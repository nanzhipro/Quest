//
//  NetworkServiceProtocol.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import AsyncHTTPClient
import Foundation
import NIOCore

protocol NetworkServiceProtocol {
    func request<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Encodable?
    ) async throws -> T
    
    func upload(
        _ data: ByteBuffer,
        to endpoint: String,
        headers: [String: String]?
    ) async throws -> String
} 