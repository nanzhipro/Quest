//
//  MemberAuthMiddleware.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Vapor

struct MemberAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let bearer = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Missing authentication token")
        }
        
        guard let tokenUUID = UUID(uuidString: bearer.token) else {
            throw Abort(.unauthorized, reason: "Invalid token format")
        }
        
        guard let member = try await Member.query(on: request.db)
            .filter(\.$id, .equal, tokenUUID)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid authentication token")
        }
        
        guard member.isActive else {
            throw Abort(.forbidden, reason: "Membership is inactive")
        }
        
        if let endDate = member.membershipEndDate, endDate < Date() {
            throw Abort(.forbidden, reason: "Membership has expired")
        }
        
        request.auth.login(member)
        return try await next.respond(to: request)
    }
} 