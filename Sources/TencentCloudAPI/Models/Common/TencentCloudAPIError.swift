//
//  TencentCloudAPIError.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation

/// 腾讯云API错误
public enum TencentCloudAPIError: Error {
    /// API请求失败
    case requestFailed(message: String)
    /// 签名生成失败
    case signatureGenerationFailed(message: String)
    /// 参数无效
    case invalidParameter(paramName: String, message: String)
    /// 响应解析失败
    case responseParsingFailed(message: String)
    /// 服务错误
    case serviceError(code: String, message: String)
    /// 未知错误
    case unknown(message: String)
}

extension TencentCloudAPIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .requestFailed(let message):
            return "请求失败: \(message)"
        case .signatureGenerationFailed(let message):
            return "签名生成失败: \(message)"
        case .invalidParameter(let paramName, let message):
            return "参数无效[\(paramName)]: \(message)"
        case .responseParsingFailed(let message):
            return "响应解析失败: \(message)"
        case .serviceError(let code, let message):
            return "服务错误[\(code)]: \(message)"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}

/// 腾讯云API错误响应
public struct TencentCloudAPIErrorResponse: Codable {
    public struct Error: Codable {
        public let code: String
        public let message: String
        
        enum CodingKeys: String, CodingKey {
            case code = "Code"
            case message = "Message"
        }
    }
    
    public let error: Error
    public let requestId: String?
    
    enum CodingKeys: String, CodingKey {
        case error = "Error"
        case requestId = "RequestId"
    }
} 