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
    
    public init(config: TencentHunyuanConfig) {
        let endpoint = "hunyuan.tencentcloudapi.com"
        let service = "hunyuan"
        
        self.config = config
        self.httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: .init(timeout: .init(connect: .seconds(30), read: .seconds(30)))
        )
        
        self.apiService = APIService(networkService: NetworkService(
            client: httpClient,
            baseURL: "https://\(endpoint)"
        ))
        
        self.signer = TencentHunyuanSigner(
            secretId: config.secretId,
            secretKey: config.secretKey,
            service: service,
            endpoint: endpoint
        )
        
        self.logger = Logger(label: "TencentHunyuanProvider")
    }
    
    deinit {
        try? httpClient.syncShutdown()
    }
    
    public func execute(_ request: LLMRequest) async throws -> LLMResponse {
        guard validateConfig(request.config) else {
            logger.error("Invalid configuration", metadata: [
                "model": .string(request.config.model),
                "supportedModels": .string(supportedModels.joined(separator: ", "))
            ])
            throw LLMError.invalidConfiguration
        }
        
        do {
            let timestamp = Int(floor(Date().timeIntervalSince1970))
            let endpoint = TencentHunyuanEndpoint.chatCompletions(request)
            
            logger.debug("Preparing request", metadata: [
                "action": .string("ChatCompletions"),
                "timestamp": .string("\(timestamp)")
            ])
            
            // 获取签名头部
            var headers = try signer.sign(
                params: endpoint.body as! [String: Any],
                timestamp: timestamp,
                action: "ChatCompletions"
            )
            
            // 合并端点定义的头部
            endpoint.headers?.forEach { headers[$0.key] = $0.value }
            
            logger.debug("Sending request to Tencent Hunyuan")
            
            // 发送请求
            let response: TencentHunyuanResponse = try await apiService.send(
                endpoint,
                headers: headers,
                body: endpoint.body
            )
            
            // 转换响应
            guard let firstChoice = response.response.choices.first else {
                logger.error("No choices in response")
                throw LLMError.responseParsing("No choices in response")
            }
            
            logger.info("Request completed successfully", metadata: [
                "requestId": .string(response.response.requestId),
                "totalTokens": .string("\(response.response.usage.totalTokens)")
            ])
            
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
            ])
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
                    
                    // 解析 SSE 格式的响应
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