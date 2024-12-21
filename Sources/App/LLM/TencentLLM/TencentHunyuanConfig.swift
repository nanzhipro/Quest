//
//  TencentHunyuanConfig.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

public struct TencentHunyuanConfig: LLMProviderConfig, Sendable {
    public let identifier = "tencent.hunyuan"
    public let secretId: String
    public let secretKey: String
    public let appId: String
    public let region: String
    
    public init(
        secretId: String,
        secretKey: String,
        appId: String,
        region: String = "ap-beijing"
    ) {
        self.secretId = secretId
        self.secretKey = secretKey
        self.appId = appId
        self.region = region
    }
    
    public func validate() -> Bool {
        !secretId.isEmpty && !secretKey.isEmpty && !appId.isEmpty
    }
} 