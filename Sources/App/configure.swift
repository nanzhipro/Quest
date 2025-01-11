import Fluent
import FluentPostgresDriver
import JWT
import Leaf
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
  // 从环境变量设置日志级别
  app.logger.logLevel = Environment.logLevel

  // 配置日志服务
  let loggingConfig = LoggingConfiguration(
    label: "app.vapor",
    metadata: [
      "app": .string("VaporApp"),
      "environment": .string(app.environment.name),
      "logLevel": .string("\(Environment.logLevel)"),
    ]
  )
  app.log = LoggingService(configuration: loggingConfig)

  app.log.info(
    "Application starting",
    metadata: [
      "environment": .string(app.environment.name),
      "logLevel": .string("\(app.logger.logLevel)"),
    ], source: "configure")

  // 加载 .env 文件
  _ = try Environment.detect()
  app.logger.info("Environment variables loaded")

  // 验证关键环境变量
  if Environment.get("TENCENT_SECRET_ID") == nil {
    app.logger.warning("TENCENT_SECRET_ID not found in environment")
  }

  // uncomment to serve files from /Public folder
  // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

  app.databases.use(
    DatabaseConfigurationFactory.postgres(
      configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:))
          ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "yourusername",
        password: Environment.get("DATABASE_PASSWORD") ?? "yourpassword",
        database: Environment.get("DATABASE_NAME") ?? "yourdatabase",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

  app.views.use(.leaf)

  // 配置 JWT
  app.jwt.signers.use(.hs256(key: AppEnvironment.jwtSecret))

  // 配置 LLM 服务
  do {
    // 从环境变量或配置中获取要使用的 LLM 提供者
    let provider: LLMProviderType =
      Environment.get("LLM_PROVIDER") == "doubao" ? .doubao : .tencentHunyuanOpenAI

    // 建并执行初始化
    let initializer = LLMInitializerFactory.createInitializer(for: provider)
    try initializer.initialize(app: app)
  } catch {
    app.logger.error("Failed to configure LLM: \(error)")
  }

  // 注册 LLM 路由
  try LLMController().routes(app)

  // 注释掉数据库迁移，使用内存存储进行测试
  app.migrations.add(CreatePrompt())
  app.migrations.add(CreateInitialPrompt())

  // 添加自动迁移（仅限开发环境）
  if app.environment == .development {
      try await app.autoMigrate().get()
  }

  // register routes
  try routes(app)
  try app.register(collection: PromptController(promptService: DatabasePromptService(db: app.db)))
}
