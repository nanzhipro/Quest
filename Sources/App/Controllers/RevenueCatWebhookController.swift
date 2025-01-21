import Vapor

struct RevenueCatWebhookController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let webhook = routes.grouped("revenuecat", "webhook")
        webhook.post(use: handleWebhook)
    }

    @Sendable
    func handleWebhook(req: Request) async throws -> HTTPStatus {
        // Verify RevenueCat signature
        guard let signature = req.headers["X-RevenueCat-Signature"].first else {
            throw Abort(.unauthorized, reason: "Missing RevenueCat signature")
        }

        // Verify the signature (this is a placeholder, implement actual verification)
        guard verifySignature(signature, for: req) else {
            throw Abort(.unauthorized, reason: "Invalid RevenueCat signature")
        }

        // Decode the webhook payload
        let payload = try req.content.decode(RevenueCatWebhookPayload.self)

        // Process the webhook data and update user subscription status
        try await processWebhookData(payload, on: req)

        return .ok
    }

    private func verifySignature(_ signature: String, for req: Request) -> Bool {
        // Implement actual signature verification logic here
        return true
    }

    private func processWebhookData(_ payload: RevenueCatWebhookPayload, on req: Request) async throws {
        // Find the member by RevenueCat user ID
        guard let member = try await Member.query(on: req.db)
            .filter(\.$revenueCatUserId == payload.userId)
            .first()
        else {
            throw Abort(.notFound, reason: "Member not found")
        }

        // Update the member's subscription status based on the webhook data
        member.updateSubscriptionStatus(with: payload)

        // Save the updated member
        try await member.save(on: req.db)
    }
}

struct RevenueCatWebhookPayload: Content {
    let userId: String
    let subscriptionStatus: String
    let expirationDate: Date?
}

extension Member {
    func updateSubscriptionStatus(with payload: RevenueCatWebhookPayload) {
        // Update the member's subscription status based on the webhook data
        self.isActive = (payload.subscriptionStatus == "active")
        self.membershipEndDate = payload.expirationDate
    }
}
