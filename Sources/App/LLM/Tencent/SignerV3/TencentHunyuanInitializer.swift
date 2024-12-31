//
//  TencentHunyuanInitializer.swift
//  App
//
//  Created by CursorAI on 2024-03-20.
//

import Vapor

struct TencentHunyuanInitializer: LLMInitializer {
    private enum Constants {
        static let secretIdEnv = "TENCENT_SECRET_ID"
        static let secretKeyEnv = "TENCENT_SECRET_KEY"
        static let appIdEnv = "TENCENT_APP_ID"
    }
    
    func initialize(app: Application) throws {
        let (secretId, secretKey, appId) = try requireCredentials(app)
        let config = TencentHunyuanConfig(
            secretId: secretId,
            secretKey: secretKey,
            appId: appId
        )
        
        try validateConfig(config)
        
        let provider = TencentHunyuanProvider(config: config, app: app)
        LLMConfiguration.shared.register(provider: provider, isActive: false, app: app)
    }
    
    private func requireCredentials(_ app: Application) throws -> (String, String, String) {
        guard let secretId = Environment.get(Constants.secretIdEnv),
              let secretKey = Environment.get(Constants.secretKeyEnv),
              let appId = Environment.get(Constants.appIdEnv)
        else {
            app.logger.error("Missing required environment variables", metadata: [
                "required": .string("\(Constants.secretIdEnv), \(Constants.secretKeyEnv), \(Constants.appIdEnv)")
            ])
            throw LLMInitializerError.missingConfiguration
        }
        return (secretId, secretKey, appId)
    }
    
    private func validateConfig(_ config: TencentHunyuanConfig) throws {
        try config.validate()
    }
}
