//
//  LLMInitializerFactory.swift
//  App
//
//  Created by CursorAI on 2024-03-20.
//

import Vapor

// 定义 LLM 提供者类型
enum LLMProviderType {
  case tencentHunyuan
  case tencentHunyuanOpenAI
  case doubao
  case deepseek
}

// 工厂类，用于创建 LLM 初始化器
struct LLMInitializerFactory {
  static func createInitializer(for provider: LLMProviderType) -> LLMInitializer {
    switch provider {
    case .tencentHunyuan:
      return TencentHunyuanInitializer()
    case .tencentHunyuanOpenAI:
      return TencentHunyuanOpenAIInitializer()
    case .doubao:
      return DoubaoLLMInitializer()
    case .deepseek:
      return DeepseekOpenAIInitializer()
    }
  }
}

