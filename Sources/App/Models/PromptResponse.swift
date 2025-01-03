//
//  PromptResponse.swift
//  Quest
//
//  Created by CursorAI on 2024-02-21.
//

import Vapor

struct PromptResponse: Content {
    let content: String
    let version: Int
    
    init(prompt: Prompt) {
        self.content = prompt.content
        self.version = prompt.version
    }
} 