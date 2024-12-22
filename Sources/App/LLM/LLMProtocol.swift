//
//  LLMProtocol.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

/// LLM 消息角色
public enum LLMRole: String, Sendable {
    case system = "system"
    case user = "user"
    case assistant = "assistant"
}

extension LLMRole: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue.lowercased() {
        case "system":
            self = .system
        case "user":
            self = .user
        case "assistant":
            self = .assistant
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot initialize LLMRole from invalid String value: \(rawValue)"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// LLM 消息结构
public struct LLMMessage: Codable, Sendable {
    public let role: LLMRole
    public let content: String
    
    public init(role: LLMRole, content: String) {
        self.role = role
        self.content = content
    }
    
    enum CodingKeys: String, CodingKey {
        case role = "Role"
        case content = "Content"
    }
}

/// LLM 请求配置
public struct LLMConfig: Codable, Sendable {
    public let model: String
    public let temperature: Double
    public var stream: Bool
    
    public init(
        model: String,
        temperature: Double = 0.7,
        stream: Bool = false
    ) {
        self.model = model
        self.temperature = temperature
        self.stream = stream
    }
    
    enum CodingKeys: String, CodingKey {
        case model = "Model"
        case temperature = "Temperature"
        case stream = "Stream"
    }
}

/// LLM 请求选项
public struct LLMRequest: Content {
    public let messages: [LLMMessage]
    public var config: LLMConfig
    
    public init(messages: [LLMMessage], config: LLMConfig) {
        self.messages = messages
        self.config = config
    }
    
    enum CodingKeys: String, CodingKey {
        case messages = "Messages"
        case model = "Model"
        case temperature = "Temperature"
        case stream = "Stream"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messages = try container.decode([LLMMessage].self, forKey: .messages)
        let model = try container.decode(String.self, forKey: .model)
        let temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ?? 0.7
        let stream = try container.decodeIfPresent(Bool.self, forKey: .stream) ?? false
        config = LLMConfig(model: model, temperature: temperature, stream: stream)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messages, forKey: .messages)
        try container.encode(config.model, forKey: .model)
        try container.encode(config.temperature, forKey: .temperature)
        try container.encode(config.stream, forKey: .stream)
    }
}

/// LLM 响应结构
public struct LLMResponse: Content {
    public let content: String
    public let usage: LLMUsage
    public let requestId: String
    
    public init(content: String, usage: LLMUsage, requestId: String) {
        self.content = content
        self.usage = usage
        self.requestId = requestId
    }
    
    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case usage = "Usage"
        case requestId = "RequestId"
    }
}

/// Token 使用统计
public struct LLMUsage: Codable, Sendable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
    
    public init(promptTokens: Int, completionTokens: Int, totalTokens: Int) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
    }
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "PromptTokens"
        case completionTokens = "CompletionTokens"
        case totalTokens = "TotalTokens"
    }
}

public enum LLMError: Error {
    /// 配置无效
    case invalidConfiguration
    /// 提供者未配置
    case providerNotConfigured
    /// 请求无效
    case invalidRequest
    /// 请求失败
    case requestFailed(String)
    /// 响应解析失败
    case responseParsing(String)
    /// 未知错误
    case unknown(String)
    /// 提供者未找到
    case providerNotFound
}

/// LLM 服务提供者协议
public protocol LLMProvider: Sendable {
    /// 服务提供者名称
    var name: String { get }
    
    /// 支持的模型列表
    var supportedModels: [String] { get }
    
    /// 执行 LLM 请求
    /// - Parameter request: LLM 请求内容
    /// - Returns: LLM 响应结果
    func execute(_ request: LLMRequest) async throws -> LLMResponse
    
    /// 执行流式 LLM 请求
    /// - Parameter request: LLM 请求内容
    /// - Returns: 异步流式响应序列
    func executeStream(_ request: LLMRequest) async throws -> AsyncThrowingStream<String, Error>
    
    /// 验证配置是否有效
    /// - Parameter config: LLM 配置
    /// - Returns: 配置是否有效
    func validateConfig(_ config: LLMConfig) -> Bool
}

/// LLM 工厂协议
public protocol LLMFactory {
    /// 创建 LLM 提供者实例
    /// - Parameter config: 提供者配置
    /// - Returns: LLM 提供者实例
    func createProvider(config: [String: Any]) throws -> LLMProvider
} 
