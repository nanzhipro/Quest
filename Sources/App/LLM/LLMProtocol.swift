//
//  LLMProtocol.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

/// LLM 消息角色
public enum LLMRole: String, Codable {
    case system
    case user
    case assistant
}

/// LLM 消息结构
public struct LLMMessage: Codable {
    public let role: LLMRole
    public let content: String
    
    public init(role: LLMRole, content: String) {
        self.role = role
        self.content = content
    }
}

/// LLM 请求配置
public struct LLMConfig: Codable {
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
}

/// LLM 请求选项
public struct LLMRequest: Codable {
    public let messages: [LLMMessage]
    public var config: LLMConfig
    
    public init(messages: [LLMMessage], config: LLMConfig) {
        self.messages = messages
        self.config = config
    }
}

/// LLM 响应结构
public struct LLMResponse: Codable {
    public let content: String
    public let usage: LLMUsage
    public let requestId: String
    
    public init(content: String, usage: LLMUsage, requestId: String) {
        self.content = content
        self.usage = usage
        self.requestId = requestId
    }
}

/// Token 使用统计
public struct LLMUsage: Codable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
    
    public init(promptTokens: Int, completionTokens: Int, totalTokens: Int) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
    }
}

/// LLM 错误类型
public enum LLMError: Error {
    /// 配置无效
    case invalidConfiguration
    /// 提供者未配置
    case providerNotConfigured
    /// 请求失败
    case requestFailed(String)
    /// 响应解析失败
    case responseParsing(String)
    /// 未知错误
    case unknown(String)
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