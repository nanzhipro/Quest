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
        // 1. 获取签名
        guard let signatureHeader = req.headers.first(name: "X-RevenueCat-Signature") else {
            req.logger.warning("Missing RevenueCat signature header")
            throw Abort(.unauthorized, reason: "Missing signature header")
        }
        
        guard let webhookSecret = Environment.get("REVENUECAT_WEBHOOK_SECRET") else {
            req.logger.error("RevenueCat webhook secret not configured")
            throw Abort(.internalServerError, reason: "Webhook secret not configured")
        }
        
        // 2. 获取原始请求体
        let rawBody = try await req.body.collect(max: 1024 * 1024).get()
        guard let bodyBuffer = rawBody else {
            throw Abort(.badRequest, reason: "Missing request body")
        }
        
        // 3. 获取原始请求体字符串，保持原始格式
        guard let rawBodyString = bodyBuffer.getString(at: 0, length: bodyBuffer.readableBytes) else {
            throw Abort(.badRequest, reason: "Invalid request body")
        }
        
        // 4. 计算签名
        let secretData = Data(webhookSecret.utf8)
        let messageData = Data(rawBodyString.utf8)
        
        #if canImport(CryptoKit)
        let hmac = HMAC<SHA256>.authenticationCode(for: messageData, using: SymmetricKey(data: secretData))
        let computedSignature = Data(hmac).map { String(format: "%02x", $0) }.joined()
        #else
        let hmac = HMAC<SHA256>.authenticationCode(for: messageData, using: SymmetricKey(data: secretData))
        let computedSignature = Data(hmac).map { String(format: "%02x", $0) }.joined()
        #endif
        
        // 5. 验证签名
        guard computedSignature == signatureHeader else {
            req.logger.warning("Invalid RevenueCat signature", metadata: [
                "computed": .string(computedSignature),
                "received": .string(signatureHeader)
            ])
            throw Abort(.unauthorized, reason: "Invalid signature")
        }
        
        // 6. 解析事件
        let event: RevenueCatWebhookEvent
        do {
            event = try JSONDecoder().decode(RevenueCatWebhookEvent.self, from: bodyBuffer)
        } catch {
            req.logger.error("Failed to decode webhook event: \(error)")
            throw Abort(.badRequest, reason: "Invalid webhook payload")
        }
        
        // 7. 处理事件
        do {
            try await handleEvent(event, on: req)
            req.logger.info("Successfully processed RevenueCat event: \(event.event.id)")
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