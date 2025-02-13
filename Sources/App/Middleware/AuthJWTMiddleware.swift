//
//  AuthJWTMiddleware.swift
//  VaporProject
//
//  Created by CursorAI on 2023-10-04.
//

import Vapor
import JWT

struct AuthJWTMiddleware: Middleware {
    // 定义需要排除的路径
    private static let excludedPaths: Set<String> = [
        "/api/get_jwt_token"
    ]
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        let logger = request.logger
        logger.info("Starting JWT authentication for request")
        
        // 检查当前路径是否在排除列表中
        if Self.excludedPaths.contains(request.url.path) {
            logger.info("Skipping JWT verification for excluded path: \(request.url.path)")
            return next.respond(to: request)
        }
        
        // 从请求头中提取 Authorization 字段
        guard let authHeader = request.headers.first(name: .authorization),
              authHeader.hasPrefix("Bearer ") else {
            logger.warning("Missing or invalid Authorization header")
            return request.eventLoop.makeSucceededFuture(
                Response(status: .unauthorized, body: .init(string: "Unauthorized"))
            )
        }
        
        let token = authHeader.replacingOccurrences(of: "Bearer ", with: "")
        
        do {
            // 使用统一的 AuthPayload 验证 token
            let payload = try request.jwt.verify(token, as: AuthPayload.self)
            logger.info("JWT verification successful", metadata: [
                "userID": .string(payload.sub.value)
            ])
            // 如果需要，可将解析后的 payload 存储到 request.auth 供后续使用
            return next.respond(to: request)
        } catch {
            logger.error("JWT verification failed: \(error.localizedDescription)")
            return request.eventLoop.makeSucceededFuture(
                Response(status: .unauthorized, body: .init(string: "Invalid or expired token"))
            )
        }
    }
} 