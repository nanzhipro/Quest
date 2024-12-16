//
//  MemberAuthMiddleware.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Vapor

/// 会员认证中间件
/// 负责验证请求中的认证令牌，并确保会员状态有效
struct MemberAuthMiddleware: AsyncMiddleware {
    /// 处理入站请求
    /// - Parameters:
    ///   - request: HTTP 请求
    ///   - next: 下一个响应处理器
    /// - Returns: HTTP 响应
    /// - Throws: 认证失败时抛出相应的错误
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // 1. 验证认证头
        guard let bearer = request.headers.bearerAuthorization else {
            request.logger.warning("Missing authentication token")
            throw Abort(.unauthorized, reason: "Missing authentication token")
        }
        
        // 2. 验证令牌格式
        guard let tokenUUID = UUID(uuidString: bearer.token) else {
            request.logger.warning("Invalid token format: \(bearer.token)")
            throw Abort(.unauthorized, reason: "Invalid token format")
        }
        
        // 3. 查找并验证会员
        guard let member = try await Member.query(on: request.db)
            .filter(\.$id, .equal, tokenUUID)
            .first() else {
            request.logger.warning("Invalid authentication token: \(bearer.token)")
            throw Abort(.unauthorized, reason: "Invalid authentication token")
        }
        
        // 4. 检查会员状态
        guard member.isActive else {
            request.logger.notice("Inactive member attempted access: \(member.id?.uuidString ?? "unknown")")
            throw Abort(.forbidden, reason: "Membership is inactive")
        }
        
        // 5. 检查会员有效期
        if let endDate = member.membershipEndDate {
            if endDate < Date() {
                request.logger.notice("Expired membership attempted access: \(member.id?.uuidString ?? "unknown")")
                throw Abort(.forbidden, reason: "Membership has expired")
            }
        }
        
        // 6. 记录成功的认证
        request.logger.info("Successful authentication for member: \(member.id?.uuidString ?? "unknown")")
        
        // 7. 将会员信息存储在请求中
        request.auth.login(member)
        
        // 8. 添加会员ID到响应头（可选，用于调试）
        let response = try await next.respond(to: request)
        response.headers.add(name: "X-Member-ID", value: member.id?.uuidString ?? "unknown")
        
        return response
    }
}

// MARK: - 辅助扩展

private extension Request {
    /// 获取当前认证的会员
    var authenticatedMember: Member? {
        auth.get(Member.self)
    }
}

// MARK: - 常量

private enum Constants {
    /// 认证相关的错误消息
    enum ErrorMessage {
        static let missingToken = "Missing authentication token"
        static let invalidFormat = "Invalid token format"
        static let invalidToken = "Invalid authentication token"
        static let inactiveMember = "Membership is inactive"
        static let expiredMembership = "Membership has expired"
    }
    
    /// 响应头
    enum Header {
        static let memberID = "X-Member-ID"
    }
} 