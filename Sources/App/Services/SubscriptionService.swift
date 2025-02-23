//
//  SubscriptionService.swift
//  App
//
//  Created by CursorAI on 2024-03-21.
//

import Vapor
import Fluent

struct SubscriptionService {
    let db: Database
    
    func handleSubscriptionEvent(_ event: RevenueCatWebhookEvent) async throws {
        let eventData = event.event
        
        // 将毫秒时间戳转换为 Date
        let purchasedAt = Date(timeIntervalSince1970: Double(eventData.purchased_at_ms ?? 0) / 1000)
        let expiresAt = eventData.expiration_at_ms.map { Date(timeIntervalSince1970: Double($0) / 1000) }
        
        // 查找现有订阅
        let existingSubscription = try await UserSubscription.query(on: db)
            .filter(\.$app_user_id == eventData.app_user_id)
            .filter(\.$product_id == eventData.product_id ?? "")
            .first()
        
        // 根据事件类型处理订阅
        switch eventData.type {
        case "INITIAL_PURCHASE", "NON_RENEWING_PURCHASE":
            // 创建新订阅
            if existingSubscription == nil {
                let subscription = UserSubscription(
                    app_user_id: eventData.app_user_id,
                    product_id: eventData.product_id ?? "",
                    entitlement_id: eventData.entitlement_id,
                    status: .active,
                    purchased_at: purchasedAt,
                    expires_at: expiresAt
                )
                try await subscription.create(on: db)
            }
            
        case "RENEWAL":
            // 更新现有订阅
            if let subscription = existingSubscription {
                subscription.status = .active
                subscription.expires_at = expiresAt
                subscription.cancellation_date = nil
                try await subscription.save(on: db)
            }
            
        case "CANCELLATION":
            // 标记订阅为已取消
            if let subscription = existingSubscription {
                subscription.status = .cancelled
                subscription.cancellation_date = Date()
                try await subscription.save(on: db)
            }
            
        case "UNCANCELLATION":
            // 恢复订阅
            if let subscription = existingSubscription {
                subscription.status = .active
                subscription.cancellation_date = nil
                try await subscription.save(on: db)
            }
            
        default:
            break
        }
    }
    
    // 获取用户的所有有效订阅
    func getActiveSubscriptions(for appUserId: String) async throws -> [UserSubscription] {
        try await UserSubscription.query(on: db)
            .filter(\.$app_user_id == appUserId)
            .filter(\.$status == .active)
            .all()
    }
    
    // 检查用户是否有特定权益的有效订阅
    func hasActiveEntitlement(_ entitlementId: String, for appUserId: String) async throws -> Bool {
        try await UserSubscription.query(on: db)
            .filter(\.$app_user_id == appUserId)
            .filter(\.$entitlement_id == entitlementId)
            .filter(\.$status == .active)
            .first() != nil
    }
} 