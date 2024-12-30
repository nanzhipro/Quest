//
//  CreateMembershipTier.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Fluent

struct CreateMembershipTier: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema("membership_tiers")
      .id()
      .field("name", .string, .required)
      .field("description", .string, .required)
      .field("price", .double, .required)
      .field("duration_months", .int, .required)
      .field("benefits", .array(of: .string), .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("membership_tiers").delete()
  }
}
