import Fluent
import Vapor
import TencentCloudAPI

func routes(_ app: Application) throws {
  app.get { req async throws in
    try await req.view.render("index", ["title": "Hello Vapor!"])
  }

  app.get("hello") { req async -> String in
    "Hello, world!"
  }

  // API 路由组
  _ = app.grouped("api", "v1")

  // 注册 TokenController，提供 /api/get_jwt_token 接口
  try app.register(collection: SimpleJWTTokenController())

  // 注册 RevenueCat Webhook 控制器
  try app.register(collection: RevenueCatWebhookController())

  // 注册语音识别控制器
  try configureVoiceRecognition(app)

  app.get("health") { req -> String in
    return "healthy"
  }
}

/// 配置语音识别控制器
private func configureVoiceRecognition(_ app: Application) throws {
    // 从环境变量获取腾讯云API凭证
    guard let secretId = Environment.get("TENCENT_SECRET_ID"),
          let secretKey = Environment.get("TENCENT_SECRET_KEY") else {
        app.logger.warning("腾讯云API凭证未设置，语音识别服务不可用")
        return
    }
    
    // 获取地域，默认为广州
    let region = Environment.get("TENCENT_REGION") ?? "ap-guangzhou"
    
    // 创建腾讯云API配置
    let config = TencentCloudAPIConfig(
        secretId: secretId,
        secretKey: secretKey,
        region: region
    )
    
    // 注册语音识别控制器
    try app.register(collection: VoiceRecognitionController(config: config))
    
    app.logger.info("语音识别服务已配置",
                 metadata: ["region": .string(region)])
}
