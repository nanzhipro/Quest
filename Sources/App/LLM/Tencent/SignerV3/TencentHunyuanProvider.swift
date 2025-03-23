//
//  TencentHunyuanProvider.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import AsyncHTTPClient
import Foundation
import Vapor

public final class TencentHunyuanProvider: LLMProvider {
  public let name = "TencentHunyuan"
  private let apiService: APIServiceProtocol
  private let signer: TencentHunyuanSigner
  private let logger: Logger
  private let config: TencentHunyuanConfig
  private let httpClient: HTTPClient

  // 添加静态方法用于时间戳和日期的处理
  static func formatUTCDate(from timestamp: Int) -> String {
    // Date 必须从时间戳 X-TC-Timestamp 计算得到，且时区为 UTC+0。
    // 详细参考： https://cloud.tencent.com/document/product/598/38504
    let utcDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    return dateFormatter.string(from: utcDate)
  }

  public init(config: TencentHunyuanConfig, app: Application) {
    let endpoint = "hunyuan.tencentcloudapi.com"
    let service = "hunyuan"

    self.config = config
    self.httpClient = HTTPClient(
      eventLoopGroupProvider: .singleton,
      configuration: .init(timeout: .init(connect: .seconds(30), read: .seconds(30)))
    )

    self.apiService = APIService(
      networkService: NetworkService(
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
    
    // 记录 Provider 初始化配置信息
    logger.info("TencentHunyuan Provider initialized", metadata: [
      "name": .string(name),
      "service": .string(service),
      "endpoint": .string(endpoint),
      "model": .string(config.model),
      "maxQueueSize": .string("\(config.maxQueueSize)"),
      "maxConcurrentRequests": .string("\(config.maxConcurrentRequests)")
    ], source: "TencentHunyuanProvider.init")
  }

  deinit {
    try? httpClient.syncShutdown()
  }

  public func execute(_ request: LLMRequest) async throws -> LLMResponse {
    let source = "TencentHunyuanProvider.execute"
    guard validateConfig(request.config) else {
      logger.error(
        "Invalid configuration",
        metadata: [
          "model": .string(request.config.model),
        ], source: source)
      throw LLMError.invalidConfiguration("Unsupported model: \(request.config.model)")
    }

    do {
      // 使用 UTC 时区生成时间戳
      let utcTimestamp = Int(Date().timeIntervalSince1970)

      // 使用统一的日期格式化方法
      let utcDateString = Self.formatUTCDate(from: utcTimestamp)

      logger.debug(
        "UTC timestamp validation",
        metadata: [
          "timestamp": .string("\(utcTimestamp)"),
          "utcDate": .string(utcDateString),
        ], source: source)

      let endpoint = TencentHunyuanEndpoint(
        request: request,
        logger: logger,
        timestamp: utcTimestamp
      )

      logger.info(
        "Preparing request",
        metadata: [
          "action": .string("ChatCompletions"),
          "timestamp": .string("\(utcTimestamp)"),
          "utcDate": .string(utcDateString),
          "model": .string(request.config.model),
          "messageCount": .string("\(request.messages.count)"),
        ], source: source)

      // 获取签名头部
      var headers = try signer.sign(
        params: endpoint.parameters ?? [:],
        timestamp: utcTimestamp,
        action: "ChatCompletions"
      )

      logger.info(
        "Generated signature headers",
        metadata: [
          "timestamp": .string("\(utcTimestamp)"),
          "headerCount": .string("\(headers.count)"),
        ], source: source)

      // 合并端点定义的头部
      endpoint.headers?.forEach { headers[$0.key] = $0.value }

      logger.info(
        "Sending request",
        metadata: [
          "endpoint": .string(endpoint.path),
          "method": .string(endpoint.method.rawValue),
        ],
        source: source
      )

      // 发送请求
      let response: TencentHunyuanResponse = try await apiService.send(
        endpoint,
        headers: headers,
        body: endpoint.body
      )

      // 记录原始响应
      if let responseData = try? JSONEncoder().encode(response),
        let responseString = String(data: responseData, encoding: .utf8)
      {
        logger.debug(
          "Raw API response",
          metadata: [
            "response": .string(responseString)
          ], source: source)
      }

      logger.info(
        "Received response",
        metadata: [
          "requestId": .string(response.response.requestId),
          "hasNote": .string(response.response.note != nil ? "true" : "false"),
          "choicesCount": .string("\(response.response.choices.count)"),
          "usage": .string("\(response.response.usage)"),
        ], source: source)

      // 转换响应
      guard let firstChoice = response.response.choices.first else {
        logger.error("No choices in response", metadata: nil, source: source)
        throw LLMError.requestFailed(NSError(domain: "LLM", code: -1, userInfo: [
          NSLocalizedDescriptionKey: "No choices in response"
        ]))
      }

      logger.info(
        "Request completed successfully",
        metadata: [
          "requestId": .string(response.response.requestId),
          "totalTokens": .string("\(response.response.usage.totalTokens)"),
        ], source: source)

      return LLMResponse(
        content: firstChoice.message.content,
        requestId: response.response.requestId
      )

    } catch {
      logger.error(
        "Request failed",
        metadata: [
          "error": .string(String(describing: error))
        ], source: source)
      throw error
    }
  }

  public func validateConfig(_ config: LLMConfig) -> Bool {
    return true
  }
}
