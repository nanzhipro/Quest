//
//  AppConfig.swift
//  App
//
//  Created by CursorAI on 2024-03-21.
//

import Vapor

// AppConfig 结构体用于管理应用程序配置
// 遵循 Content 协议使其可以在 HTTP 请求和响应中使用
struct AppConfig: Content {
    // RevenueCat API 密钥
    let revenuecatApiKey: String
    // 当未订阅时，是否启用高级功能, 默认是 false
    let enablePremiumFeaturesWhenUnsubscribed: Bool

    // 从环境变量中加载配置
    // - Parameter environment: Vapor 的环境对象
    // - Returns: 配置完成的 AppConfig 实例
    // - Throws: 如果必需的环境变量未设置，则抛出错误
    static func load(from environment: Environment) throws -> AppConfig {
        guard let key = Environment.get("REVENUECAT_API_KEY") else {
            throw Abort(.internalServerError, reason: "REVENUECAT_API_KEY not configured")
        }

        guard let enablePremiumFeaturesWhenUnsubscribed = Environment.get("ENABLE_PREMIUM_FEATURES_WHEN_UNSUBSCRIBED") else {
            throw Abort(.internalServerError, reason: "ENABLE_PREMIUM_FEATURES_WHEN_UNSUBSCRIBED not configured")
        }

        return AppConfig(revenuecatApiKey: key, enablePremiumFeaturesWhenUnsubscribed: enablePremiumFeaturesWhenUnsubscribed == "true")
    }
}
