//
//  TencentHunyuanSigner.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import CryptoKit

final class TencentHunyuanSigner: @unchecked Sendable {
    private let secretId: String
    private let secretKey: String
    private let service: String
    private let endpoint: String
    
    init(secretId: String, secretKey: String, service: String, endpoint: String) {
        self.secretId = secretId
        self.secretKey = secretKey
        self.service = service
        self.endpoint = endpoint
    }
    
    func sign(params: [String: Any], timestamp: Int, action: String) throws -> [String: String] {
        let date = formatDate(timestamp)
        let credentialScope = "\(date)/\(service)/tc3_request"
        
        // 1. 规范请求串
        let canonicalRequest = try buildCanonicalRequest(
            params: params,
            action: action
        )
        
        // 2. 待签名字符串
        let stringToSign = buildStringToSign(
            timestamp: timestamp,
            credentialScope: credentialScope,
            canonicalRequest: canonicalRequest
        )
        
        // 3. 计算签名
        let signature = try calculateSignature(
            date: date,
            stringToSign: stringToSign
        )
        
        // 4. 返回所有需要的头部
        return [
            "Authorization": """
            TC3-HMAC-SHA256 \
            Credential=\(secretId)/\(credentialScope), \
            SignedHeaders=content-type;host;x-tc-action, \
            Signature=\(signature)
            """,
            "Host": endpoint,
            "X-TC-Timestamp": String(timestamp),
            "X-TC-Action": action
        ]
    }
    
    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
    
    private func buildCanonicalRequest(
        params: [String: Any],
        action: String
    ) throws -> String {
        let method = "POST"
        let canonicalUri = "/"
        let canonicalQueryString = ""
        let canonicalHeaders = """
        content-type:application/json
        host:\(endpoint)
        x-tc-action:\(action.lowercased())
        
        """
        let signedHeaders = "content-type;host;x-tc-action"
        let hashedRequestPayload = try hashPayload(params)
        
        return """
        \(method)
        \(canonicalUri)
        \(canonicalQueryString)
        \(canonicalHeaders)
        \(signedHeaders)
        \(hashedRequestPayload)
        """
    }
    
    private func buildStringToSign(
        timestamp: Int,
        credentialScope: String,
        canonicalRequest: String
    ) -> String {
        let algorithm = "TC3-HMAC-SHA256"
        let requestHash = sha256(canonicalRequest)
        
        return """
        \(algorithm)
        \(timestamp)
        \(credentialScope)
        \(requestHash)
        """
    }
    
    private func calculateSignature(
        date: String,
        stringToSign: String
    ) throws -> String {
        let secretDate = hmac(key: "TC3\(secretKey)".data(using: .utf8)!, data: date.data(using: .utf8)!)
        let secretService = hmac(key: secretDate, data: service.data(using: .utf8)!)
        let secretSigning = hmac(key: secretService, data: "tc3_request".data(using: .utf8)!)
        let signature = hmac(key: secretSigning, data: stringToSign.data(using: .utf8)!)
        
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