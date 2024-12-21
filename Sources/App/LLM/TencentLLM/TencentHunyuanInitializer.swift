//
//  TencentHunyuanInitializer.swift
//  App
//
//  Created by CursorAI on 2024-03-20.
//

import Vapor

struct TencentHunyuanInitializer: LLMInitializer {
    func initialize(app: Application) throws {
        guard let secretId = Environment.get("TENCENT_SECRET_ID"),
              let secretKey = Environment.get("TENCENT_SECRET_KEY"),
              let appId = Environment.get("TENCENT_APP_ID") else {
            app.logger.error("Missing Tencent Hunyuan configuration")
            throw LLMInitializerError.missingConfiguration
        }
        
        let config = TencentHunyuanConfig(
            secretId: secretId,
            secretKey: secretKey,
            appId: appId
        )
        
        guard config.validate() else {
            app.logger.error("Invalid Tencent Hunyuan configuration")
            throw LLMInitializerError.invalidConfiguration
        }
        
        app.logger.info("Creating Tencent Hunyuan provider", metadata: [
            "appId": .string(appId),
            "region": .string(Environment.get("TENCENT_REGION") ?? "default")
        ])
        
        let provider = TencentHunyuanProvider(config: config, app: app)
        LLMConfiguration.shared.register(provider: provider, isActive: true, app: app)
    }
} 