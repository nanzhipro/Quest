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

/// 腾讯混元大模型响应
struct TencentHunyuanResponse: Codable {
    /// 响应内容
    struct Response: Codable {
        /// 选项内容
        struct Choice: Codable {
            /// 消息内容
            struct Message: Codable {
                /// 角色（assistant、user、system）
                let role: String
                /// 消息内容
                let content: String
                
                enum CodingKeys: String, CodingKey {
                    case role = "Role"
                    case content = "Content"
                }
            }
            
            /// 选项索引
            let index: Int
            /// 消息内容
            let message: Message
            /// 结束原因
            let finishReason: String?
            
            enum CodingKeys: String, CodingKey {
                case index = "Index"
                case message = "Message"
                case finishReason = "FinishReason"
            }
        }
        
        /// Token 使用统计
        struct Usage: Codable {
            /// 提示 Token 数量
            let promptTokens: Int
            /// 补全 Token 数量
            let completionTokens: Int
            /// 总 Token 数量
            let totalTokens: Int
            
            enum CodingKeys: String, CodingKey {
                case promptTokens = "PromptTokens"
                case completionTokens = "CompletionTokens"
                case totalTokens = "TotalTokens"
            }
        }
        
        /// 请求 ID
        let requestId: String
        /// 响应注释
        let note: String?
        /// 选项列表
        let choices: [Choice]
        /// 创建时间戳
        let created: Int
        /// 会话 ID
        let id: String
        /// Token 使用统计
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
    
    /// 响应内容
    let response: Response
    
    enum CodingKeys: String, CodingKey {
        case response = "Response"
    }
} 