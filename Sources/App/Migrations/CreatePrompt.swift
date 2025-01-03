//
//  CreatePrompt.swift
//  Quest
//
//  Created by CursorAI on 2024-02-21.
//

import Fluent

struct CreatePrompt: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("prompts")
            .id()
            .field("content", .string, .required)
            .field("version", .int, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("prompts").delete()
    }
} 