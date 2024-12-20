//
//  LLMConfiguration.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

final class LLMConfiguration {
    static let shared = LLMConfiguration()
    private var provider: LLMProvider?
    
    private init() {}
    
    func configureTencentHunyuan(app: Application) throws {
        guard !AppEnvironment.LLM.secretId.isEmpty,
              !AppEnvironment.LLM.secretKey.isEmpty else {
            app.logger.warning("Tencent Hunyuan credentials not configured")
            throw LLMError.invalidConfiguration
        }
        
        let factory = TencentHunyuanFactory(app: app)
        provider = try factory.createProvider(config: [
            "secretId": AppEnvironment.LLM.secretId,
            "secretKey": AppEnvironment.LLM.secretKey,
            "region": AppEnvironment.LLM.region
        ])
        
        app.logger.info("Tencent Hunyuan LLM configured successfully")
    }
    
    func getProvider() throws -> LLMProvider {
        guard let provider = provider else {
            throw LLMError.providerNotConfigured
        }
        return provider
    }
} 