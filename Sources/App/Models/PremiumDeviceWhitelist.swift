//
//  PremiumDeviceWhitelist.swift
//  App
//
//  Created by CursorAI on 2024-05-08.
//

import Fluent
import Vapor

/// 高级功能白名单设备模型
/// 用于存储被授权使用高级功能的设备UUID
final class PremiumDeviceWhitelist: Model, Content {
    /// 常量模式名称，用于数据库表映射
    static let schema = "premium_device_whitelist"

    /// 模型ID
    @ID(key: .id)
    var id: UUID?

    /// 设备唯一标识符
    @Field(key: "device_uuid")
    var deviceUUID: String

    /// 添加到白名单的时间
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    /// 白名单过期时间
    @Field(key: "expires_at")
    var expiresAt: Date?

    /// 初始化方法
    init() {}

    /// 创建新的白名单记录
    /// - Parameters:
    ///   - deviceUUID: 设备唯一标识符
    ///   - expiresAt: 权限过期时间
    init(deviceUUID: String, expiresAt: Date?) {
        self.deviceUUID = deviceUUID
        self.expiresAt = expiresAt
    }
}

// MARK: - 查询帮助方法
extension PremiumDeviceWhitelist {
    /// 检查设备是否在白名单中且未过期
    /// - Parameters:
    ///   - deviceUUID: 设备唯一标识符
    ///   - db: 数据库
    /// - Returns: 设备是否有高级功能的访问权限
    static func isDeviceWhitelisted(_ deviceUUID: String, on db: Database) async throws -> Bool {
        guard
            let entry = try await PremiumDeviceWhitelist.query(on: db)
                .filter(\.$deviceUUID == deviceUUID)
                .first()
        else {
            return false
        }

        // 检查是否已过期
        if let expiryDate = entry.expiresAt, expiryDate < Date() {
            return false
        }

        return true
    }
}
