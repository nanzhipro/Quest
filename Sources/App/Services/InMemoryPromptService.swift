//
//  InMemoryPromptService.swift
//  Quest
//
//  Created by CursorAI on 2024-02-21.
//

import Vapor

protocol PromptService {
    func getLatestPrompt() async throws -> Prompt
}

class InMemoryPromptService: PromptService {
    static let shared = InMemoryPromptService()
    
    private var prompts: [Prompt] = []
    
    private init() {
        // 添加测试数据
        let initialPrompt = Prompt(
            id: UUID(),
            content: "你好，杭州。",
            version: 1
        )
        prompts.append(initialPrompt)
    }
    
    func getLatestPrompt() async throws -> Prompt {
        guard let latest = prompts.max(by: { $0.version < $1.version }) else {
            throw Abort(.notFound, reason: "No prompts available")
        }
        return latest
    }
    
    // 用于测试的辅助方法
    func addPrompt(_ prompt: Prompt) {
        prompts.append(prompt)
    }
} 