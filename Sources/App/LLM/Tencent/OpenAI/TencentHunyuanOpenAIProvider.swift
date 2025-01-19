@preconcurrency import OpenAI
import Foundation
import Vapor

public final class TencentHunyuanOpenAIProvider: LLMProvider {
    public let name = "TencentHunyuanOpenAI"
    // https://cloud.tencent.com/document/product/1729/97731
    public let supportedModels = ["hunyuan-lite", "hunyuan-large"]
    
    private let openAI: OpenAI
    private let configuration: TencentHunyuanOpenAIConfig
    private let requestQueue: RequestQueue
    private let semaphore: AsyncSemaphore
    private let logger: Logger
    
    // 使用 actor 管理请求状态
    private actor RequestState {
        private var activeCount = 0
        private var requestId = 0
        
        func incrementActive() -> Int { activeCount += 1; return activeCount }
        func decrementActive() -> Int { activeCount -= 1; return activeCount }
        func nextRequestId() -> Int { requestId += 1; return requestId }
        func currentActive() -> Int { activeCount }
    }
    
    private let state: RequestState
    
    init(config: TencentHunyuanOpenAIConfig, app: Application) {
        self.configuration = config
        self.logger = app.logger
        self.state = RequestState()
        
        self.requestQueue = RequestQueue(maxQueueSize: configuration.maxQueueSize)
        self.semaphore = AsyncSemaphore(value: configuration.maxConcurrentRequests)
        
        self.openAI = OpenAI(configuration: .init(
            token: configuration.apiToken,
            host: configuration.host,
            timeoutInterval: configuration.timeoutInterval
        ))
    }
    
    public func execute(_ request: LLMRequest) async throws -> LLMResponse {
        let content = try await chat(request.messages[0].content)
        return LLMResponse(content: content, requestId: UUID().uuidString)
    }
    
    public func validateConfig(_ config: LLMConfig) -> Bool { true }
    
    private func processQueue() async {
        while let request = await requestQueue.dequeue() {
            Task {
                do {
                    _ = try await request.operation()
                } catch {
                    logger.error("Queued request failed: \(error)")
                }
            }
            await Task.yield()
        }
    }
    
    public func chat(_ message: String, priority: Int = 0) async throws -> String {
        let requestId = await state.nextRequestId()
        let operation = { [weak self] () async throws -> String in
            guard let self = self else { throw TencentHunyuanOpenAIError.invalidConfiguration }
            
            // 使用下划线忽略返回值，因为我们在 defer 中处理计数
            _ = await self.state.incrementActive()
            defer { Task { 
                let count = await self.state.decrementActive()
                if count < self.configuration.maxConcurrentRequests {
                    await self.processQueue()
                }
            }}
            
            self.logger.info("Processing request", metadata: [
                "requestId": .string("\(requestId)"),
                "message": .string(message.prefix(50).description)
            ])
            
            let query = ChatQuery(
                messages: [.init(role: .user, content: message)!],
                model: self.configuration.model
            )
            
            let result = try await self.openAI.chats(query: query)
            guard let response = result.choices.first?.message.content else {
                throw TencentHunyuanOpenAIError.noResponse
            }
            
            let responseString = response.string ?? ""
            
            // 添加调试日志，将响应转换为 JSON 格式打印
            self.logger.debug("[\(name)] LLM response", metadata: [
                "requestId": .string("\(requestId)"),
                "response": .string(responseString)
            ])
            
            return responseString
        }
        
        // 检查当前活跃请求数
        if await state.currentActive() >= configuration.maxConcurrentRequests {
            let queuedRequest = RequestQueue.QueuedRequest(priority: priority, operation: operation)
            try await requestQueue.enqueue(queuedRequest)
            Task { await processQueue() }
            await semaphore.wait()
        }
        
        defer { Task { await semaphore.signal() } }
        return try await operation()
    }
}

// 简化的异步信号量实现
private actor AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) { self.value = value }
    
    func wait() async {
        if value > 0 { value -= 1; return }
        await withCheckedContinuation { waiters.append($0) }
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
