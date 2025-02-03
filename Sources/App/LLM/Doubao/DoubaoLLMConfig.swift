//
//  DoubaoLLMConfig.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

// TODO: 豆包支持了最新版本的 OpenAI 调用方式，Swift OpenAI 还不支持。
// 所以暂时不支持豆包，详见：https://github.com/MacPaw/OpenAI/issues/221
public struct DoubaoLLMConfig: LLMProviderConfig {
  public let identifier = "doubao.llm"
  public let apiKey: String
  public let endpoint: String

  public init(apiKey: String, endpoint: String) {
    self.apiKey = apiKey
    self.endpoint = endpoint
  }

  public func validate() throws {
    guard !apiKey.isEmpty else {
      throw LLMError.invalidConfiguration("API Key cannot be empty")
    }
    guard !endpoint.isEmpty else {
      throw LLMError.invalidConfiguration("Endpoint cannot be empty")
    }
  }
}
