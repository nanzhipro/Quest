//
//  TencentHunyuanEndpoint.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor
import Logging

/// 腾讯混元大模型 API 端点
struct TencentHunyuanEndpoint: APIEndpoint {
    private let request: LLMRequest
    private let logger: Logger
    private let timestamp: Int
    
    init(request: LLMRequest, logger: Logger, timestamp: Int) {
        self.request = request
        self.logger = logger
        self.timestamp = timestamp
    }
    
    var path: String {
        "/"
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var headers: [String: String]? {
        let source = "TencentHunyuanEndpoint.headers"
        // 按照文档要求的顺序设置 headers
        let headers = [
            "Host": "hunyuan.tencentcloudapi.com",
            "X-TC-Action": "ChatCompletions",
            "X-TC-Timestamp": String(timestamp),
            "X-TC-Language": "zh-CN",
            "X-TC-Version": "2023-09-01",
            "X-TC-Region": "ap-beijing",
            "Content-Type": "application/json; charset=utf-8"
        ]
        
        logger.debug("Generated API headers", metadata: [
            "headerCount": .string("\(headers.count)"),
            "action": .string("ChatCompletions"),
            "timestamp": .string("\(timestamp)")
        ], source: source)
        
        return headers
    }
    
    var body: Encodable? {
        let source = "TencentHunyuanEndpoint.body"
        logger.debug("Preparing request body", metadata: [
            "model": .string(request.config.model),
            "messageCount": .string("\(request.messages.count)")
        ], source: source)
        
        return TencentHunyuanRequest(from: request)
    }
    
    var parameters: [String: Any]? {
        let source = "TencentHunyuanEndpoint.parameters"
        let params = TencentHunyuanRequest(from: request).toDictionary()
        
        logger.debug("Generated request parameters", metadata: [
            "paramCount": .string("\(params.count)"),
            "model": .string(request.config.model)
        ], source: source)
        
        return params
    }
    
    var currentTimestamp: Int {
        timestamp
    }
} 
