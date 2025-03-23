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

  // 设置最大请求体大小为 1MB
  app.routes.defaultMaxBodySize = "1mb"
  app.log.info(
    "Set default max body size to 1mb", 
    metadata: ["maxBodySize": .string("1mb")], 
    source: "configure"
  )

  // 加载 .env 文件
  _ = try Environment.detect()
  app.logger.info("Environment variables loaded")

  // 验证关键环境变量
  if Environment.get("TENCENT_SECRET_ID") == nil {
    app.logger.warning("TENCENT_SECRET_ID not found in environment")
  }
  
  // 记录当前使用的腾讯混元模型
  app.logger.info(
    "Tencent Hunyuan Model configuration",
    metadata: [
      "model": .string(Environment.get("TENCENT_MODEL") ?? "hunyuan-standard-256K (default)")
    ],
    source: "configure"
  )

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

  // 全局注册 JWT 中间件，确保所有请求在进入路由前均需经过 JWT 验证
  app.middleware.use(AuthJWTMiddleware())

  // 配置 LLM 服务
  do {
    // 从环境变量或配置中获取要使用的 LLM 提供者
    let provider: LLMProviderType =
      Environment.get("LLM_PROVIDER") == "deepseek" ? .deepseek : .tencentHunyuanOpenAI

    // 建并执行初始化
    let initializer = LLMInitializerFactory.createInitializer(for: provider)
    try initializer.initialize(app: app)
  } catch {
    app.logger.error("Failed to configure LLM: \(error)")
  }

  // 注册 LLM 路由
  try LLMController(promptService: app.environment == .testing ? 
                               InMemoryPromptService.shared : 
                               DatabasePromptService(db: app.db)).routes(app)

  // 注释掉数据库迁移，使用内存存储进行测试
  app.migrations.add(CreatePrompt())
  app.migrations.add(CreateUserSubscription())

  // 添加自动迁移（仅限开发环境）
  if app.environment == .development {
      try await app.autoMigrate().get()
  }

  // 配置 TLS
  try configureTLS(app)

  // 添加用户订阅迁移
  app.migrations.add(CreateUserSubscription())

  // register routes
  try routes(app)
  try app.register(collection: PromptController(promptService: DatabasePromptService(db: app.db)))
  try app.register(collection: ConfigController())
}

private func configureTLS(_ app: Application) throws {
    let certPath = Environment.get("TLS_CERT_PATH") ?? "/app/certs/cert.pem"
    let keyPath = Environment.get("TLS_KEY_PATH") ?? "/app/certs/key.pem"
    
    do {
        app.logger.info("Attempting to load TLS certificates",
                      metadata: ["certPath": .string(certPath),
                               "keyPath": .string(keyPath)])
        
        let cert = try NIOSSLCertificate(file: certPath, format: .pem)
        let key = try NIOSSLPrivateKey(file: keyPath, format: .pem)
        
        // 配置 TLS
        var tlsConfig = TLSConfiguration.makeServerConfiguration(
            certificateChain: [.certificate(cert)],
            privateKey: .privateKey(key)
        )
        
        // 设置 TLS 安全选项
        tlsConfig.minimumTLSVersion = .tlsv12           // 最低使用 TLS 1.2
        tlsConfig.maximumTLSVersion = .tlsv13           // 最高支持 TLS 1.3
        tlsConfig.certificateVerification = .none       // 服务端模式不验证客户端证书
        
        // 配置 HTTPS 服务器
        app.http.server.configuration = .init(
            hostname: "0.0.0.0",
            port: 443,
            backlog: 256,                               // 连接队列大小
            reuseAddress: true,                         // 允许端口重用
            tcpNoDelay: true,                           // 优化 TCP 延迟
            supportVersions: [.one, .two],              // 同时支持 HTTP/1.x 和 HTTP/2
            tlsConfiguration: tlsConfig
        )
        
        app.logger.info("TLS configuration completed successfully", metadata: [
            "port": .string("443"),
            "http_versions": .string("HTTP/1.x, HTTP/2"),
            "tls_version": .string("1.2-1.3")
        ])
        
    } catch let error as NIOSSLError {
        // 处理 SSL 相关错误
        app.logger.warning("SSL configuration error: \(error). Falling back to HTTP", metadata: [
            "error_type": .string("\(type(of: error))"),
            "error_description": .string(error.localizedDescription)
        ])
        fallbackToHTTP(app)
    } catch {
        // 处理其他错误
        app.logger.warning("Failed to load TLS certificates: \(error). Falling back to HTTP")
        fallbackToHTTP(app)
    }
}

/// 降级到 HTTP 服务
private func fallbackToHTTP(_ app: Application) {
    app.http.server.configuration = .init(
        hostname: "0.0.0.0",
        port: 8080,
        backlog: 256,
        reuseAddress: true,
        tcpNoDelay: true,
        supportVersions: [.one]  // HTTP 模式仅支持 HTTP/1.x
    )
    
    app.logger.info("HTTP server configured", metadata: [
        "port": .string("8080"),
        "http_version": .string("HTTP/1.x")
    ])
}
