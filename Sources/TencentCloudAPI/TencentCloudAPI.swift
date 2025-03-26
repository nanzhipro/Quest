//
//  TencentCloudAPI.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation

/// 腾讯云API根类，提供便捷的服务访问方法
public class TencentCloud {
    /// API客户端
    private let client: TencentCloudAPIClient
    
    /// 初始化腾讯云API
    /// - Parameter config: API配置
    public init(config: TencentCloudAPIConfig) {
        self.client = TencentCloudAPIClient(config: config)
    }
    
    /// 创建语音识别服务
    /// - Parameter version: API版本，默认为配置中的默认版本
    /// - Returns: 语音识别服务
    public func asr(version: String? = nil) -> ASRService {
        return ASRService(client: client, version: version)
    }
    
    /// 快速创建腾讯云API实例
    /// - Parameters:
    ///   - secretId: 密钥ID
    ///   - secretKey: 密钥
    ///   - region: 地域
    ///   - options: 附加选项
    /// - Returns: 腾讯云API实例
    public static func create(
        secretId: String,
        secretKey: String,
        region: String,
        options: [String: Any] = [:]
    ) -> TencentCloud {
        var config = TencentCloudAPIConfig(
            secretId: secretId,
            secretKey: secretKey,
            region: region
        )
        
        // 应用附加选项
        if let endpoint = options["endpoint"] as? String {
            config = TencentCloudAPIConfig(
                secretId: secretId,
                secretKey: secretKey,
                region: region,
                endpoint: endpoint
            )
        }
        
        if let timeout = options["timeout"] as? TimeInterval {
            config = TencentCloudAPIConfig(
                secretId: secretId,
                secretKey: secretKey,
                region: region,
                endpoint: config.endpoint,
                requestTimeout: timeout
            )
        }
        
        if let autoRetry = options["autoRetry"] as? Bool {
            config = TencentCloudAPIConfig(
                secretId: secretId,
                secretKey: secretKey,
                region: region,
                endpoint: config.endpoint,
                requestTimeout: config.requestTimeout,
                autoRetry: autoRetry
            )
        }
        
        if let maxRetries = options["maxRetries"] as? Int {
            config = TencentCloudAPIConfig(
                secretId: secretId,
                secretKey: secretKey,
                region: region,
                endpoint: config.endpoint,
                requestTimeout: config.requestTimeout,
                autoRetry: config.autoRetry,
                maxRetries: maxRetries
            )
        }
        
        if let defaultVersion = options["defaultVersion"] as? String {
            config = TencentCloudAPIConfig(
                secretId: secretId,
                secretKey: secretKey,
                region: region,
                endpoint: config.endpoint,
                requestTimeout: config.requestTimeout,
                autoRetry: config.autoRetry,
                maxRetries: config.maxRetries,
                defaultVersion: defaultVersion
            )
        }
        
        return TencentCloud(config: config)
    }
} 