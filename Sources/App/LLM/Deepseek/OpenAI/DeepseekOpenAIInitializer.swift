//
//  DeepseekOpenAIInitializer.swift
//  Quest
//
//  Created by CursorAI on 2024-01-09.
//

import Vapor

struct DeepseekOpenAIInitializer: LLMInitializer {
    private enum Constants {
        static let apiKeyEnv = "DEEPSEEK_API_KEY"
    }
    
    func initialize(app: Application) throws {
        let apiToken = try requireApiToken(app)
        let config = DeepseekOpenAIConfig(apiToken: apiToken)
        
        let provider = DeepseekOpenAIProvider(config: config, app: app)
        LLMConfiguration.shared.register(provider: provider, isActive: true, app: app)
    }
    
    private func requireApiToken(_ app: Application) throws -> String {
        guard let apiToken = Environment.get(Constants.apiKeyEnv) else {
            app.logger.error("Missing required environment variable", metadata: [
                "variable": .string(Constants.apiKeyEnv)
            ])
            throw LLMInitializerError.missingConfiguration
        }
        return apiToken
    }
} 