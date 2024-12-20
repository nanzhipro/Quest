//
//  APIServiceProtocol.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

protocol APIServiceProtocol: Sendable {
    func fetch<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func send<T: Decodable>(_ endpoint: APIEndpoint, headers: [String: String]?, body: Encodable?) async throws -> T
} 