//
//  CreatePremiumDeviceWhitelist.swift
//  App
//
//  Created by CursorAI on 2024-05-08.
//

import Fluent

struct CreatePremiumDeviceWhitelist: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(PremiumDeviceWhitelist.schema)
            .id()
            .field("device_uuid", .string, .required)
            .field("created_at", .datetime)
            .field("expires_at", .datetime)
            .unique(on: "device_uuid")  // 确保每个设备 UUID 只有一条记录
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(PremiumDeviceWhitelist.schema).delete()
    }
}
