//
//  CreateUserSubscription.swift
//  App
//
//  Created by CursorAI on 2024-03-21.
//

import Fluent

struct CreateUserSubscription: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(UserSubscription.schema)
            .id()
            .field("app_user_id", .string, .required)
            .field("product_id", .string, .required)
            .field("entitlement_id", .string)
            .field("status", .string, .required)
            .field("purchased_at", .datetime, .required)
            .field("expires_at", .datetime)
            .field("cancellation_date", .datetime)
            .field("original_transaction_id", .string)
            .field("is_sandbox", .bool, .required, .custom("DEFAULT FALSE"))
            .field("metadata", .json, .required, .custom("DEFAULT '{}'::jsonb"))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "app_user_id", "product_id")  // 每个用户每个产品只能有一个订阅
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(UserSubscription.schema).delete()
    }
} 