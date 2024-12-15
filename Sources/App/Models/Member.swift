//
//  Member.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Fluent
import Vapor

final class Member: Model, Content, @unchecked Sendable, Authenticatable {
    static let schema = "members"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "phone_number")
    var phoneNumber: String?
    
    @Parent(key: "tier_id")
    var tier: MembershipTier
    
    @Field(key: "points")
    var points: Int
    
    @Field(key: "is_active")
    var isActive: Bool
    
    @Timestamp(key: "membership_start_date", on: .create)
    var membershipStartDate: Date?
    
    @Timestamp(key: "membership_end_date", on: .update)
    var membershipEndDate: Date?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil,
         username: String,
         email: String,
         passwordHash: String,
         phoneNumber: String? = nil,
         tierId: UUID,
         points: Int = 0,
         isActive: Bool = true,
         membershipEndDate: Date? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.phoneNumber = phoneNumber
        self.$tier.id = tierId
        self.points = points
        self.isActive = isActive
        self.membershipEndDate = membershipEndDate
    }
}

extension Member: ModelAuthenticatable {
    static let usernameKey = \Member.$email
    static let passwordHashKey = \Member.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension Member {
    func generateToken() throws -> String {
        // 在实际应用中，应该使用更安全的令牌生成方法
        // 这里仅作为示例
        guard let id = self.id else {
            throw Abort(.internalServerError, reason: "Member ID not found")
        }
        return id.uuidString
    }
} 