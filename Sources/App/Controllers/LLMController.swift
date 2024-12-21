//
//  LLMController.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

/// LLM API 控制器
struct LLMController {
    /// 创建路由
    func routes(_ app: Application) throws {
        app.log.debug("Registering LLM routes", metadata: nil, source: "LLMController.routes")
        
        let llm = app.grouped("api", "v1", "llm")
        
        // 聊天补全接口
        llm.post("chat") { req -> LLMResponse in
            let source = "LLMController.chat"
            req.log.info("Processing chat request", metadata: [
                "path": .string("/api/v1/llm/chat"),
                "contentType": .string(req.headers.first(name: .contentType) ?? "none")
            ], source: source)
            
            let request = try req.validate(content: LLMRequest.self)
            
            req.log.info("Request parameters", metadata: [
                "model": .string(request.config.model),
                "temperature": .string("\(request.config.temperature)"),
                "stream": .string("\(request.config.stream)"),
                "messageCount": .string("\(request.messages.count)")
            ], source: source)
            
            guard !request.messages.isEmpty else {
                req.log.warning("Empty messages received", metadata: nil, source: source)
                throw LLMError.invalidRequest
            }
            
            do {
                req.log.info("Getting LLM provider", metadata: nil, source: source)
                let provider = try LLMConfiguration.shared.getProvider()
                
                req.log.info("Executing LLM request", metadata: [
                    "model": .string(request.config.model),
                    "provider": .string(provider.name)
                ], source: source)
                
                let response = try await provider.execute(request)
                
                req.log.info("Chat request completed", metadata: [
                    "requestId": .string(response.requestId),
                    "tokenUsage": .string("\(response.usage)")
                ], source: source)
                
                return response
            } catch {
                req.log.error(error, message: "Chat request failed", metadata: nil, source: source)
                throw error
            }
        }
        
        // 流式聊天补全接口
        llm.post("chat", "stream") { req async throws -> Response in
            let source = "LLMController.chatStream"
            req.log.debug("Processing stream request", metadata: [
                "path": .string("/api/v1/llm/chat/stream"),
                "contentType": .string(req.headers.first(name: .contentType) ?? "none")
            ], source: source)
            
            let request = try req.validate(content: LLMRequest.self)
            
            req.log.debug("Stream request parameters", metadata: [
                "model": .string(request.config.model),
                "temperature": .string("\(request.config.temperature)"),
                "messageCount": .string("\(request.messages.count)")
            ], source: source)
            
            guard !request.messages.isEmpty else {
                req.log.warning("Empty messages received for stream", metadata: nil, source: source)
                throw LLMError.invalidRequest
            }
            
            let response = Response(body: .init())
            response.headers.replaceOrAdd(
                name: .contentType,
                value: "text/event-stream; charset=utf-8"
            )
            
            do {
                req.log.debug("Getting LLM provider for stream", metadata: nil, source: source)
                let provider = try LLMConfiguration.shared.getProvider()
                
                req.log.debug("Executing streaming request", metadata: [
                    "model": .string(request.config.model),
                    "provider": .string(provider.name)
                ], source: source)
                
                let stream = try await provider.executeStream(request)
                
                response.body = .init(stream: { writer in
                    Task {
                        do {
                            var chunkCount = 0
                            for try await chunk in stream {
                                chunkCount += 1
                                req.log.debug("Sending chunk", metadata: [
                                    "chunkNumber": .string("\(chunkCount)"),
                                    "chunkSize": .string("\(chunk.count)")
                                ], source: source)
                                
                                let buffer = ByteBuffer(string: "data: \(chunk)\n\n")
                                _ = writer.write(.buffer(buffer))
                            }
                            
                            let doneBuffer = ByteBuffer(string: "data: [DONE]\n\n")
                            _ = writer.write(.buffer(doneBuffer))
                            
                            req.log.info("Stream completed", metadata: [
                                "totalChunks": .string("\(chunkCount)")
                            ], source: source)
                        } catch {
                            req.log.error(error, message: "Stream processing failed", metadata: nil, source: source)
                            _ = writer.write(.error(error))
                        }
                    }
                })
                
                return response
            } catch {
                req.log.error(error, message: "Failed to initialize stream", metadata: nil, source: source)
                throw error
            }
        }
    }
}

// MARK: - Request Validation
extension Request {
    func validate<T: Content>(content type: T.Type) throws -> T {
        try self.content.decode(type)
    }
} 