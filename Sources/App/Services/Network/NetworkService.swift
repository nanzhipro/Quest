//
//  NetworkService.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import AsyncHTTPClient
import Foundation
import NIOCore
import Vapor

final class NetworkService: NetworkServiceProtocol {
  private let client: HTTPClient
  private let baseURL: String
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder
  private let logger: Logger

  init(
    client: HTTPClient,
    baseURL: String,
    decoder: JSONDecoder = .init(),
    encoder: JSONEncoder = .init(),
    logger: Logger? = nil
  ) {
    self.client = client
    self.baseURL = baseURL
    self.decoder = decoder
    self.encoder = encoder
    if let logger = logger {
      self.logger = logger
    } else {
      var logger = Logger(label: "NetworkService")
      logger.logLevel = Environment.logLevel
      self.logger = logger
    }
  }

  private func formatRequestDetails(
    url: URL,
    method: HTTPMethod,
    headers: [String: String]?,
    body: Encodable?
  ) throws -> String {
    var details = """
      🌐 Request Details:
      📍 URL: \(url.absoluteString)
      📝 Method: \(method.rawValue)

      📋 Headers:
      """

    if let headers = headers, !headers.isEmpty {
      details +=
        "\n"
        + headers
        .sorted(by: { $0.key < $1.key })
        .map { "   \($0.key): \($0.value)" }
        .joined(separator: "\n")
    } else {
      details += "\n   No headers"
    }

    details += "\n\n📦 Body:"
    if let body = body {
      let bodyData = try encoder.encode(body)
      if let jsonObject = try? JSONSerialization.jsonObject(with: bodyData),
        let prettyData = try? JSONSerialization.data(
          withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
        let prettyString = String(data: prettyData, encoding: .utf8)
      {
        details +=
          "\n\(prettyString.split(separator: "\n").map { "   \($0)" }.joined(separator: "\n"))"
      } else {
        details += "\n   Unable to format body as JSON"
      }
    } else {
      details += "\n   No body"
    }

    return details
  }

  func request<T: Decodable>(
    _ endpoint: String,
    method: HTTPMethod,
    headers: [String: String]? = nil,
    body: Encodable? = nil
  ) async throws -> T {
    let source = "NetworkService.request"

    guard let url = URL(string: baseURL + endpoint) else {
      logger.error(
        "Invalid URL",
        metadata: [
          "baseURL": .string(baseURL),
          "endpoint": .string(endpoint),
        ], source: source)
      throw NetworkError.invalidURL
    }

    logger.debug(
      "Preparing request",
      metadata: [
        "url": .string(url.absoluteString),
        "method": .string(method.rawValue),
        "headerCount": .string("\(headers?.count ?? 0)"),
      ], source: source)

    if logger.logLevel <= .debug {
      let requestDetails = try formatRequestDetails(
        url: url,
        method: method,
        headers: headers,
        body: body
      )
      logger.debug("\n\(requestDetails)", source: source)
    }

    var request = HTTPClientRequest(url: url.absoluteString)
    request.method = .init(rawValue: method.rawValue)

    headers?.forEach { request.headers.add(name: $0.key, value: $0.value) }

    if let body = body {
      let data = try encoder.encode(body)
      request.body = .bytes(ByteBuffer(data: data))
      logger.debug(
        "Request body prepared",
        metadata: [
          "bodySize": .string("\(data.count)")
        ], source: source)
    }

    logger.info(
      "Executing request",
      metadata: [
        "url": .string(url.absoluteString),
        "method": .string(method.rawValue),
      ], source: source)

    let response = try await client.execute(request, timeout: .seconds(30))

    logger.debug(
      "Received response",
      metadata: [
        "statusCode": .string("\(response.status.code)"),
        "headers": .string("\(response.headers)"),
      ], source: source)

    guard (200...299).contains(response.status.code) else {
      logger.error(
        "Server error",
        metadata: [
          "statusCode": .string("\(response.status.code)"),
          "url": .string(url.absoluteString),
        ], source: source)
      throw NetworkError.serverError(Int(response.status.code))
    }

    let responseData = try await response.body.collect(upTo: 1024 * 1024)  // 1MB limit

    logger.debug(
      "Processing response body",
      metadata: [
        "dataSize": .string("\(responseData.readableBytes)")
      ], source: source)

    do {
      // 尝试将响应数据转换为JSON对象
      if let jsonObject = try? JSONSerialization.jsonObject(with: Data(buffer: responseData)),
        // 如果成功，则尝试将JSON对象转换为格式化后的数据
        let prettyData = try? JSONSerialization.data(
          withJSONObject: jsonObject, options: .prettyPrinted),
        // 如果成功，则尝试将格式化后的数据转换为字符串
        let prettyJSON = String(data: prettyData, encoding: .utf8)
      {
        // 如果所有步骤都成功，则记录格式化后的JSON字符串
        logger.debug(
          "Response JSON",
          metadata: [
            "url": .string(url.absoluteString),
            "json": .string(prettyJSON),
          ], source: source)
      }

      // 使用解码器解码响应数据
      let decoded = try decoder.decode(T.self, from: Data(buffer: responseData))
      // 记录请求完成的日志
      logger.info(
        "Request completed successfully",
        metadata: [
          "url": .string(url.absoluteString),
          "statusCode": .string("\(response.status.code)"),
        ], source: source)
      // 返回解码后的数据
      return decoded
    } catch {
      // 如果解码或格式化过程中发生错误，则记录错误日志
      logger.error(
        "Response parsing failed",
        metadata: [
          "error": .string("\(error)"),
          "type": .string("\(T.self)"),
          "rawResponse": .string(String(buffer: responseData)),
        ], source: source)
      // 抛出捕获到的错误
      throw error
    }
  }

  func upload(
    _ data: ByteBuffer,
    to endpoint: String,
    headers: [String: String]? = nil
  ) async throws -> String {
    let source = "NetworkService.upload"

    guard let url = URL(string: baseURL + endpoint) else {
      logger.error(
        "Invalid upload URL",
        metadata: [
          "baseURL": .string(baseURL),
          "endpoint": .string(endpoint),
        ], source: source)
      throw NetworkError.invalidURL
    }

    logger.debug(
      "Preparing upload",
      metadata: [
        "url": .string(url.absoluteString),
        "dataSize": .string("\(data.readableBytes)"),
        "headerCount": .string("\(headers?.count ?? 0)"),
      ], source: source)

    var request = HTTPClientRequest(url: url.absoluteString)
    request.method = .POST
    request.body = .bytes(data)

    headers?.forEach { request.headers.add(name: $0.key, value: $0.value) }

    logger.info(
      "Starting upload",
      metadata: [
        "url": .string(url.absoluteString),
        "dataSize": .string("\(data.readableBytes)"),
      ], source: source)

    let response = try await client.execute(request, timeout: .seconds(60))

    logger.debug(
      "Received upload response",
      metadata: [
        "statusCode": .string("\(response.status.code)"),
        "headers": .string("\(response.headers)"),
      ], source: source)

    guard (200...299).contains(response.status.code) else {
      logger.error(
        "Upload failed",
        metadata: [
          "statusCode": .string("\(response.status.code)"),
          "url": .string(url.absoluteString),
        ], source: source)
      throw NetworkError.serverError(Int(response.status.code))
    }

    let responseData = try await response.body.collect(upTo: 1024 * 1024)
    let result = String(buffer: responseData)

    logger.info(
      "Upload completed successfully",
      metadata: [
        "url": .string(url.absoluteString),
        "responseSize": .string("\(result.count)"),
      ], source: source)

    return result
  }
}
