import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    // API 路由组
    let api = app.grouped("api", "v1")
    
    // 配置 LLM Service
    let llmService = LLMService(
        client: app.client,
        apiKey: Environment.get("LLM_API_KEY") ?? "",
        apiEndpoint: Environment.get("LLM_API_ENDPOINT") ?? ""
    )
    
    // 注册 AI 控制器
    try api.register(collection: AIController(llmService: llmService))
    
    // 注册其他 API 控制器
    try api.register(collection: MemberController())
    try app.register(collection: TodoController())

    app.get("health") { req -> String in
        return "healthy"
    }
}
