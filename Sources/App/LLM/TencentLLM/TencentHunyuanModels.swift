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
    
    func toDictionary() -> [String: Any] {
        [
            "Model": model,
            "Messages": messages,
            "Stream": stream,
            "Temperature": temperature
        ]
    }
}

struct TencentHunyuanResponse: Decodable {
    struct Response: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let role: String
                let content: String
                
                enum CodingKeys: String, CodingKey {
                    case role = "Role"
                    case content = "Content"
                }
            }
            let index: Int
            let message: Message
            let finishReason: String?
            
            enum CodingKeys: String, CodingKey {
                case index = "Index"
                case message = "Message"
                case finishReason = "FinishReason"
            }
        }
        
        struct Usage: Decodable {
            let promptTokens: Int
            let completionTokens: Int
            let totalTokens: Int
            
            enum CodingKeys: String, CodingKey {
                case promptTokens = "PromptTokens"
                case completionTokens = "CompletionTokens"
                case totalTokens = "TotalTokens"
            }
        }
        
        let requestId: String
        let note: String?
        let choices: [Choice]
        let created: Int?
        let id: String?
        let usage: Usage
        
        enum CodingKeys: String, CodingKey {
            case requestId = "RequestId"
            case note = "Note"
            case choices = "Choices"
            case created = "Created"
            case id = "Id"
            case usage = "Usage"
        }
    }
    
    let response: Response
    
    enum CodingKeys: String, CodingKey {
        case response = "Response"
    }
} 