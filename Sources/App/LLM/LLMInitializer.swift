//
//  LLMInitializer.swift
//  App
//
//  Created by CursorAI on 2024-03-20.
//

import Vapor

protocol LLMInitializer {
  func initialize(app: Application) throws
}

enum LLMInitializerError: Error {
  case missingConfiguration
  case invalidConfiguration
  case initializationFailed(Error)
}
