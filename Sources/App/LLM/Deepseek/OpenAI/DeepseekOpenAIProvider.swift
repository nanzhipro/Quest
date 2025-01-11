//
//  DeepseekOpenAIProvider.swift
//  Quest
//
//  Created by CursorAI on 2024-01-09.
//

@preconcurrency import OpenAI
import Foundation
import Vapor

public final class DeepseekOpenAIProvider: LLMProvider {
    public let name = "DeepseekOpenAI"
    public let supportedModels = ["deepseek-chat"]
    
    private let openAI: OpenAI
    private let configuration: DeepseekOpenAIConfig
    private let requestQueue: RequestQueue
    private let semaphore: AsyncSemaphore
    private let logger: Logger
    
    // 使用 actor 来管理可变状态
    private actor RequestCounter {
        private var activeRequestCount: Int = 0
        private var requestCounter: Int = 0
        
        func incrementActiveRequests() {
            activeRequestCount += 1
        }
        
        func decrementActiveRequests() -> Int {
            activeRequestCount -= 1
            return activeRequestCount
        }
        
        func getActiveRequestCount() -> Int {
            activeRequestCount
        }
        
        func nextRequestId() -> Int {
            requestCounter += 1
            return requestCounter
        }
    }
    
    private let counter: RequestCounter
    
    init(config: DeepseekOpenAIConfig, app: Application) {
        self.configuration = config
        self.logger = app.logger
        self.counter = RequestCounter()
        
        self.requestQueue = RequestQueue(maxQueueSize: configuration.maxQueueSize)
        self.semaphore = AsyncSemaphore(value: configuration.maxConcurrentRequests)
        
        let openAIConfig = OpenAI.Configuration(
            token: configuration.apiToken,
            host: configuration.host,
            timeoutInterval: configuration.timeoutInterval
        )
        
        self.openAI = OpenAI(configuration: openAIConfig)
    }
    
    public func execute(_ request: LLMRequest) async throws -> LLMResponse {
        let responseContent = try await chat(request.messages[0].content, priority: 0)
        return LLMResponse(content: responseContent, requestId: UUID().uuidString)
    }
    
    public func validateConfig(_ config: LLMConfig) -> Bool {
        return true
    }
    
    private func processQueuedRequests() async {
        logger.debug("Starting queue processor")
        while let request = await requestQueue.dequeue() {
            logger.debug("Processing next queued request")
            Task {
                do {
                    _ = try await request.operation()
                    logger.debug("Queued request completed")
                } catch {
                    logger.error("Queued request failed: \(error)")
                }
            }
            await Task.yield()
        }
        logger.debug("Queue empty, processor stopped")
    }
    
    public func chat(_ message: String, priority: Int = 0) async throws -> String {
        let requestId = await counter.nextRequestId()
        logger.info("New request initiated", metadata: ["requestId": .string("\(requestId)"), "message": .string(message.prefix(50).description)])
        
        let operation: () async throws -> String = { [weak self] in
            guard let self = self else { throw DeepseekOpenAIError.invalidConfiguration }
            
            await self.counter.incrementActiveRequests()
            
            defer {
                Task.detached {
                    let count = await self.counter.decrementActiveRequests()
                    if count < self.configuration.maxConcurrentRequests {
                        await self.processQueuedRequests()
                    }
                }
            }
            
            let query = ChatQuery(
                messages: [.init(role: .user, content: message)!],
                model: self.configuration.model
            )
            
            let result = try await self.openAI.chats(query: query)
            guard let response = result.choices.first?.message.content else {
                throw DeepseekOpenAIError.noResponse
            }
            
            logger.info("Request completed", metadata: ["requestId": .string("\(requestId)")])
            return String(describing: response)
        }
        
        let activeCount = await counter.getActiveRequestCount()
        if activeCount >= configuration.maxConcurrentRequests {
            logger.debug("Max concurrent requests reached, queueing", metadata: ["requestId": .string("\(requestId)")])
            let queuedRequest = RequestQueue.QueuedRequest(priority: priority, operation: operation)
            try await requestQueue.enqueue(queuedRequest)
            
            Task { await processQueuedRequests() }
            
            await semaphore.wait()
        }
        
        defer { Task { await semaphore.signal() } }
        return try await operation()
    }
}

private actor AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        self.value = value
    }
    
    func wait() async {
        if value > 0 {
            value -= 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            value += 1
        }
    }
} 