//
//  DeviceWhitelistCommand.swift
//  App
//
//  Created by CursorAI on 2024-05-08.
//

import Fluent
import Foundation
import Vapor

/// 管理高级功能设备白名单的命令
struct DeviceWhitelistCommand: AsyncCommand {
    /// 命令参数定义
    struct Signature: CommandSignature {
        /// 操作类型：add(添加)、remove(删除)、list(列出所有)
        @Argument(name: "action")
        var action: String

        /// 设备UUID (添加或删除操作必需)
        @Option(name: "uuid", short: "u")
        var deviceUUID: String?

        /// 权限过期时间 (可选，仅添加操作使用，格式：YYYY-MM-DD)
        @Option(name: "expires", short: "e")
        var expiresAt: String?

        /// 是否只显示有效的白名单设备 (可选，仅列表操作使用)
        @Flag(name: "valid-only", short: "v")
        var validOnly: Bool
    }

    /// 命令帮助信息
    var help: String {
        """
        管理高级功能设备白名单

        使用方法:
          添加设备: swift run App device-whitelist add --uuid F8D75B3E-C25A-4FDA-B9D6-5D83748F1111 [--expires 2024-12-31]
          删除设备: swift run App device-whitelist remove --uuid F8D75B3E-C25A-4FDA-B9D6-5D83748F1111
          列出设备: swift run App device-whitelist list [--valid-only]
        """
    }

    /// 命令实现
    func run(using context: CommandContext, signature: Signature) async throws {
        let app = context.application

        // 根据操作类型执行不同的操作
        switch signature.action.lowercased() {
        case "add":
            try await addDevice(app: app, context: context, signature: signature)
        case "remove":
            try await removeDevice(app: app, context: context, signature: signature)
        case "list":
            try await listDevices(app: app, context: context, signature: signature)
        default:
            context.console.error("无效的操作: \(signature.action)")
            context.console.output(ConsoleText(stringLiteral: help))
            throw Abort(.badRequest, reason: "无效的操作")
        }
    }

    /// 添加设备到白名单
    private func addDevice(app: Application, context: CommandContext, signature: Signature)
        async throws
    {
        guard let deviceUUID = signature.deviceUUID, !deviceUUID.isEmpty else {
            context.console.error("必须提供设备UUID (--uuid)")
            throw Abort(.badRequest, reason: "必须提供设备UUID")
        }

        // 解析过期时间
        var expiresDate: Date? = nil
        if let expiresString = signature.expiresAt {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            guard let date = dateFormatter.date(from: expiresString) else {
                context.console.error("无效的过期日期格式。请使用 YYYY-MM-DD 格式。")
                throw Abort(.badRequest, reason: "无效的过期日期格式")
            }

            // 设置为当天最后一秒
            let calendar = Calendar.current
            let components = DateComponents(
                year: calendar.component(.year, from: date),
                month: calendar.component(.month, from: date),
                day: calendar.component(.day, from: date),
                hour: 23,
                minute: 59,
                second: 59
            )

            expiresDate = calendar.date(from: components)
        }

        // 查找现有记录
        if let existingEntry = try await PremiumDeviceWhitelist.query(on: app.db)
            .filter(\.$deviceUUID == deviceUUID)
            .first()
        {
            // 更新过期时间
            existingEntry.expiresAt = expiresDate
            try await existingEntry.save(on: app.db)

            if let expires = expiresDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                context.console.success(
                    "设备 \(deviceUUID) 白名单已更新，过期时间: \(dateFormatter.string(from: expires))")
            } else {
                context.console.success("设备 \(deviceUUID) 白名单已更新，永不过期")
            }
        } else {
            // 创建新记录
            let newEntry = PremiumDeviceWhitelist(deviceUUID: deviceUUID, expiresAt: expiresDate)
            try await newEntry.save(on: app.db)

            if let expires = expiresDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                context.console.success(
                    "设备 \(deviceUUID) 已添加到白名单，过期时间: \(dateFormatter.string(from: expires))")
            } else {
                context.console.success("设备 \(deviceUUID) 已添加到白名单，永不过期")
            }
        }
    }

    /// 从白名单中移除设备
    private func removeDevice(app: Application, context: CommandContext, signature: Signature)
        async throws
    {
        guard let deviceUUID = signature.deviceUUID, !deviceUUID.isEmpty else {
            context.console.error("必须提供设备UUID (--uuid)")
            throw Abort(.badRequest, reason: "必须提供设备UUID")
        }

        // 查找并删除设备
        let query = PremiumDeviceWhitelist.query(on: app.db)
            .filter(\.$deviceUUID == deviceUUID)

        // 检查设备是否存在
        guard try await query.count() > 0 else {
            context.console.warning("设备 \(deviceUUID) 不在白名单中")
            return
        }

        try await query.delete()
        context.console.success("设备 \(deviceUUID) 已从白名单中移除")
    }

    /// 列出白名单设备
    private func listDevices(app: Application, context: CommandContext, signature: Signature)
        async throws
    {
        let query = PremiumDeviceWhitelist.query(on: app.db)

        // 如果指定了只显示有效的，则筛选未过期的设备
        if signature.validOnly {
            query.group(.or) { group in
                group.filter(\.$expiresAt == nil)
                group.filter(\.$expiresAt > Date())
            }
        }

        let devices = try await query.all()

        if devices.isEmpty {
            context.console.output("白名单中没有设备")
            return
        }

        // 简化输出，直接显示表数据
        context.console.output("")
        context.console.output("设备白名单:")

        // 打印设备列表
        for device in devices {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            let createdAt =
                device.createdAt != nil ? dateFormatter.string(from: device.createdAt!) : "未记录"
            let expiresAt =
                device.expiresAt != nil ? dateFormatter.string(from: device.expiresAt!) : "永不过期"
            let isExpired = device.expiresAt != nil && device.expiresAt! < Date() ? " (已过期)" : ""

            context.console.output("UUID: \(device.deviceUUID)")
            context.console.output("添加时间: \(createdAt)")
            context.console.output("过期时间: \(expiresAt)\(isExpired)")
            context.console.output("-----------------")
        }

        context.console.output("总计: \(String(devices.count)) 个设备")
        context.console.output("")
    }
}
