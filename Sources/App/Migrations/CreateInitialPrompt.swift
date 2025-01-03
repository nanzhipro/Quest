//
//  CreateInitialPrompt.swift
//  Quest
//
//  Created by CursorAI on 2024-02-21.
//

import Fluent

struct CreateInitialPrompt: AsyncMigration {
    func prepare(on database: Database) async throws {
        let prompt = Prompt(
            content: "你好，杭州。",
            version: 1
        )
        try await prompt.save(on: database)
    }

    func revert(on database: Database) async throws {
        try await Prompt.query(on: database).delete()
    }
} 