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
    let jwksString = Environment.get("JWT_SECRET") ?? "your-default-secret-key"
    if Environment.get("JWT_SECRET") == nil {
        app.logger.warning("JWT_SECRET not found in environment, using default key")
    }
    app.jwt.signers.use(.hs256(key: jwksString))

    // 配置环境变量
    let llmApiKey = Environment.get("LLM_API_KEY") ?? "your-api-key"
    if Environment.get("LLM_API_KEY") == nil {
        app.logger.warning("LLM_API_KEY not found in environment, using default key")
        Environment.process.LLM_API_KEY = llmApiKey
    }
    
    let llmApiEndpoint = Environment.get("LLM_API_ENDPOINT") ?? "https://api.llm-service.com/v1/analyze"
    if Environment.get("LLM_API_ENDPOINT") == nil {
        app.logger.warning("LLM_API_ENDPOINT not found in environment, using default endpoint")
        Environment.process.LLM_API_ENDPOINT = llmApiEndpoint
    }
    
    app.logger.info("LLM configuration: endpoint=\(llmApiEndpoint)")

    // register routes
    try routes(app)
}
