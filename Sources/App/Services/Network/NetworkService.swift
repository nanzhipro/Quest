//
//  NetworkService.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import AsyncHTTPClient
import Foundation
import NIOCore

final class NetworkService: NetworkServiceProtocol {
    private let client: HTTPClient
    private let baseURL: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(
        client: HTTPClient,
        baseURL: String,
        decoder: JSONDecoder = .init(),
        encoder: JSONEncoder = .init()
    ) {
        self.client = client
        self.baseURL = baseURL
        self.decoder = decoder
        self.encoder = encoder
    }
    
    func request<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = HTTPClientRequest(url: url.absoluteString)
        request.method = .init(rawValue: method.rawValue)
        
        headers?.forEach { request.headers.add(name: $0.key, value: $0.value) }
        
        if let body = body {
            let data = try encoder.encode(body)
            request.body = .bytes(ByteBuffer(data: data))
        }
        
        let response = try await client.execute(request, timeout: .seconds(30))
        
        guard (200...299).contains(response.status.code) else {
            throw NetworkError.serverError(Int(response.status.code))
        }
        
        let responseData = try await response.body.collect(upTo: 1024 * 1024) // 1MB limit
        return try decoder.decode(T.self, from: Data(buffer: responseData))
    }
    
    func upload(
        _ data: ByteBuffer,
        to endpoint: String,
        headers: [String: String]? = nil
    ) async throws -> String {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = HTTPClientRequest(url: url.absoluteString)
        request.method = .POST
        request.body = .bytes(data)
        
        headers?.forEach { request.headers.add(name: $0.key, value: $0.value) }
        
        let response = try await client.execute(request, timeout: .seconds(60))
        
        guard (200...299).contains(response.status.code) else {
            throw NetworkError.serverError(Int(response.status.code))
        }
        
        let responseData = try await response.body.collect(upTo: 1024 * 1024)
        return String(buffer: responseData)
    }
} 