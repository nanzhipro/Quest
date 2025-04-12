//
//  WaitlistController.swift
//  App
//
//  Created by CursorAI on 2024-05-12.
//

import Fluent
import Vapor

struct WaitlistController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let waitlist = routes.grouped("api", "v1", "waitlist")
        waitlist.post(use: create)
    }

    func create(req: Request) async throws -> HTTPStatus {
        try WaitlistEntryRequest.validate(content: req)
        let waitlistRequest = try req.content.decode(WaitlistEntryRequest.self)

        // 检查邮箱是否已存在
        if try await WaitlistEntry.query(on: req.db)
            .filter(\.$email == waitlistRequest.email)
            .first() != nil
        {
            return .ok  // 已存在也返回成功，避免暴露信息
        }

        let waitlistEntry = WaitlistEntry(email: waitlistRequest.email)
        try await waitlistEntry.save(on: req.db)
        return .ok
    }
}

// 请求验证
struct WaitlistEntryRequest: Content, Validatable {
    let email: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
    }
}
