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
        let logger = req.logger
        logger.info("Processing JWT token request", metadata: [
            "request_id": .string(req.id ?? "unknown"),
            "client_ip": .string(req.remoteAddress?.hostname ?? "unknown")
        ])
        
        // 解码请求体中的客户端凭据
        let tokenRequest = try req.content.decode(JWTTokenRequest.self)
        
        // 校验凭据是否正确
        guard tokenRequest.client_id == validClientId,
              tokenRequest.client_secret == validClientSecret else {
            logger.warning("Invalid client credentials attempt", metadata: [
                "request_id": .string(req.id ?? "unknown"),
                "client_id": .string(tokenRequest.client_id),
                "client_ip": .string(req.remoteAddress?.hostname ?? "unknown")
            ])
            throw Abort(.unauthorized, reason: "无效的客户端凭据")
        }
        
        logger.debug("Client credentials validated successfully", metadata: [
            "request_id": .string(req.id ?? "unknown"),
            "client_id": .string(tokenRequest.client_id)
        ])
        
        // 设置 Token 的有效期（这里设定为 1 小时）
        let expirationTime = Date().addingTimeInterval(3600)
        // 构造统一的 AuthPayload，此处设置 sub 为 QuestService
        let payload = AuthPayload(sub: SubjectClaim(value: "QuestService"),
                                exp: ExpirationClaim(value: expirationTime))
        do {
            // 使用全局配置的 JWT 签名器生成 token
            let token = try req.jwt.sign(payload)
            
            logger.info("JWT token generated successfully", metadata: [
                "request_id": .string(req.id ?? "unknown"),
                "client_id": .string(tokenRequest.client_id),
                "expiration": .string("\(expirationTime.timeIntervalSince1970)"),
                "token_length": .string("\(token.count)")
            ])
            
            return req.eventLoop.makeSucceededFuture(JWTTokenResponse(token: token))
        } catch {
            logger.error("Failed to generate JWT token", metadata: [
                "request_id": .string(req.id ?? "unknown"),
                "client_id": .string(tokenRequest.client_id),
                "error": .string(error.localizedDescription)
            ])
            return req.eventLoop.makeFailedFuture(error)
        }
    }
} 
