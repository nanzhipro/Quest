//
//  MemberDTO.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Vapor

struct CreateMemberDTO: Content {
    let username: String
    let email: String
    let password: String
    let phoneNumber: String?
    let tierId: UUID
}

struct UpdateMemberDTO: Content {
    let username: String?
    let email: String?
    let phoneNumber: String?
    let tierId: UUID?
}

struct MemberResponse: Content {
    let id: UUID?
    let username: String
    let email: String
    let phoneNumber: String?
    let tierName: String
    let points: Int
    let isActive: Bool
    let membershipEndDate: Date?
    
    init(member: Member, tierName: String) {
        self.id = member.id
        self.username = member.username
        self.email = member.email
        self.phoneNumber = member.phoneNumber
        self.tierName = tierName
        self.points = member.points
        self.isActive = member.isActive
        self.membershipEndDate = member.membershipEndDate
    }
} 