//
//  TencentHunyuanConfig.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

public struct TencentHunyuanConfig: LLMProviderConfig, Sendable {
  public let identifier = "tencent.hunyuan"
  public let secretId: String
  public let secretKey: String
  public let appId: String
  public let model: String
  public let maxQueueSize: Int
  public let maxConcurrentRequests: Int

  public init(
    secretId: String,
    secretKey: String,
    appId: String,
    model: String = "hunyuan-lite",
    maxQueueSize: Int = 100,
    maxConcurrentRequests: Int = 10
  ) {
    self.secretId = secretId
    self.secretKey = secretKey
    self.appId = appId
    self.model = model
    self.maxQueueSize = maxQueueSize
    self.maxConcurrentRequests = maxConcurrentRequests
  }

  public func validate() throws {
    guard !secretId.isEmpty else {
      throw LLMError.invalidConfiguration("Secret ID cannot be empty")
    }
    guard !secretKey.isEmpty else {
      throw LLMError.invalidConfiguration("Secret Key cannot be empty")
    }
    guard !appId.isEmpty else {
      throw LLMError.invalidConfiguration("App ID cannot be empty")
    }
  }
}
