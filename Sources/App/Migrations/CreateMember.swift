//
//  CreateMember.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Fluent

struct CreateMember: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema("members")
      .id()
      .field("username", .string, .required)
      .field("email", .string, .required)
      .field("password_hash", .string, .required)
      .field("phone_number", .string)
      .field("tier_id", .uuid, .required, .references("membership_tiers", "id"))
      .field("points", .int, .required, .sql(.default("0")))
      .field("is_active", .bool, .required, .sql(.default(true)))
      .field("membership_start_date", .datetime)
      .field("membership_end_date", .datetime)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "email")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("members").delete()
  }
}
