//
//  LLMConfiguration.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

/// LLM 配置管理
@globalActor public actor LLMConfiguration {
    public static let shared = LLMConfiguration()
    
    /// 当前使用的 LLM 提供者
    private var currentProvider: LLMProvider?
    
    private init() {}
    
    /// 配置腾讯混元大模型
    /// - Parameters:
    ///   - app: Vapor 应用实例
    ///   - secretId: 腾讯云 SecretId
    ///   - secretKey: 腾讯云 SecretKey
    ///   - region: 地域，默认为 ap-beijing
    public func configureTencentHunyuan(
        app: Application,
        secretId: String? = nil,
        secretKey: String? = nil,
        region: String = "ap-beijing"
    ) throws {
        // 优先使用参数传入的配置，其次使用环境变量
        let finalSecretId = secretId ?? Environment.get("TENCENT_SECRET_ID")
        let finalSecretKey = secretKey ?? Environment.get("TENCENT_SECRET_KEY")
        
        guard let finalSecretId = finalSecretId,
              let finalSecretKey = finalSecretKey else {
            throw LLMError.invalidConfiguration
        }
        
        let factory = TencentHunyuanFactory(app: app)
        currentProvider = try factory.createProvider(config: [
            "secretId": finalSecretId,
            "secretKey": finalSecretKey,
            "region": region
        ])
        
        app.logger.info("Tencent Hunyuan LLM configured successfully")
    }
    
    /// 获取当前配置的 LLM 提供者
    /// - Returns: LLM 提供者实例
    public func getProvider() throws -> LLMProvider {
        guard let provider = currentProvider else {
            throw LLMError.invalidConfiguration
        }
        return provider
    }
} 