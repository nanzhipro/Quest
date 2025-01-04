//
//  PromptController.swift
//  Quest
//
//  Created by CursorAI on 2024-02-21.
//

import Fluent
import Vapor

struct PromptController: RouteCollection {
  private let promptService: PromptService

  init(promptService: PromptService = InMemoryPromptService.shared) {
    self.promptService = promptService
  }

  func boot(routes: RoutesBuilder) throws {
    let prompts = routes.grouped("api", "prompts")
    prompts.get(use: getLatestPrompt)
  }

  func getLatestPrompt(req: Request) async throws -> PromptResponse {
    let latestPrompt = try await promptService.getLatestPrompt()
    return PromptResponse(prompt: latestPrompt)
  }
}
