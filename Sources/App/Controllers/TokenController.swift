//
//  TokenController.swift
//  VaporProject
//
//  Created by CursorAI on 2023-10-04.
//

import Vapor
import JWT

// 用于解析客户端请求体中携带的凭据数据
struct TokenRequest: Content {
    let client_id: String
    let client_secret: String
}

// 用于返回生成的 JWT token
struct TokenResponse: Content {
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

// TokenController 实现了 RouteCollection，用于注册 /api/token 路由
struct TokenController: RouteCollection {
    // 硬编码的客户端凭据
    private let validClientId = "QuestService"
    private let validClientSecret = "QuestSecret"
    
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.post("token", use: tokenHandler)
    }
    
    // 处理 /api/token 请求的路由函数
    func tokenHandler(req: Request) throws -> EventLoopFuture<TokenResponse> {
        // 解码请求体中的客户端凭据
        let tokenRequest = try req.content.decode(TokenRequest.self)
        
        // 校验凭据是否正确
        guard tokenRequest.client_id == validClientId,
              tokenRequest.client_secret == validClientSecret else {
            throw Abort(.unauthorized, reason: "无效的客户端凭据")
        }
        
        // 设置 Token 的有效期（这里设定为 1 小时）
        let expirationTime = Date().addingTimeInterval(3600)
        // 构造统一的 AuthPayload，此处设置 sub 为 QuestService
        let payload = AuthPayload(sub: SubjectClaim(value: "QuestService"),
                                  exp: ExpirationClaim(value: expirationTime))
        do {
            // 使用全局配置的 JWT 签名器生成 token
            let token = try req.jwt.sign(payload)
            return req.eventLoop.makeSucceededFuture(TokenResponse(token: token))
        } catch {
            return req.eventLoop.makeFailedFuture(error)
        }
    }
} 