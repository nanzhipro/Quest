//
//  TencentHunyuanModels.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

struct TencentHunyuanRequest: Encodable {
    let model: String
    let messages: [[String: String]]
    let stream: Bool
    let temperature: Double
    
    init(from request: LLMRequest) {
        self.model = request.config.model
        self.messages = request.messages.map { [
            "Role": $0.role.rawValue,
            "Content": $0.content
        ]}
        self.stream = request.config.stream
        self.temperature = request.config.temperature
    }
    
    enum CodingKeys: String, CodingKey {
        case model = "Model"
        case messages = "Messages"
        case stream = "Stream"
        case temperature = "Temperature"
    }
}

struct TencentHunyuanResponse: Decodable {
    struct Response: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }
            let message: Message
        }
        struct Usage: Decodable {
            let promptTokens: Int
            let completionTokens: Int
            let totalTokens: Int
        }
        let choices: [Choice]
        let usage: Usage
        let requestId: String
    }
    let response: Response
} 