//
//  WaitlistEntry.swift
//  App
//
//  Created by CursorAI on 2024-05-12.
//

import Fluent
import Vapor

final class WaitlistEntry: Model, Content {
    static let schema = "waitlist_entries"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, email: String) {
        self.id = id
        self.email = email
    }
}

// 数据库迁移
struct CreateWaitlistEntry: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(WaitlistEntry.schema)
            .id()
            .field("email", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(WaitlistEntry.schema).delete()
    }
}
