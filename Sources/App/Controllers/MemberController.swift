//
//  MemberController.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Fluent
import Vapor

struct MemberController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let members = routes.grouped("members")
        let protectedMembers = members.grouped(MemberAuthMiddleware())
        
        // 公开路由
        members.post("register", use: register)
        members.post("login", use: login)
        
        // 受保护路由
        protectedMembers.get(use: index)
        protectedMembers.get(":memberID", use: show)
        protectedMembers.put(":memberID", use: update)
        protectedMembers.delete(":memberID", use: delete)
        protectedMembers.post("renew", ":memberID", use: renewMembership)
        protectedMembers.post("points", ":memberID", use: updatePoints)
    }
    
    @Sendable
    func register(req: Request) async throws -> MemberResponse {
        let dto = try req.content.decode(CreateMemberDTO.self)
        
        // 验证邮箱是否已存在
        if try await Member.query(on: req.db)
            .filter(\.$email == dto.email)
            .first() != nil {
            throw Abort(.conflict, reason: "Email already exists")
        }
        
        // 验证会员等级是否存在
        guard let tier = try await MembershipTier.find(dto.tierId, on: req.db) else {
            throw Abort(.notFound, reason: "Membership tier not found")
        }
        
        let hashedPassword = try await req.password.async.hash(dto.password)
        
        let member = Member(
            username: dto.username,
            email: dto.email,
            passwordHash: hashedPassword,
            phoneNumber: dto.phoneNumber,
            tierId: dto.tierId
        )
        
        try await member.save(on: req.db)
        return MemberResponse(member: member, tierName: tier.name)
    }
    
    @Sendable
    func login(req: Request) async throws -> String {
        // 定义登录请求结构
        struct LoginRequest: Content {
            let email: String
            let password: String
        }
        
        // 解码登录请求
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        // 查找用户
        guard let member = try await Member.query(on: req.db)
            .filter(\.$email, .equal, loginRequest.email)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        
        // 验证密码
        guard try member.verify(password: loginRequest.password) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        
        // 检查会员状态
        guard member.isActive else {
            throw Abort(.forbidden, reason: "Account is inactive")
        }
        
        if let endDate = member.membershipEndDate, endDate < Date() {
            throw Abort(.forbidden, reason: "Membership has expired")
        }
        
        // 生成令牌
        let token = try member.generateToken()
        return token
    }
    
    @Sendable
    func index(req: Request) async throws -> [MemberResponse] {
        let members = try await Member.query(on: req.db)
            .with(\.$tier)
            .all()
        
        return members.map { member in
            MemberResponse(member: member, tierName: member.tier.name)
        }
    }
    
    @Sendable
    func show(req: Request) async throws -> MemberResponse {
        guard let memberID = req.parameters.get("memberID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid member ID")
        }
        
        guard let member = try await Member.query(on: req.db)
            .with(\.$tier)
            .filter(\.$id, .equal, memberID)
            .first() else {
            throw Abort(.notFound)
        }
        
        return MemberResponse(member: member, tierName: member.tier.name)
    }
    
    @Sendable
    func update(req: Request) async throws -> MemberResponse {
        let dto = try req.content.decode(UpdateMemberDTO.self)
        
        guard let memberID = req.parameters.get("memberID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid member ID")
        }
        
        guard let member = try await Member.query(on: req.db)
            .with(\.$tier)
            .filter(\.$id, .equal, memberID)
            .first() else {
            throw Abort(.notFound)
        }
        
        if let username = dto.username {
            member.username = username
        }
        if let email = dto.email {
            member.email = email
        }
        if let phoneNumber = dto.phoneNumber {
            member.phoneNumber = phoneNumber
        }
        if let tierId = dto.tierId {
            member.$tier.id = tierId
        }
        
        try await member.save(on: req.db)
        return MemberResponse(member: member, tierName: member.tier.name)
    }
    
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let memberID = req.parameters.get("memberID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid member ID")
        }
        
        guard let member = try await Member.find(memberID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await member.delete(on: req.db)
        return .noContent
    }
    
    @Sendable
    func renewMembership(req: Request) async throws -> MemberResponse {
        guard let memberID = req.parameters.get("memberID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid member ID")
        }
        
        guard let member = try await Member.query(on: req.db)
            .with(\.$tier)
            .filter(\.$id, .equal, memberID)
            .first() else {
            throw Abort(.notFound)
        }
        
        let newEndDate = Date().addingTimeInterval(TimeInterval(member.tier.durationMonths * 30 * 24 * 60 * 60))
        member.membershipEndDate = newEndDate
        member.isActive = true
        
        try await member.save(on: req.db)
        return MemberResponse(member: member, tierName: member.tier.name)
    }
    
    @Sendable
    func updatePoints(req: Request) async throws -> MemberResponse {
        struct PointsUpdate: Content {
            let points: Int
        }
        
        let pointsUpdate = try req.content.decode(PointsUpdate.self)
        
        guard let memberID = req.parameters.get("memberID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid member ID")
        }
        
        guard let member = try await Member.query(on: req.db)
            .with(\.$tier)
            .filter(\.$id, .equal, memberID)
            .first() else {
            throw Abort(.notFound)
        }
        
        member.points += pointsUpdate.points
        try await member.save(on: req.db)
        
        return MemberResponse(member: member, tierName: member.tier.name)
    }
} 