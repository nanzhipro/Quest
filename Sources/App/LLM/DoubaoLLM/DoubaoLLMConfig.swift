//
//  DoubaoLLMConfig.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

public struct DoubaoLLMConfig: LLMProviderConfig {
  public let identifier = "doubao.llm"
  public let apiKey: String
  public let endpoint: String

  public init(apiKey: String, endpoint: String) {
    self.apiKey = apiKey
    self.endpoint = endpoint
  }

  public func validate() -> Bool {
    !apiKey.isEmpty && !endpoint.isEmpty
  }
}
