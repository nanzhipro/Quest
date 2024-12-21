//
//  AIController.swift
//  VaporApp
//
//  Created by CursorAI on 2024-03-20.
//

import Vapor

struct AIController: RouteCollection, Sendable {
    private let llmService: LLMServiceProtocol
    
    init(llmService: LLMServiceProtocol) {
        self.llmService = llmService
    }
    
    func boot(routes: RoutesBuilder) throws {
        let ai = routes.grouped("ai")
        ai.post("analyze") { req async throws -> AIAnalysisResponse in
            let requestId = UUID().uuidString
            let source = "AIController.analyze"
            
            // 记录请求开始
            req.log.info(
                "AI analysis request started",
                metadata: ["requestId": .string(requestId)],
                source: source
            )
            
            do {
                // 记录请求参数解析
                req.log.debug(
                    "Decoding request parameters",
                    metadata: ["requestId": .string(requestId)],
                    source: source
                )
                
                let analysisRequest = try req.content.decode(AIAnalysisRequest.self)
                
                // 记录参数验证
                req.log.info(
                    "Request parameters validated",
                    metadata: [
                        "requestId": .string(requestId),
                        "textLength": .string("\(analysisRequest.text.count)"),
                        "language": .string(analysisRequest.options?.language ?? "default"),
                        "maxTokens": .string("\(analysisRequest.options?.maxTokens ?? 0)"),
                        "temperature": .string("\(analysisRequest.options?.temperature ?? 0.0)")
                    ],
                    source: source
                )
                
                guard !analysisRequest.text.isEmpty else {
                    req.log.error(
                        "Empty text content",
                        metadata: ["requestId": .string(requestId)],
                        source: source
                    )
                    throw Abort(.badRequest, reason: "Text content cannot be empty")
                }
                
                // 记录 LLM 服务调用开始
                let startTime = Date()
                req.log.info(
                    "Starting LLM service call",
                    metadata: ["requestId": .string(requestId)],
                    source: source
                )
                
                let response = try await llmService.analyzeText(
                    analysisRequest.text,
                    options: analysisRequest.options
                )
                
                // 记录 LLM 服务调用完成
                let duration = Date().timeIntervalSince(startTime)
                req.log.info(
                    "LLM service call completed",
                    metadata: [
                        "requestId": .string(requestId),
                        "duration": .string(String(format: "%.3f", duration)),
                        "keywordsCount": .string("\(response.keywords.count)"),
                        "analysisLength": .string("\(response.analysis.count)")
                    ],
                    source: source
                )
                
                return response
                
            } catch let error as AbortError {
                // 记录业务逻辑错误
                req.log.error(
                    error,
                    message: "Business error occurred",
                    metadata: ["requestId": .string(requestId)],
                    source: source
                )
                throw error
            } catch {
                // 记录意外错误
                req.log.error(
                    error,
                    message: "Unexpected error occurred",
                    metadata: ["requestId": .string(requestId)],
                    source: source
                )
                throw error
            }
        }
    }
} 