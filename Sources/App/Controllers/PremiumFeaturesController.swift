//
//  PremiumFeaturesController.swift
//  App
//
//  Created by CursorAI on 2024-05-08.
//

import Fluent
import Vapor

/// 处理高级功能访问权限的控制器
struct PremiumFeaturesController: RouteCollection {
    /// 模型响应结构
    struct PremiumAccessResponse: Content {
        /// 是否有权限访问高级功能
        let hasAccess: Bool
        /// 如果没有权限，提供原因说明
        let reason: String?
    }

    /// 设备UUID请求结构
    struct DeviceCheckRequest: Content {
        /// 设备唯一标识符
        let deviceUUID: String
    }

    /// 添加白名单设备请求结构
    struct AddDeviceRequest: Content {
        /// 设备唯一标识符
        let deviceUUID: String
        /// 白名单过期时间（可选）
        let expiresAt: Date?
    }

    /// 注册路由
    func boot(routes: RoutesBuilder) throws {
        let premiumFeatures = routes.grouped("api", "v1", "premium-features")

        // 检查设备是否可以访问高级功能
        premiumFeatures.post("check-access", use: checkAccess)

        // 管理端点（应该添加额外的认证保护）
        let admin = premiumFeatures.grouped("admin")
        admin.post("add-device", use: addDevice)
        admin.delete("remove-device", ":deviceUUID", use: removeDevice)
    }

    /// 检查设备是否有访问高级功能的权限
    /// - Parameter req: HTTP请求
    /// - Returns: 访问权限响应
    func checkAccess(req: Request) async throws -> PremiumAccessResponse {
        let deviceCheckRequest = try req.content.decode(DeviceCheckRequest.self)
        let deviceUUID = deviceCheckRequest.deviceUUID

        // 首先检查全局设置
        let appConfig = try AppConfig.load(from: req.application.environment)

        // 如果全局允许高级功能，直接返回允许
        if appConfig.enablePremiumFeaturesWhenUnsubscribed {
            return PremiumAccessResponse(hasAccess: true, reason: nil)
        }

        // 否则检查设备是否在白名单中
        let isWhitelisted = try await PremiumDeviceWhitelist.isDeviceWhitelisted(
            deviceUUID, on: req.db)

        if isWhitelisted {
            return PremiumAccessResponse(hasAccess: true, reason: nil)
        } else {
            // 检查是否已过期
            let expiredDevice = try await PremiumDeviceWhitelist.query(on: req.db)
                .filter(\.$deviceUUID == deviceUUID)
                .filter(\.$expiresAt < Date())
                .first()

            if expiredDevice != nil {
                return PremiumAccessResponse(
                    hasAccess: false,
                    reason: "设备白名单权限已过期"
                )
            }

            return PremiumAccessResponse(
                hasAccess: false,
                reason: "设备未被授权访问高级功能"
            )
        }
    }

    /// 将设备添加到白名单
    /// - Parameter req: HTTP请求
    /// - Returns: 操作成功响应
    func addDevice(req: Request) async throws -> HTTPStatus {
        let addRequest = try req.content.decode(AddDeviceRequest.self)

        // 查找现有记录
        if let existingEntry = try await PremiumDeviceWhitelist.query(on: req.db)
            .filter(\.$deviceUUID == addRequest.deviceUUID)
            .first()
        {
            // 更新过期时间
            existingEntry.expiresAt = addRequest.expiresAt
            try await existingEntry.save(on: req.db)
        } else {
            // 创建新记录
            let newEntry = PremiumDeviceWhitelist(
                deviceUUID: addRequest.deviceUUID,
                expiresAt: addRequest.expiresAt
            )
            try await newEntry.save(on: req.db)
        }

        return .ok
    }

    /// 从白名单中移除设备
    /// - Parameter req: HTTP请求
    /// - Returns: 操作成功响应
    func removeDevice(req: Request) async throws -> HTTPStatus {
        guard let deviceUUID = req.parameters.get("deviceUUID") else {
            throw Abort(.badRequest, reason: "缺少设备UUID参数")
        }

        try await PremiumDeviceWhitelist.query(on: req.db)
            .filter(\.$deviceUUID == deviceUUID)
            .delete()

        return .ok
    }
}
