//
//  RevenueCatWebhook.swift
//  App
//
//  Created by CursorAI on 2024-03-21.
//

import Vapor
import Fluent

// Webhook 事件模型
struct RevenueCatWebhookEvent: Codable {
    let event: Event
    let api_version: String
    
    struct Event: Codable {
        let event_id: String
        let type: String
        let app_user_id: String
        let original_app_user_id: String
        let product_id: String?
        let entitlement_id: String?
        let purchased_at_ms: Int64?
        let expiration_at_ms: Int64?
    }
}

// 事件日志模型
final class EventLog: Model, Content {
    static let schema = "revenuecat_event_logs"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "event_id")
    var event_id: String
    
    @Field(key: "event_type")
    var event_type: String
    
    @Field(key: "app_user_id")
    var app_user_id: String
    
    @Field(key: "processed_at")
    var processed_at: Date
    
    init() { }
    
    init(id: UUID? = nil, event_id: String, event_type: String, app_user_id: String) {
        self.id = id
        self.event_id = event_id
        self.event_type = event_type
        self.app_user_id = app_user_id
        self.processed_at = Date()
    }
} 