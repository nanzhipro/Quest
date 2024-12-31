import Vapor

struct TencentHunyuanOpenAIInitializer: LLMInitializer {
    private enum Constants {
        static let apiKeyEnv = "TENCENT_HUNYUAN_API_KEY"
    }
    
    func initialize(app: Application) throws {
        let apiToken = try requireApiToken(app)
        let config = TencentHunyuanOpenAIConfig(apiToken: apiToken)
        
        let provider = TencentHunyuanOpenAIProvider(config: config, app: app)
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
