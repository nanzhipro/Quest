//
//  LLMController.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

struct LLMController {
  func routes(_ app: Application) throws {
    let llm = app.grouped("api", "v1", "llm")
    llm.post("chat", use: chat)
  }
  
  private func chat(_ req: Request) async throws -> LLMResponse {
    let request = try req.content.decode(LLMRequest.self)
    
    guard !request.messages.isEmpty else {
      req.logger.warning("Empty messages received")
      throw LLMError.invalidRequest
    }
    
    let provider = try LLMConfiguration.shared.getProvider()
    req.logger.info("Processing chat request", metadata: [
      "model": .string(request.config.model),
      "provider": .string(provider.name)
    ])
    
    let response = try await provider.execute(request)
    req.logger.info("Chat request completed", metadata: [
      "requestId": .string(response.requestId)
    ])
    
    return response
  }
}
