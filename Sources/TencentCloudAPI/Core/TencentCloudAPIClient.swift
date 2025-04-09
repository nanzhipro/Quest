//
//  TencentCloudAPIClient.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import AsyncHTTPClient
import Foundation
import NIOCore

/// 腾讯云API客户端
public class TencentCloudAPIClient {
  // MARK: - Constants

  private enum Constants {
    static let contentType = "application/json; charset=utf-8"
    static let httpMethod = "POST"
    static let canonicalURI = "/"
    static let canonicalQueryString = ""
    static let signedHeaders = "content-type;host;x-tc-action"
    static let successStatusCodes = 200...299
  }

  // MARK: - Properties

  /// API配置
  public let config: TencentCloudAPIConfig
  /// 签名生成器
  private let signatureGenerator: TC3SignatureGenerator
  /// HTTP客户端
  private let httpClient: HTTPClient
  /// JSON编码器
  private let jsonEncoder: JSONEncoder
  /// JSON解码器
  private let jsonDecoder: JSONDecoder

  // MARK: - Initialization

  /// 初始化腾讯云API客户端
  /// - Parameter config: API配置
  public init(config: TencentCloudAPIConfig) {
    self.config = config
    self.signatureGenerator = TC3SignatureGenerator(
      secretId: config.secretId,
      secretKey: config.secretKey
    )

    var httpClientConfig = HTTPClient.Configuration()
    httpClientConfig.timeout = .init(
      connect: .seconds(Int64(config.requestTimeout)),
      read: .seconds(Int64(config.requestTimeout))
    )

    self.httpClient = HTTPClient(
      eventLoopGroupProvider: .singleton,
      configuration: httpClientConfig
    )

    self.jsonEncoder = JSONEncoder()
    self.jsonDecoder = JSONDecoder()
  }

  deinit {
    try? httpClient.syncShutdown()
  }

  // MARK: - Public Methods

  /// 发送API请求
  /// - Parameters:
  ///   - action: API操作名称
  ///   - version: API版本
  ///   - request: 请求参数
  ///   - responseType: 响应类型
  /// - Returns: API响应
  public func sendRequest<T: Encodable, R: Decodable>(
    action: String,
    version: String,
    request: T,
    responseType: R.Type
  ) async throws -> R {
    let request = try await buildRequest(
      action: action,
      version: version,
      request: request
    )

    let response = try await executeRequest(request: request)
    return try await handleResponse(response: response, responseType: responseType)
  }

  // MARK: - Private Methods

  /// 构建API请求
  private func buildRequest<T: Encodable>(
    action: String,
    version: String,
    request: T
  ) async throws -> HTTPClientRequest {
    let host = config.endpoint
    var httpRequest = HTTPClientRequest(url: "https://\(host)")
    httpRequest.method = .POST

    let requestData = try jsonEncoder.encode(request)
    httpRequest.body = .bytes(ByteBuffer(bytes: requestData))

    // 设置请求头
    try await setRequestHeaders(
      request: &httpRequest,
      host: host,
      action: action,
      version: version,
      requestBody: String(data: requestData, encoding: .utf8)!
    )

    return httpRequest
  }

  /// 设置请求头
  private func setRequestHeaders(
    request: inout HTTPClientRequest,
    host: String,
    action: String,
    version: String,
    requestBody: String
  ) async throws {
    // 设置基本请求头
    request.headers.add(name: "Content-Type", value: Constants.contentType)
    request.headers.add(name: "Host", value: host)
    request.headers.add(name: "X-TC-Action", value: action)
    request.headers.add(name: "X-TC-Version", value: version)
    request.headers.add(name: "X-TC-Region", value: config.region)

    // 设置时间戳
    let timestamp = Int(Date().timeIntervalSince1970)
    request.headers.add(name: "X-TC-Timestamp", value: "\(timestamp)")

    // 构建规范头部字符串
    let canonicalHeaders = """
      content-type:\(Constants.contentType)
      host:\(host)
      x-tc-action:\(action.lowercased())

      """

    // 构建签名信息
    let requestInfo = TC3RequestInfo(
      httpMethod: Constants.httpMethod,
      canonicalURI: Constants.canonicalURI,
      canonicalQueryString: Constants.canonicalQueryString,
      canonicalHeaders: canonicalHeaders,
      signedHeaders: Constants.signedHeaders,
      requestPayload: requestBody
    )

    // 生成并设置授权头部
    let authorizationHeader = try signatureGenerator.generateAuthorizationHeader(
      service: host.split(separator: ".").first.map(String.init) ?? "asr",
      timestamp: timestamp,
      requestInfo: requestInfo
    )
    request.headers.add(name: "Authorization", value: authorizationHeader)
  }

  /// 处理API响应
  private func handleResponse<R: Decodable>(
    response: HTTPClientResponse,
    responseType: R.Type
  ) async throws -> R {
    guard Constants.successStatusCodes.contains(Int(response.status.code)) else {
      let body = try await response.body.collect(upTo: 1024 * 1024)
      try await handleErrorResponse(data: body, statusCode: response.status.code)
      throw TencentCloudAPIError.unknown(message: "未知错误")
    }

    let body = try await response.body.collect(upTo: 1024 * 1024)
    return try await parseResponse(data: body, responseType: responseType)
  }

  /// 将ByteBuffer转换为Data
  private func convertToData(buffer: ByteBuffer) -> Foundation.Data {
    var buffer = buffer
    if let bytes = buffer.readBytes(length: buffer.readableBytes) {
      return Foundation.Data(bytes)
    }
    return Foundation.Data()
  }

  /// 处理错误响应
  private func handleErrorResponse(data: ByteBuffer, statusCode: UInt) async throws {
    do {
      let errorData = convertToData(buffer: data)
      let errorResponse = try jsonDecoder.decode(TencentCloudAPIErrorResponse.self, from: errorData)
      throw TencentCloudAPIError.serviceError(
        code: errorResponse.error.code,
        message: errorResponse.error.message
      )
    } catch {
      if let error = error as? TencentCloudAPIError {
        throw error
      }

      let errorString: String
      if let str = String(data: convertToData(buffer: data), encoding: .utf8) {
        errorString = str
      } else {
        errorString = "无法解析响应内容"
      }

      throw TencentCloudAPIError.responseParsingFailed(
        message: "HTTP状态码: \(statusCode), 无法解析错误响应: \(errorString)"
      )
    }
  }

  /// 解析响应数据
  private func parseResponse<R: Decodable>(
    data: ByteBuffer,
    responseType: R.Type
  ) async throws -> R {
    let responseData = convertToData(buffer: data)
    do {
      let wrapperResponse = try jsonDecoder.decode(
        TencentCloudAPIResponse<R>.self, from: responseData)
      return wrapperResponse.response
    } catch {
      return try jsonDecoder.decode(R.self, from: responseData)
    }
  }

  /// 执行HTTP请求，支持自动重试
  private func executeRequest(request: HTTPClientRequest) async throws -> HTTPClientResponse {
    if !config.autoRetry {
      return try await httpClient.execute(request, timeout: .seconds(Int64(config.requestTimeout)))
    }

    var lastError: Error?
    var retryCount = 0
    let retryDelays = [0.5, 1.0, 2.0, 4.0, 8.0]

    while retryCount <= config.maxRetries {
      do {
        return try await httpClient.execute(
          request, timeout: .seconds(Int64(config.requestTimeout)))
      } catch {
        lastError = error
        retryCount += 1

        if retryCount > config.maxRetries {
          throw TencentCloudAPIError.requestFailed(
            message: "请求失败，已重试\(retryCount - 1)次: \(error.localizedDescription)")
        }

        let delay =
          retryCount - 1 < retryDelays.count ? retryDelays[retryCount - 1] : retryDelays.last!
        try await Task.sleep(for: .seconds(delay))
      }
    }

    throw lastError ?? TencentCloudAPIError.unknown(message: "未知错误")
  }
}
