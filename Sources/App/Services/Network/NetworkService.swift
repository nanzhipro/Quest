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
    
    func request<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: Encodable? = nil
    ) async throws -> T {
        let source = "NetworkService.request"
        
        guard let url = URL(string: baseURL + endpoint) else {
            logger.error("Invalid URL", metadata: [
                "baseURL": .string(baseURL),
                "endpoint": .string(endpoint)
            ], source: source)
            throw NetworkError.invalidURL
        }
        
        logger.debug("Preparing request", metadata: [
            "url": .string(url.absoluteString),
            "method": .string(method.rawValue),
            "headerCount": .string("\(headers?.count ?? 0)")
        ], source: source)
        
        var request = HTTPClientRequest(url: url.absoluteString)
        request.method = .init(rawValue: method.rawValue)
        
        headers?.forEach { request.headers.add(name: $0.key, value: $0.value) }
        
        if let body = body {
            let data = try encoder.encode(body)
            request.body = .bytes(ByteBuffer(data: data))
            logger.debug("Request body prepared", metadata: [
                "bodySize": .string("\(data.count)")
            ], source: source)
        }
        
        logger.info("Executing request", metadata: [
            "url": .string(url.absoluteString),
            "method": .string(method.rawValue)
        ], source: source)
        
        let response = try await client.execute(request, timeout: .seconds(30))
        
        logger.debug("Received response", metadata: [
            "statusCode": .string("\(response.status.code)"),
            "headers": .string("\(response.headers)")
        ], source: source)
        
        guard (200...299).contains(response.status.code) else {
            logger.error("Server error", metadata: [
                "statusCode": .string("\(response.status.code)"),
                "url": .string(url.absoluteString)
            ], source: source)
            throw NetworkError.serverError(Int(response.status.code))
        }
        
        let responseData = try await response.body.collect(upTo: 1024 * 1024) // 1MB limit
        
        logger.debug("Processing response body", metadata: [
            "dataSize": .string("\(responseData.readableBytes)")
        ], source: source)
        
        do {
            let decoded = try decoder.decode(T.self, from: Data(buffer: responseData))
            logger.info("Request completed successfully", metadata: [
                "url": .string(url.absoluteString),
                "statusCode": .string("\(response.status.code)")
            ], source: source)
            return decoded
        } catch {
            logger.error("Response parsing failed", metadata: [
                "error": .string("\(error)"),
                "type": .string("\(T.self)")
            ], source: source)
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
            logger.error("Invalid upload URL", metadata: [
                "baseURL": .string(baseURL),
                "endpoint": .string(endpoint)
            ], source: source)
            throw NetworkError.invalidURL
        }
        
        logger.debug("Preparing upload", metadata: [
            "url": .string(url.absoluteString),
            "dataSize": .string("\(data.readableBytes)"),
            "headerCount": .string("\(headers?.count ?? 0)")
        ], source: source)
        
        var request = HTTPClientRequest(url: url.absoluteString)
        request.method = .POST
        request.body = .bytes(data)
        
        headers?.forEach { request.headers.add(name: $0.key, value: $0.value) }
        
        logger.info("Starting upload", metadata: [
            "url": .string(url.absoluteString),
            "dataSize": .string("\(data.readableBytes)")
        ], source: source)
        
        let response = try await client.execute(request, timeout: .seconds(60))
        
        logger.debug("Received upload response", metadata: [
            "statusCode": .string("\(response.status.code)"),
            "headers": .string("\(response.headers)")
        ], source: source)
        
        guard (200...299).contains(response.status.code) else {
            logger.error("Upload failed", metadata: [
                "statusCode": .string("\(response.status.code)"),
                "url": .string(url.absoluteString)
            ], source: source)
            throw NetworkError.serverError(Int(response.status.code))
        }
        
        let responseData = try await response.body.collect(upTo: 1024 * 1024)
        let result = String(buffer: responseData)
        
        logger.info("Upload completed successfully", metadata: [
            "url": .string(url.absoluteString),
            "responseSize": .string("\(result.count)")
        ], source: source)
        
        return result
    }
} 