import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    app.migrations.add(CreateTodo())

    app.views.use(.leaf)

    // 配置 JWT
    app.jwt.signers.use(.hs256(key: AppEnvironment.jwtSecret))
    
    // 配置 LLM 服务
    do {
        // 从环境变量或配置中获取要使用的 LLM 提供者
        let provider: LLMProviderType = Environment.get("LLM_PROVIDER") == "doubao" ? .doubao : .tencentHunyuan
        
        // 创建并执行初始化
        let initializer = LLMInitializerFactory.createInitializer(for: provider)
        try initializer.initialize(app: app)
    } catch {
        app.logger.error("Failed to configure LLM: \(error)")
    }
    
    // 注册 LLM 路由
    try LLMController().routes(app)
    
    // register routes
    try routes(app)

    // 配置日志服务
    let loggingConfiguration = LoggingConfiguration(
        label: "app.vapor",
        metadata: [
            "app": .string("VaporApp"),
            "environment": .string(app.environment.name)
        ]
    )
    app.log = LoggingService(configuration: loggingConfiguration)
}
