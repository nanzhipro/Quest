//
//  MemberTests.swift
//  AppTests
//
//  Created by CursorAI on 2024-03-20.
//

@testable import App
import XCTVapor

final class MemberTests: XCTestCase {
    var app: Application!
    var testTier: MembershipTier!
    
    override func setUpWithError() throws {
        app = try Application(.testing)
        try configure(app)
        
        // 创建测试会员等级
        testTier = try createTestMembershipTier()
    }
    
    override func tearDownWithError() throws {
        try app.migrator.revertAll()
        app.shutdown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestMembershipTier() throws -> MembershipTier {
        let tier = MembershipTier(
            name: "Test Tier",
            description: "Test Description",
            price: 99.99,
            durationMonths: 12,
            benefits: ["Benefit 1", "Benefit 2"]
        )
        try tier.create(on: app.db).wait()
        return tier
    }
    
    private func createTestMember() throws -> Member {
        let member = Member(
            username: "testuser",
            email: "test@example.com",
            passwordHash: try app.password.hash("password123"),
            phoneNumber: "1234567890",
            tierId: testTier.id!
        )
        try member.create(on: app.db).wait()
        return member
    }
    
    // MARK: - Tests
    
    func testRegisterMember() throws {
        // 准备测试数据
        let registerData = CreateMemberDTO(
            username: "newuser",
            email: "new@example.com",
            password: "password123",
            phoneNumber: "1234567890",
            tierId: testTier.id!
        )
        
        try app.test(.POST, "members/register", beforeRequest: { req in
            try req.content.encode(registerData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let response = try res.content.decode(MemberResponse.self)
            XCTAssertEqual(response.username, registerData.username)
            XCTAssertEqual(response.email, registerData.email)
            XCTAssertEqual(response.phoneNumber, registerData.phoneNumber)
            XCTAssertEqual(response.tierName, testTier.name)
        })
    }
    
    func testRegisterMemberWithDuplicateEmail() throws {
        // 先创建一个会员
        _ = try createTestMember()
        
        // 尝试使用相同的邮箱注册
        let registerData = CreateMemberDTO(
            username: "newuser",
            email: "test@example.com", // 使用相同的邮箱
            password: "password123",
            phoneNumber: "1234567890",
            tierId: testTier.id!
        )
        
        try app.test(.POST, "members/register", beforeRequest: { req in
            try req.content.encode(registerData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        })
    }
    
    func testGetMember() throws {
        let member = try createTestMember()
        
        // 模拟认证令牌
        let token = member.id?.uuidString ?? ""
        
        try app.test(.GET, "members/\(member.id!)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: token)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let response = try res.content.decode(MemberResponse.self)
            XCTAssertEqual(response.username, member.username)
            XCTAssertEqual(response.email, member.email)
        })
    }
    
    func testUpdateMember() throws {
        let member = try createTestMember()
        
        let updateData = UpdateMemberDTO(
            username: "updateduser",
            email: "updated@example.com",
            phoneNumber: "9876543210",
            tierId: nil
        )
        
        try app.test(.PUT, "members/\(member.id!)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: member.id!.uuidString)
            try req.content.encode(updateData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let response = try res.content.decode(MemberResponse.self)
            XCTAssertEqual(response.username, updateData.username)
            XCTAssertEqual(response.email, updateData.email)
            XCTAssertEqual(response.phoneNumber, updateData.phoneNumber)
        })
    }
    
    func testDeleteMember() throws {
        let member = try createTestMember()
        
        try app.test(.DELETE, "members/\(member.id!)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: member.id!.uuidString)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
            
            // 验证会员已被删除
            let deletedMember = try? Member.find(member.id!, on: app.db).wait()
            XCTAssertNil(deletedMember)
        })
    }
    
    func testRenewMembership() throws {
        let member = try createTestMember()
        
        try app.test(.POST, "members/renew/\(member.id!)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: member.id!.uuidString)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let response = try res.content.decode(MemberResponse.self)
            XCTAssertTrue(response.isActive)
            XCTAssertNotNil(response.membershipEndDate)
        })
    }
    
    func testUpdatePoints() throws {
        let member = try createTestMember()
        
        let pointsUpdate = ["points": 100]
        
        try app.test(.POST, "members/points/\(member.id!)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: member.id!.uuidString)
            try req.content.encode(pointsUpdate)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let response = try res.content.decode(MemberResponse.self)
            XCTAssertEqual(response.points, member.points + pointsUpdate["points"]!)
        })
    }
    
    func testUnauthorizedAccess() throws {
        try app.test(.GET, "members", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testInvalidMembershipTier() throws {
        let registerData = CreateMemberDTO(
            username: "newuser",
            email: "new@example.com",
            password: "password123",
            phoneNumber: "1234567890",
            tierId: UUID() // 使用一个不存在的会员等级ID
        )
        
        try app.test(.POST, "members/register", beforeRequest: { req in
            try req.content.encode(registerData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
} 