//
//  CreateEventLog.swift
//  App
//
//  Created by CursorAI on 2024-03-21.
//

import Fluent

struct CreateEventLog: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(EventLog.schema)
            .id()
            .field("event_id", .string, .required)
            .field("event_type", .string, .required)
            .field("app_user_id", .string, .required)
            .field("processed_at", .datetime, .required)
            .unique(on: "event_id")  // 确保事件只处理一次
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(EventLog.schema).delete()
    }
} 