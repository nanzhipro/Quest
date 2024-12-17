//
//  LLMService.swift
//  VaporApp
//
//  Created by CursorAI on 2024-03-20.
//

import Vapor

protocol LLMServiceProtocol: Sendable {
    func analyzeText(_ text: String, options: AIAnalysisRequest.AnalysisOptions?) async throws -> AIAnalysisResponse
}

final class LLMService: LLMServiceProtocol {
    private let client: Client
    private let apiKey: String
    private let apiEndpoint: String
    
    init(client: Client, apiKey: String, apiEndpoint: String) {
        self.client = client
        self.apiKey = apiKey
        self.apiEndpoint = apiEndpoint
    }
    
    func analyzeText(_ text: String, options: AIAnalysisRequest.AnalysisOptions?) async throws -> AIAnalysisResponse {
        let headers = HTTPHeaders([
            ("Authorization", "Bearer \(apiKey)"),
            ("Content-Type", "application/json")
        ])
        
        // 创建请求体
        struct RequestBody: Content {
            let text: String
            let options: AIAnalysisRequest.AnalysisOptions?
        }
        
        let requestBody = RequestBody(text: text, options: options)
        
        let response = try await client.post(URI(string: apiEndpoint), headers: headers) { req in
            try req.content.encode(requestBody)
        }
        
        guard response.status == HTTPStatus.ok else {
            throw Abort(.badRequest, reason: "LLM API request failed")
        }
        
        return try response.content.decode(AIAnalysisResponse.self)
    }
} 