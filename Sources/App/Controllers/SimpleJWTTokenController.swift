//
//  SimpleJWTTokenController.swift
//  Quest
//
//  Created by CursorAI on 2023-10-04.
//

import Vapor
import JWT

// 用于解析客户端请求体中携带的凭据数据
struct JWTTokenRequest: Content {
    let client_id: String
    let client_secret: String
}

// 用于返回生成的 JWT token
struct JWTTokenResponse: Content {
    let token: String
}

// 定义 JWT 的载荷结构，包含发布者和过期时间声明
struct ClientPayload: JWTPayload {
    let iss: IssuerClaim
    let exp: ExpirationClaim

    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
}

// SimpleJWTTokenController 实现了 RouteCollection，用于注册 /api/get_jwt_token 路由
struct SimpleJWTTokenController: RouteCollection {
    // 硬编码的客户端凭据
    private let validClientId = "QuestService"
    private let validClientSecret = "QuestSecret"
    
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.post("get_jwt_token", use: tokenHandler)
    }
    
    // 处理 /api/get_jwt_token 请求的路由函数
    func tokenHandler(req: Request) throws -> EventLoopFuture<JWTTokenResponse> {
        let tokenRequest = try req.content.decode(JWTTokenRequest.self)
        
        guard tokenRequest.client_id == validClientId,
              tokenRequest.client_secret == validClientSecret else {
            req.logger.warning("Invalid client credentials",
                             metadata: ["client_id": .string(tokenRequest.client_id)])
            throw Abort(.unauthorized)
        }
        
        let payload = AuthPayload(
            sub: SubjectClaim(value: "QuestService"),
            exp: ExpirationClaim(value: Date().addingTimeInterval(3600))
        )
        
        do {
            let token = try req.jwt.sign(payload)
            req.logger.info("JWT token generated", metadata: ["client_id": .string(tokenRequest.client_id)])
            return req.eventLoop.makeSucceededFuture(JWTTokenResponse(token: token))
        } catch {
            req.logger.error("Token generation failed", metadata: ["error": .string(error.localizedDescription)])
            throw Abort(.internalServerError)
        }
    }
} 
