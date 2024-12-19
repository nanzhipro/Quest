//
//  TencentHunyuanFactory.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

/// 腾讯混元大模型工厂
public final class TencentHunyuanFactory: LLMFactory {
    private let app: Application
    
    public init(app: Application) {
        self.app = app
    }
    
    public func createProvider(config: [String: Any]) throws -> LLMProvider {
        guard let secretId = config["secretId"] as? String,
              let secretKey = config["secretKey"] as? String else {
            throw LLMError.invalidConfiguration
        }
        
        let region = config["region"] as? String ?? "ap-beijing"
        return TencentHunyuanProvider(
            app: app,
            secretId: secretId,
            secretKey: secretKey,
            region: region
        )
    }
} 