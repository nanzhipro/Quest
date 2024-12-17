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
            // 生成请求 ID
            let requestId = UUID().uuidString
            
            // 记录请求开始
            req.logger.info("[\(requestId)] AI analysis request started")
            
            do {
                // 记录请求参数解析
                req.logger.info("[\(requestId)] Decoding request parameters")
                let analysisRequest = try req.content.decode(AIAnalysisRequest.self)
                
                // 记录参数验证
                req.logger.info("""
                    [\(requestId)] Request parameters:
                    - Text length: \(analysisRequest.text.count)
                    - Language: \(analysisRequest.options?.language ?? "default")
                    - MaxTokens: \(analysisRequest.options?.maxTokens ?? 0)
                    - Temperature: \(analysisRequest.options?.temperature ?? 0.0)
                    """)
                
                guard !analysisRequest.text.isEmpty else {
                    req.logger.error("[\(requestId)] Error: Empty text content")
                    throw Abort(.badRequest, reason: "Text content cannot be empty")
                }
                
                // 记录 LLM 服务调用开始
                req.logger.info("[\(requestId)] Calling LLM service")
                let startTime = Date()
                
                let response = try await llmService.analyzeText(
                    analysisRequest.text,
                    options: analysisRequest.options
                )
                
                // 记录 LLM 服务调用完成
                let duration = Date().timeIntervalSince(startTime)
                req.logger.info("""
                    [\(requestId)] LLM service call completed:
                    - Duration: \(String(format: "%.3f", duration))s
                    - Keywords count: \(response.keywords.count)
                    - Analysis length: \(response.analysis.count)
                    """)
                
                return response
                
            } catch let error as AbortError {
                // 记录业务逻辑错误
                req.logger.error("[\(requestId)] Business error: \(error.reason)")
                throw error
            } catch {
                // 记录意外错误
                req.logger.error("[\(requestId)] Unexpected error: \(error.localizedDescription)")
                throw error
            }
        }
    }
} 