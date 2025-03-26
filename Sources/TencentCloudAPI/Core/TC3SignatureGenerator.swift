//
//  TC3SignatureGenerator.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation
import Crypto

/// TC3签名生成器
public class TC3SignatureGenerator {
    /// 密钥ID
    private let secretId: String
    /// 密钥
    private let secretKey: String
    
    /// 初始化TC3签名生成器
    /// - Parameters:
    ///   - secretId: 密钥ID
    ///   - secretKey: 密钥
    public init(secretId: String, secretKey: String) {
        self.secretId = secretId
        self.secretKey = secretKey
    }
    
    /// 计算HMAC-SHA256
    /// - Parameters:
    ///   - key: 密钥数据
    ///   - message: 消息数据
    /// - Returns: HMAC结果数据
    func hmac256(key: Data, message: Data) throws -> Data {
        let key = SymmetricKey(data: key)
        let hmac = HMAC<SHA256>.authenticationCode(for: message, using: key)
        return Data(hmac)
    }
    
    /// 计算字符串的SHA256哈希值并转换为小写十六进制
    /// - Parameter str: 输入字符串
    /// - Returns: 小写十六进制SHA256哈希值
    func sha256Hex(_ str: String) throws -> String {
        let data = Data(str.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// 构建规范请求串
    /// - Parameter requestInfo: 请求信息
    /// - Returns: 规范请求串
    func constructCanonicalRequest(requestInfo: TC3RequestInfo) throws -> String {
        let hashedPayload = try sha256Hex(requestInfo.requestPayload)
        
        return """
        \(requestInfo.httpMethod)
        \(requestInfo.canonicalURI)
        \(requestInfo.canonicalQueryString)
        \(requestInfo.canonicalHeaders)
        \(requestInfo.signedHeaders)
        \(hashedPayload)
        """
    }
    
    /// 构建待签名字符串
    /// - Parameters:
    ///   - timestamp: 时间戳
    ///   - date: 日期字符串
    ///   - service: 服务名称
    ///   - canonicalRequest: 规范请求串
    /// - Returns: 待签名字符串
    func constructStringToSign(timestamp: Int, date: String, service: String, canonicalRequest: String) throws -> String {
        let hashedCanonicalRequest = try sha256Hex(canonicalRequest)
        let credentialScope = "\(date)/\(service)/tc3_request"
        
        return """
        TC3-HMAC-SHA256
        \(timestamp)
        \(credentialScope)
        \(hashedCanonicalRequest)
        """
    }
    
    /// 计算签名
    /// - Parameters:
    ///   - date: 日期字符串
    ///   - service: 服务名称
    ///   - stringToSign: 待签名字符串
    /// - Returns: 签名结果
    func calculateSignature(date: String, service: String, stringToSign: String) throws -> String {
        let secretKeyData = Data(("TC3" + secretKey).utf8)
        let dateData = Data(date.utf8)
        let serviceData = Data(service.utf8)
        let tc3RequestData = Data("tc3_request".utf8)
        let stringToSignData = Data(stringToSign.utf8)
        
        // 派生密钥
        let secretDate = try hmac256(key: secretKeyData, message: dateData)
        let secretService = try hmac256(key: secretDate, message: serviceData)
        let secretSigning = try hmac256(key: secretService, message: tc3RequestData)
        
        // 计算签名
        let signature = try hmac256(key: secretSigning, message: stringToSignData)
        
        // 转换为十六进制
        return signature.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// 构建授权头部
    /// - Parameters:
    ///   - date: 日期字符串
    ///   - service: 服务名称
    ///   - signedHeaders: 已签名的头部字段
    ///   - signature: 签名结果
    /// - Returns: 授权头部字符串
    func constructAuthorizationHeader(date: String, service: String, signedHeaders: String, signature: String) -> String {
        let credentialScope = "\(date)/\(service)/tc3_request"
        return "TC3-HMAC-SHA256 Credential=\(secretId)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
    }
    
    /// 生成请求签名
    /// - Parameters:
    ///   - service: 服务名称
    ///   - timestamp: 时间戳
    ///   - date: 日期字符串
    ///   - requestInfo: 请求信息
    /// - Returns: 签名结果
    public func generateSignature(service: String, timestamp: Int, date: String, requestInfo: TC3RequestInfo) throws -> String {
        // 构建规范请求串
        let canonicalRequest = try constructCanonicalRequest(requestInfo: requestInfo)
        
        // 构建待签名字符串
        let stringToSign = try constructStringToSign(timestamp: timestamp, date: date, service: service, canonicalRequest: canonicalRequest)
        
        // 计算签名
        return try calculateSignature(date: date, service: service, stringToSign: stringToSign)
    }
    
    /// 生成完整的授权头部
    /// - Parameters:
    ///   - service: 服务名称
    ///   - timestamp: 时间戳
    ///   - requestInfo: 请求信息
    /// - Returns: 授权头部字符串
    public func generateAuthorizationHeader(service: String, timestamp: Int, requestInfo: TC3RequestInfo) throws -> String {
        // 从时间戳生成日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let date = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
        
        // 生成签名
        let signature = try generateSignature(service: service, timestamp: timestamp, date: date, requestInfo: requestInfo)
        
        // 构建授权头部
        return constructAuthorizationHeader(date: date, service: service, signedHeaders: requestInfo.signedHeaders, signature: signature)
    }
}

/// TC3请求信息
public struct TC3RequestInfo {
    /// HTTP请求方法
    public let httpMethod: String
    /// 规范URI
    public let canonicalURI: String
    /// 规范查询字符串
    public let canonicalQueryString: String
    /// 规范头部
    public let canonicalHeaders: String
    /// 已签名的头部字段
    public let signedHeaders: String
    /// 请求载荷
    public let requestPayload: String
    
    /// 初始化TC3请求信息
    /// - Parameters:
    ///   - httpMethod: HTTP请求方法
    ///   - canonicalURI: 规范URI
    ///   - canonicalQueryString: 规范查询字符串
    ///   - canonicalHeaders: 规范头部
    ///   - signedHeaders: 已签名的头部字段
    ///   - requestPayload: 请求载荷
    public init(
        httpMethod: String,
        canonicalURI: String,
        canonicalQueryString: String,
        canonicalHeaders: String,
        signedHeaders: String,
        requestPayload: String
    ) {
        self.httpMethod = httpMethod
        self.canonicalURI = canonicalURI
        self.canonicalQueryString = canonicalQueryString
        self.canonicalHeaders = canonicalHeaders
        self.signedHeaders = signedHeaders
        self.requestPayload = requestPayload
    }
} 