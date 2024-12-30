//
//  NetworkError.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

enum NetworkError: Error {
  case invalidURL
  case requestFailed(Error)
  case invalidResponse
  case decodingFailed(Error)
  case unauthorized
  case serverError(Int)
  case custom(String)
}
