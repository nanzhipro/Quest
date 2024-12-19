//
//  TencentHunyuanProvider.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor
import CryptoKit

/// 腾讯混元大模型提供者
public final class TencentHunyuanProvider: LLMProvider {
    public let name = "TencentHunyuan"
    public let supportedModels = ["hunyuan-lite"]
    
    private let secretId: String
    private let secretKey: String
    private let region: String
    private let endpoint: String
    private let service = "hunyuan"
    private let version = "2023-09-01"
    private let client: Client
    private let logger: Logger
    
    public init(app: Application, secretId: String, secretKey: String, region: String = "ap-beijing") {
        self.secretId = secretId
        self.secretKey = secretKey
        self.region = region
        self.endpoint = "hunyuan.tencentcloudapi.com"
        self.client = app.client
        self.logger = app.logger
    }
    
    public func execute(_ request: LLMRequest) async throws -> LLMResponse {
        guard validateConfig(request.config) else {
            throw LLMError.invalidConfiguration
        }
        
        do {
            // 构建请求参数
            let params = try buildRequestParams(request)
            
            // 构建请求头
            let timestamp = Int(Date().timeIntervalSince1970)
            let headers = try buildRequestHeaders(
                params: params,
                timestamp: timestamp,
                action: "ChatCompletions"
            )
            
            // 记录请求日志
            logger.debug("Sending request to Tencent Hunyuan API", metadata: [
                "endpoint": .string(endpoint),
                "action": .string("ChatCompletions"),
                "timestamp": .string(String(timestamp))
            ])
            
            // 发送请求
            let response = try await client.post(URI(string: "https://\(endpoint)")) { req in
                req.headers = headers
                try req.content.encode(params, as: .json)
            }
            
            // 检查响应状态码
            guard response.status == .ok else {
                throw LLMError.requestFailed("Unexpected status code: \(response.status.code)")
            }
            
            // 解析响应
            return try parseResponse(response)
        } catch let error as LLMError {
            logger.error("LLM request failed", metadata: [
                "error": .string(String(describing: error))
            ])
            throw error
        } catch {
            logger.error("Unexpected error", metadata: [
                "error": .string(String(describing: error))
            ])
            throw LLMError.unknown(error.localizedDescription)
        }
    }
    
    public func executeStream(_ request: LLMRequest) async throws -> AsyncThrowingStream<String, Error> {
        guard validateConfig(request.config) else {
            throw LLMError.invalidConfiguration
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // 修改请求配置为流式
                    var streamRequest = request
                    streamRequest.config.stream = true
                    
                    let response = try await execute(streamRequest)
                    
                    // 解析 SSE 格式的响应
                    let chunks = response.content.components(separatedBy: "\n\n")
                    for chunk in chunks where !chunk.isEmpty {
                        if chunk.hasPrefix("data: ") {
                            let content = String(chunk.dropFirst(6))
                            continuation.yield(content)
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    logger.error("Stream request failed", metadata: [
                        "error": .string(String(describing: error))
                    ])
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func validateConfig(_ config: LLMConfig) -> Bool {
        return supportedModels.contains(config.model)
    }
    
    // MARK: - Private Methods
    
    private func buildRequestParams(_ request: LLMRequest) throws -> [String: Any] {
        let params: [String: Any] = [
            "Model": request.config.model,
            "Messages": request.messages.map { [
                "Role": $0.role.rawValue,
                "Content": $0.content
            ]},
            "Stream": request.config.stream,
            "Temperature": request.config.temperature
        ]
        
        // 验证参数
        guard JSONSerialization.isValidJSONObject(params) else {
            throw LLMError.invalidConfiguration
        }
        
        return params
    }
    
    private func buildRequestHeaders(
        params: [String: Any],
        timestamp: Int,
        action: String
    ) throws -> HTTPHeaders {
        var headers = HTTPHeaders()
        
        // 基础请求头
        headers.add(name: .contentType, value: "application/json")
        headers.add(name: "Host", value: endpoint)
        headers.add(name: "X-TC-Action", value: action)
        headers.add(name: "X-TC-Timestamp", value: String(timestamp))
        headers.add(name: "X-TC-Version", value: version)
        headers.add(name: "X-TC-Region", value: region)
        
        // 计算签名
        let authorization = try calculateAuthorization(
            params: params,
            timestamp: timestamp,
            action: action
        )
        headers.add(name: "Authorization", value: authorization)
        
        return headers
    }
    
    private func calculateAuthorization(
        params: [String: Any],
        timestamp: Int,
        action: String
    ) throws -> String {
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
        
        // 4. 组装 Authorization
        return """
        TC3-HMAC-SHA256 \
        Credential=\(secretId)/\(credentialScope), \
        SignedHeaders=content-type;host;x-tc-action, \
        Signature=\(signature)
        """
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
    
    private func parseResponse(_ response: ClientResponse) throws -> LLMResponse {
        guard let body = response.body else {
            throw LLMError.responseParsing("Empty response body")
        }
        
        struct TencentResponse: Codable {
            struct Response: Codable {
                struct Choice: Codable {
                    struct Message: Codable {
                        let content: String
                    }
                    let message: Message
                }
                struct Usage: Codable {
                    let promptTokens: Int
                    let completionTokens: Int
                    let totalTokens: Int
                }
                let choices: [Choice]
                let usage: Usage
                let requestId: String
            }
            let response: Response
        }
        
        do {
            let decoder = JSONDecoder()
            let tencentResponse = try decoder.decode(TencentResponse.self, from: body)
            
            guard let firstChoice = tencentResponse.response.choices.first else {
                throw LLMError.responseParsing("No choices in response")
            }
            
            return LLMResponse(
                content: firstChoice.message.content,
                usage: LLMUsage(
                    promptTokens: tencentResponse.response.usage.promptTokens,
                    completionTokens: tencentResponse.response.usage.completionTokens,
                    totalTokens: tencentResponse.response.usage.totalTokens
                ),
                requestId: tencentResponse.response.requestId
            )
        } catch {
            logger.error("Failed to parse response", metadata: [
                "error": .string(String(describing: error)),
                "body": .string(String(buffer: body))
            ])
            throw LLMError.responseParsing(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
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