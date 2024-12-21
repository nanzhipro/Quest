//
//  TencentHunyuanProvider.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor
import AsyncHTTPClient

public final class TencentHunyuanProvider: LLMProvider {
    public let name = "TencentHunyuan"
    public let supportedModels = ["hunyuan-lite"]
    
    private let apiService: APIServiceProtocol
    private let signer: TencentHunyuanSigner
    private let logger: Logger
    private let config: TencentHunyuanConfig
    private let httpClient: HTTPClient
    
    public init(config: TencentHunyuanConfig, app: Application) {
        let endpoint = "hunyuan.tencentcloudapi.com"
        let service = "hunyuan"
        
        self.config = config
        self.httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: .init(timeout: .init(connect: .seconds(30), read: .seconds(30)))
        )
        
        self.apiService = APIService(networkService: NetworkService(
            client: httpClient,
            baseURL: "https://\(endpoint)",
            logger: app.logger
        ))
        
        self.signer = TencentHunyuanSigner(
            secretId: config.secretId,
            secretKey: config.secretKey,
            service: service,
            endpoint: endpoint,
            app: app
        )
        
        self.logger = app.logger
    }
    
    deinit {
        try? httpClient.syncShutdown()
    }
    
    public func execute(_ request: LLMRequest) async throws -> LLMResponse {
        let source = "TencentHunyuanProvider.execute"
        guard validateConfig(request.config) else {
            logger.error("Invalid configuration", metadata: [
                "model": .string(request.config.model),
                "supportedModels": .string(supportedModels.joined(separator: ", "))
            ], source: source)
            throw LLMError.invalidConfiguration
        }
        
        do {
            let timestamp = Int(floor(Date().timeIntervalSince1970))
            let endpoint = TencentHunyuanEndpoint(request: request, logger: logger)
            
            logger.info("Preparing request", metadata: [
                "action": .string("ChatCompletions"),
                "timestamp": .string("\(timestamp)"),
                "model": .string(request.config.model),
                "messageCount": .string("\(request.messages.count)")
            ], source: source)
            
            // 获取签名头部
            var headers = try signer.sign(
                params: endpoint.parameters ?? [:],
                timestamp: timestamp,
                action: "ChatCompletions"
            )


            
            logger.info("Generated signature headers", metadata: [
                "timestamp": .string("\(timestamp)"),
                "headerCount": .string("\(headers.count)")
            ], source: source)
            
            // 合并端点定义的头部
            endpoint.headers?.forEach { headers[$0.key] = $0.value }
            
            // 添加区域头部
            headers["X-TC-Region"] = config.region
            
            logger.info("Sending request", metadata: [
                "region": .string(config.region),
                "endpoint": .string(endpoint.path),
                "method": .string(endpoint.method.rawValue)
            ], source: source)
            
            // 发送请求
            let response: TencentHunyuanResponse = try await apiService.send(
                endpoint,
                headers: headers,
                body: endpoint.body
            )
            
            // 记录原始响应
            if let responseData = try? JSONEncoder().encode(response),
               let responseString = String(data: responseData, encoding: .utf8) {
                logger.debug("Raw API response", metadata: [
                    "response": .string(responseString)
                ], source: source)
            }
            
            logger.info("Received response", metadata: [
                "requestId": .string(response.response.requestId),
                "hasNote": .string(response.response.note != nil ? "true" : "false"),
                "choicesCount": .string("\(response.response.choices.count)"),
                "usage": .string("\(response.response.usage)")
            ], source: source)
            
            // 转换响应
            guard let firstChoice = response.response.choices.first else {
                logger.error("No choices in response", metadata: nil, source: source)
                throw LLMError.responseParsing("No choices in response")
            }
            
            logger.info("Request completed successfully", metadata: [
                "requestId": .string(response.response.requestId),
                "totalTokens": .string("\(response.response.usage.totalTokens)")
            ], source: source)
            
            return LLMResponse(
                content: firstChoice.message.content,
                usage: LLMUsage(
                    promptTokens: response.response.usage.promptTokens,
                    completionTokens: response.response.usage.completionTokens,
                    totalTokens: response.response.usage.totalTokens
                ),
                requestId: response.response.requestId
            )
            
        } catch {
            logger.error("Request failed", metadata: [
                "error": .string(String(describing: error))
            ], source: source)
            throw error
        }
    }
    
    public func executeStream(_ request: LLMRequest) async throws -> AsyncThrowingStream<String, Error> {
        guard validateConfig(request.config) else {
            logger.error("Invalid configuration for stream request")
            throw LLMError.invalidConfiguration
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    logger.debug("Starting stream request")
                    
                    // 修改请求配置为流式
                    var streamRequest = request
                    streamRequest.config.stream = true
                    
                    let response = try await execute(streamRequest)
                    
                    // 解析 SSE 格式响应
                    let chunks = response.content.components(separatedBy: "\n\n")
                    for chunk in chunks where !chunk.isEmpty {
                        if chunk.hasPrefix("data: ") {
                            let content = String(chunk.dropFirst(6))
                            continuation.yield(content)
                        }
                    }
                    
                    logger.info("Stream request completed")
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
} 