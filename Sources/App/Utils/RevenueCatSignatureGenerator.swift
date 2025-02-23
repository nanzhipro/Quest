//
//  RevenueCatSignatureGenerator.swift
//  App
//
//  Created by CursorAI on 2024-03-21.
//

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

enum RevenueCatSignatureGenerator {
    /// 生成 RevenueCat Webhook 签名
    /// - Parameters:
    ///   - jsonBody: JSON 字符串或字典
    ///   - secret: Webhook 密钥
    /// - Returns: 签名字符串
    /// - Throws: 编码错误
    static func generateSignature(jsonBody: Any, secret: String) throws -> String {
        let bodyString: String
        
        switch jsonBody {
        case let string as String:
            bodyString = string
        case let dict as [String: Any]:
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
            bodyString = String(data: jsonData, encoding: .utf8) ?? ""
        default:
            throw SignatureError.invalidInput
        }
        
        let secretData = Data(secret.utf8)
        let messageData = Data(bodyString.utf8)
        
        #if canImport(CryptoKit)
        let hmac = HMAC<SHA256>.authenticationCode(for: messageData, using: SymmetricKey(data: secretData))
        return Data(hmac).map { String(format: "%02x", $0) }.joined()
        #else
        let hmac = HMAC<SHA256>.authenticationCode(for: messageData, using: SymmetricKey(data: secretData))
        return Data(hmac).map { String(format: "%02x", $0) }.joined()
        #endif
    }
    
    enum SignatureError: Error {
        case invalidInput
    }
}

// MARK: - 使用示例
extension RevenueCatSignatureGenerator {
    static func example() throws {
        // 示例 1: 使用 JSON 字符串
        let jsonString = """
        {
            "event": {
                "event_id": "123456",
                "type": "INITIAL_PURCHASE",
                "app_user_id": "user123",
                "product_id": "premium_monthly"
            }
        }
        """
        
        let secret = "your_webhook_secret"
        let signature1 = try generateSignature(jsonBody: jsonString, secret: secret)
        print("Signature for JSON string: \(signature1)")
        
        // 示例 2: 使用字典
        let jsonDict: [String: Any] = [
            "event": [
                "event_id": "123456",
                "type": "INITIAL_PURCHASE",
                "app_user_id": "user123",
                "product_id": "premium_monthly"
            ]
        ]
        
        let signature2 = try generateSignature(jsonBody: jsonDict, secret: secret)
        print("Signature for dictionary: \(signature2)")
    }
} 