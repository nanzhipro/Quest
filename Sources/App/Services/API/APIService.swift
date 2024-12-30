//
//  APIService.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

final class APIService: APIServiceProtocol, @unchecked Sendable {
  private let networkService: NetworkServiceProtocol

  init(networkService: NetworkServiceProtocol) {
    self.networkService = networkService
  }

  func fetch<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
    try await networkService.request(
      endpoint.path,
      method: endpoint.method,
      headers: nil,
      body: nil as String?
    )
  }

  func send<T: Decodable>(_ endpoint: APIEndpoint, headers: [String: String]?, body: Encodable?)
    async throws -> T
  {
    try await networkService.request(
      endpoint.path,
      method: endpoint.method,
      headers: headers,
      body: body
    )
  }
}
