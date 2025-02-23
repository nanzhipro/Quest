//
//  RevenueCatWebhookController.swift
//  App
//
//  Created by CursorAI on 2024-03-21.
//

import Vapor
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif
import Foundation

struct RevenueCatWebhookController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // 创建不需要 JWT 认证的路由组
        let webhooks = routes.grouped("webhooks", "revenuecat")
        webhooks.post(use: handleWebhook)
    }
    
    func handleWebhook(req: Request) async throws -> HTTPStatus {
        // 1. 获取并验证签名
        guard let signatureHeader = req.headers.first(name: "x-revenuecat-signature") else {
            req.logger.warning("Missing RevenueCat signature header")
            throw Abort(.unauthorized)
        }
        
        guard let webhookSecret = Environment.get("REVENUECAT_WEBHOOK_SECRET") else {
            req.logger.error("RevenueCat webhook secret not configured")
            throw Abort(.internalServerError)
        }
        
        // 2. 获取原始请求体
        let body = try await req.body.collect(max: 1024 * 1024).get() // 1MB limit
        guard var bodyBuffer = body else {
            throw Abort(.badRequest, reason: "Missing request body")
        }
        
        let bodyString = bodyBuffer.readString(length: bodyBuffer.readableBytes) ?? ""
        
        // 3. 验证签名
        let secretData = Data(webhookSecret.utf8)
        let messageData = Data(bodyString.utf8)
        
        #if canImport(CryptoKit)
        let hmac = HMAC<SHA256>.authenticationCode(for: messageData, using: SymmetricKey(data: secretData))
        let computedSignature = hmac.map { String(format: "%02x", $0) }.joined()
        #else
        let hmac = HMAC<SHA256>.authenticationCode(for: messageData, using: SymmetricKey(data: secretData))
        let computedSignature = hmac.map { String(format: "%02x", $0) }.joined()
        #endif
        
        guard computedSignature == signatureHeader else {
            req.logger.warning("Invalid RevenueCat signature")
            throw Abort(.unauthorized)
        }
        
        // 4. 解析事件
        bodyBuffer.moveReaderIndex(to: 0)
        let event = try JSONDecoder().decode(RevenueCatWebhookEvent.self, from: bodyBuffer)
        
        // 5. 检查是否已处理过该事件
        if try await EventLog.query(on: req.db)
            .filter(\.$event_id, .equal, event.event.event_id)
            .first() != nil {
            req.logger.info("Event already processed: \(event.event.event_id)")
            return .ok
        }
        
        // 6. 处理事件
        do {
            try await handleEvent(event, on: req)
            
            // 7. 记录事件
            let eventLog = EventLog(
                event_id: event.event.event_id,
                event_type: event.event.type,
                app_user_id: event.event.app_user_id
            )
            try await eventLog.create(on: req.db)
            
            req.logger.info("Successfully processed RevenueCat event: \(event.event.event_id)")
            return .ok
            
        } catch {
            req.logger.error("Failed to process RevenueCat event: \(error)")
            throw Abort(.internalServerError)
        }
    }
    
    private func handleEvent(_ event: RevenueCatWebhookEvent, on req: Request) async throws {
        let subscriptionService = SubscriptionService(db: req.db)
        try await subscriptionService.handleSubscriptionEvent(event)
        
        // 根据事件类型记录日志
        req.logger.info("Processed subscription event",
                       metadata: [
                           "event_type": .string(event.event.type),
                           "app_user_id": .string(event.event.app_user_id),
                           "product_id": .string(event.event.product_id ?? "unknown")
                       ])
    }
} 