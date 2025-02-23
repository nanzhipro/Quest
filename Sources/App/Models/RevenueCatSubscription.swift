//
//  RevenueCatSubscription.swift
//  App
//
//  Created by CursorAI on 2024-03-21.
//

import Fluent
import Vapor

// 订阅状态枚举
enum SubscriptionStatus: String, Codable {
    case active
    case cancelled
    case expired
    case inGracePeriod
    case paused
}

// 用户订阅模型
final class UserSubscription: Model, Content, Sendable {
    static let schema = "user_subscriptions"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "app_user_id")
    private(set) var app_user_id: String
    
    @Field(key: "product_id")
    var product_id: String
    
    @Field(key: "entitlement_id")
    var entitlement_id: String?
    
    @Field(key: "status")
    var status: SubscriptionStatus
    
    @Field(key: "purchased_at")
    var purchased_at: Date
    
    @Field(key: "expires_at")
    var expires_at: Date?
    
    @Field(key: "cancellation_date")
    var cancellation_date: Date?
    
    @Field(key: "original_transaction_id")
    var original_transaction_id: String?
    
    @Field(key: "is_sandbox")
    var is_sandbox: Bool
    
    @Field(key: "metadata")
    var metadata: [String: String]
    
    @Timestamp(key: "created_at", on: .create)
    var created_at: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updated_at: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        app_user_id: String,
        product_id: String,
        entitlement_id: String? = nil,
        status: SubscriptionStatus,
        purchased_at: Date,
        expires_at: Date? = nil,
        cancellation_date: Date? = nil,
        original_transaction_id: String? = nil,
        is_sandbox: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.app_user_id = app_user_id
        self.product_id = product_id
        self.entitlement_id = entitlement_id
        self.status = status
        self.purchased_at = purchased_at
        self.expires_at = expires_at
        self.cancellation_date = cancellation_date
        self.original_transaction_id = original_transaction_id
        self.is_sandbox = is_sandbox
        self.metadata = metadata
    }
}

// 订阅服务扩展
extension UserSubscription {
    // 检查订阅是否有效
    var isActive: Bool {
        guard status == .active else { return false }
        if let expiresAt = expires_at {
            return expiresAt > Date()
        }
        return true
    }
    
    // 检查是否在宽限期
    var isInGracePeriod: Bool {
        status == .inGracePeriod
    }
    
    // 获取剩余天数
    var remainingDays: Int? {
        guard let expiresAt = expires_at else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day
    }
    
    // 更新订阅状态
    func updateStatus() {
        guard let expiresAt = expires_at else { return }
        
        let now = Date()
        if now > expiresAt {
            status = .expired
        } else if cancellation_date != nil {
            status = .cancelled
        } else {
            status = .active
        }
    }
} 