//
//  LLMController.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

struct LLMController {
  private let promptService: PromptService
  
  init(promptService: PromptService) {
    self.promptService = promptService
  }
  
  func routes(_ app: Application) throws {
    let llm = app.grouped("api", "v1", "llm")
    llm.post("chat", use: chat)
  }
  
  private func chat(_ req: Request) async throws -> LLMClientChatResponse {
    // 记录请求日志
    req.logger.info("Received chat request", metadata: [
      "request": .string(req.body.string ?? "No request body")
    ])

    // 解码客户端请求
    let clientRequest = try req.content.decode(LLMClientChatRequest.self)
    
    // 获取最新的提示词模板
    let prompt = try await promptService.getLatestPrompt()
    let promptTemplate = prompt.content
    
    // 替换提示词模板中的占位符
    let processedPrompt = promptTemplate
      .replacingOccurrences(of: "CALENDAR_NAMES_LIST", with: clientRequest.calendarNamesList)
      .replacingOccurrences(of: "USER_CONTEXT", with: clientRequest.userContext)
      .replacingOccurrences(of: "PLACEHOLDER_TEXT", with: clientRequest.placeholderText)
    
    // 创建 LLM 请求对象
    let message = LLMMessage(role: .user, content: processedPrompt)
    let config = LLMConfig(
      model: "", // 使用默认模型
      temperature: 0.3, // 使用默认温度
      stream: false
    )
    let request = LLMRequest(
      messages: [message],
      config: config
    )
    
    req.logger.info("Processing chat request with processed prompt", metadata: [
      "promptVersion": .string("\(prompt.version)"),
      "promptLength": .string("\(processedPrompt.count)")
    ])
    
    // 获取 LLM 提供者并执行请求
    let provider = try LLMConfiguration.shared.getProvider()
    req.logger.info("Using LLM provider", metadata: [
      "provider": .string(provider.name)
    ])
    
    let response = try await provider.execute(request)
    req.logger.info("Chat request completed", metadata: [
      "requestId": .string(response.requestId)
    ])
    
    return response
  }
}
