//
//  TencentHunyuanEndpoint.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

/// 腾讯混元大模型 API 端点
enum TencentHunyuanEndpoint: APIEndpoint {
    /// 聊天补全
    case chatCompletions(LLMRequest)
    
    var path: String {
        "/"
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var headers: [String: String]? {
        switch self {
        case .chatCompletions:
            return [
                "Content-Type": "application/json",
                "X-TC-Version": "2023-09-01",
                "X-TC-Action": "ChatCompletions",
                "X-TC-Language": "zh-CN",
                "X-TC-Region": "ap-beijing"
            ]
        }
    }
    
    var body: Encodable? {
        switch self {
        case .chatCompletions(let request):
            return TencentHunyuanRequest(from: request)
        }
    }
    
    // 添加获取请求参数字典的方法
    var parameters: [String: Any]? {
        switch self {
        case .chatCompletions(let request):
            return TencentHunyuanRequest(from: request).toDictionary()
        }
    }
} 