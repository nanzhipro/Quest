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

  // 注册其他 API 控制器
  try api.register(collection: MemberController())

  // 注册 TokenController，提供 /api/get_jwt_token 接口
  try app.register(collection: SimpleJWTTokenController())

  // 注册 RevenueCat Webhook 控制器
  try app.register(collection: RevenueCatWebhookController())

  app.get("health") { req -> String in
    return "healthy"
  }
}
