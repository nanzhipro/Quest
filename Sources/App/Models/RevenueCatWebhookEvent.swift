//
//  RevenueCatWebhookEvent.swift
//  App
//
//  Created by CursorAI on 2024-03-21.
//

import Vapor

struct RevenueCatWebhookEvent: Codable {
    let event: EventData
}

struct EventData: Codable {
    let id: String
    let type: String
    let app_user_id: String
    let product_id: String?
    let purchased_at_ms: Int64?
    let expiration_at_ms: Int64?
    let original_app_user_id: String?
    let entitlement_id: String?
    let presented_offering_id: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case app_user_id
        case product_id
        case purchased_at_ms
        case expiration_at_ms
        case original_app_user_id
        case entitlement_id
        case presented_offering_id
    }
} 