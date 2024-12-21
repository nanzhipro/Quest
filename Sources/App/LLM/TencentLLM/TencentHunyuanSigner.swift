//
//  TencentHunyuanSigner.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import CryptoKit
import Vapor

final class TencentHunyuanSigner: @unchecked Sendable {
    private let secretId: String
    private let secretKey: String
    private let service: String
    private let endpoint: String
    private let logger: Logger
    
    init(secretId: String, secretKey: String, service: String, endpoint: String, app: Application) {
        self.secretId = secretId
        self.secretKey = secretKey
        self.service = service
        self.endpoint = endpoint
        self.logger = app.logger
    }
    
    func sign(params: [String: Any], timestamp: Int, action: String) throws -> [String: String] {
        let source = "TencentHunyuanSigner.sign"
        logger.debug("Starting signature generation", metadata: [
            "action": .string(action),
            "timestamp": .string("\(timestamp)"),
            "service": .string(service)
        ], source: source)
        
        let date = formatDate(timestamp)
        let credentialScope = "\(date)/\(service)/tc3_request"
        let algorithm = "TC3-HMAC-SHA256"
        
        logger.debug("Building canonical request", metadata: [
            "date": .string(date),
            "credentialScope": .string(credentialScope)
        ], source: source)
        
        // 1. 构建规范请求串
        let canonicalRequest = try buildCanonicalRequest(params: params, action: action)
        let hashedCanonicalRequest = sha256(canonicalRequest)
        
        logger.debug("Canonical request built", metadata: [
            "requestHash": .string(hashedCanonicalRequest)
        ], source: source)
        
        // 2. 构建待签名字符串
        let stringToSign = """
        \(algorithm)
        \(timestamp)
        \(credentialScope)
        \(hashedCanonicalRequest)
        """
        
        logger.debug("String to sign prepared", metadata: [
            "stringHash": .string(sha256(stringToSign))
        ], source: source)
        
        // 3. 计算签名
        let signature = try calculateSignature(date: date, stringToSign: stringToSign)
        
        logger.debug("Signature calculated", metadata: [
            "signatureLength": .string("\(signature.count)")
        ], source: source)
        
        // 4. 构建授权信息
        let authorization = """
        \(algorithm) \
        Credential=\(secretId)/\(credentialScope), \
        SignedHeaders=content-type;host;x-tc-action, \
        Signature=\(signature)
        """
        
        logger.info("Authorization header generated", metadata: [
            "timestamp": .string("\(timestamp)")
        ], source: source)
        
        return ["Authorization": authorization]
    }
    
    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
    
    private func buildCanonicalRequest(params: [String: Any], action: String) throws -> String {
        let source = "TencentHunyuanSigner.buildCanonicalRequest"
        
        logger.debug("Building canonical request components", metadata: [
            "action": .string(action)
        ], source: source)
        
        // 按照文档要求构建规范请求串
        let httpRequestMethod = "POST"
        let canonicalUri = "/"
        let canonicalQueryString = ""
        let canonicalHeaders = """
        content-type:application/json
        host:\(endpoint)
        x-tc-action:\(action.lowercased())
        
        """
        let signedHeaders = "content-type;host;x-tc-action"
        let hashedRequestPayload = try hashPayload(params)
        
        let request = """
        \(httpRequestMethod)
        \(canonicalUri)
        \(canonicalQueryString)
        \(canonicalHeaders)
        \(signedHeaders)
        \(hashedRequestPayload)
        """
        
        logger.debug("Canonical request built", metadata: [
            "requestHash": .string(sha256(request))
        ], source: source)
        
        return request
    }
    
    private func calculateSignature(date: String, stringToSign: String) throws -> String {
        let source = "TencentHunyuanSigner.calculateSignature"
        
        logger.debug("Calculating signature steps", metadata: nil, source: source)
        
        // 1. 派生签名密钥
        let secretDate = hmac(key: "TC3\(secretKey)".data(using: .utf8)!, data: date.data(using: .utf8)!)
        let secretService = hmac(key: secretDate, data: service.data(using: .utf8)!)
        let secretSigning = hmac(key: secretService, data: "tc3_request".data(using: .utf8)!)
        
        // 2. 计算签名
        let signature = hmac(key: secretSigning, data: stringToSign.data(using: .utf8)!)
        
        logger.debug("Signature calculation completed", metadata: [
            "signatureLength": .string("\(signature.count)")
        ], source: source)
        
        return signature.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func hashPayload(_ params: [String: Any]) throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: params)
        return sha256(String(data: jsonData, encoding: .utf8)!)
    }
    
    private func sha256(_ string: String) -> String {
        let data = string.data(using: .utf8)!
        return SHA256.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func hmac(key: Data, data: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(signature)
    }
} 