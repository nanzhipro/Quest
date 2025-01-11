//
//  DeepseekOpenAIConfig.swift
//  Quest
//
//  Created by CursorAI on 2024-01-09.
//

import Foundation

/// Deepseek OpenAI 客户端配置
public struct DeepseekOpenAIConfig: Sendable {
    /// 默认配置值
    public enum Defaults {
        public static let host = "api.deepseek.com"
        public static let timeoutInterval: TimeInterval = 60
        public static let model = "deepseek-chat"  // 或 deepseek-coder，都会访问 V2.5 模型
        public static let maxQueueSize = 100
        public static let maxConcurrentRequests = 10
    }
    
    public let apiToken: String
    public let host: String
    public let timeoutInterval: TimeInterval
    public let model: String
    public let maxQueueSize: Int
    public let maxConcurrentRequests: Int
    
    public init(
        apiToken: String,
        host: String = Defaults.host,
        timeoutInterval: TimeInterval = Defaults.timeoutInterval,
        model: String = Defaults.model,
        maxQueueSize: Int = Defaults.maxQueueSize,
        maxConcurrentRequests: Int = Defaults.maxConcurrentRequests
    ) {
        self.apiToken = apiToken
        self.host = host
        self.timeoutInterval = timeoutInterval
        self.model = model
        self.maxQueueSize = maxQueueSize
        self.maxConcurrentRequests = maxConcurrentRequests
    }
} 
