//
//  LLMController.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

/// LLM API 控制器
struct LLMController {
  /// 创建路由
  func routes(_ app: Application) throws {
    app.log.debug("Registering LLM routes", metadata: nil, source: "LLMController.routes")

    let llm = app.grouped("api", "v1", "llm")

    // 聊天补全接口
    llm.post("chat") { req -> LLMResponse in
      let source = "LLMController.chat"
      req.log.info(
        "Processing chat request",
        metadata: [
          "path": .string("/api/v1/llm/chat"),
          "contentType": .string(req.headers.first(name: .contentType) ?? "none"),
        ], source: source)

      let request = try req.validate(content: LLMRequest.self)

      req.log.info(
        "Request parameters",
        metadata: [
          "model": .string(request.config.model),
          "temperature": .string("\(request.config.temperature)"),
          "stream": .string("\(request.config.stream)"),
          "messageCount": .string("\(request.messages.count)"),
        ], source: source)

      guard !request.messages.isEmpty else {
        req.log.warning("Empty messages received", metadata: nil, source: source)
        throw LLMError.invalidRequest
      }

      do {
        req.log.info("Getting LLM provider", metadata: nil, source: source)
        let provider = try LLMConfiguration.shared.getProvider()

        req.log.info(
          "Executing LLM request",
          metadata: [
            "model": .string(request.config.model),
            "provider": .string(provider.name),
          ], source: source)

        let response = try await provider.execute(request)

        req.log.info(
          "Chat request completed",
          metadata: [
            "requestId": .string(response.requestId),
          ], source: source)

        return response
      } catch {
        req.log.error(error, message: "Chat request failed", metadata: nil, source: source)
        throw error
      }
    }
  }
}

// MARK: - Request Validation
extension Request {
  func validate<T: Content>(content type: T.Type) throws -> T {
    try self.content.decode(type)
  }
}
