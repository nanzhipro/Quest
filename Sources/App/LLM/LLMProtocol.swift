//
//  LLMProtocol.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

/// LLM 服务提供者协议
public protocol LLMProvider: Sendable {
  /// 服务提供者名称
  var name: String { get }

  /// 执行 LLM 请求
  /// - Parameter request: LLM 请求内容
  /// - Returns: LLM 响应结果
  func execute(_ request: LLMRequest) async throws -> LLMResponse
    
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
