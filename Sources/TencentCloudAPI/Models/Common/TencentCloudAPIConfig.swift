//
//  TencentCloudAPIConfig.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation

/// 腾讯云API配置
public struct TencentCloudAPIConfig {
    /// 访问密钥ID
    public let secretId: String
    /// 访问密钥Key
    public let secretKey: String
    /// 地域
    public let region: String
    /// API端点
    public let endpoint: String
    /// 请求超时时间(秒)
    public let requestTimeout: TimeInterval
    /// 是否自动处理重试
    public let autoRetry: Bool
    /// 最大重试次数
    public let maxRetries: Int
    /// 默认API版本
    public let defaultVersion: String
    
    /// 创建一个腾讯云API配置
    /// - Parameters:
    ///   - secretId: 访问密钥ID
    ///   - secretKey: 访问密钥Key
    ///   - region: 地域
    ///   - endpoint: API端点，默认为"asr.tencentcloudapi.com"
    ///   - requestTimeout: 请求超时时间，默认60秒
    ///   - autoRetry: 是否自动处理重试，默认为true
    ///   - maxRetries: 最大重试次数，默认为3
    ///   - defaultVersion: 默认API版本，默认为"2019-06-14"
    public init(
        secretId: String,
        secretKey: String,
        region: String,
        endpoint: String = "asr.tencentcloudapi.com",
        requestTimeout: TimeInterval = 60,
        autoRetry: Bool = true,
        maxRetries: Int = 3,
        defaultVersion: String = "2019-06-14"
    ) {
        self.secretId = secretId
        self.secretKey = secretKey
        self.region = region
        self.endpoint = endpoint
        self.requestTimeout = requestTimeout
        self.autoRetry = autoRetry
        self.maxRetries = maxRetries
        self.defaultVersion = defaultVersion
    }
} 