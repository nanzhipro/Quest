import Vapor

struct TencentHunyuanOpenAIInitializer: LLMInitializer {
  func initialize(app: Application) throws {
    // 实现 OpenAI 的初始化逻辑
    guard let apiToken = Environment.get("TENCENT_HUNYUAN_API_KEY") else {
      app.logger.error("Missing TENCENT_HUNYUAN_API_KEY")
      throw LLMInitializerError.missingConfiguration
    }

    let config: TencentHunyuanOpenAIConfig = TencentHunyuanOpenAIConfig(
      apiToken: apiToken,
      model: "hunyuan-lite",
      maxQueueSize: 100,
      maxConcurrentRequests: 10)

    let provider = TencentHunyuanOpenAIProvider(config: config, app: app)
    LLMConfiguration.shared.register(provider: provider, isActive: true, app: app)
  }
}
