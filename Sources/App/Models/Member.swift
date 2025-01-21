import Fluent
import JWT
import Vapor

// MARK: - JWT Payload
struct MemberJWTPayload: JWTPayload {
  // JWT 标准声明
  let sub: SubjectClaim  // 主题（会员ID）
  let exp: ExpirationClaim  // 过期时间
  let iat: IssuedAtClaim  // 签发时间

  // 自定义声明
  let email: String
  let username: String
  let isActive: Bool
  let membershipEndDate: Date?

  init(member: Member) throws {
    guard let id = member.id else {
      throw Abort(.internalServerError, reason: "Member ID not found")
    }

    self.sub = SubjectClaim(value: id.uuidString)
    self.exp = ExpirationClaim(value: Date().addingTimeInterval(Constants.tokenLifetime))
    self.iat = IssuedAtClaim(value: Date())

    self.email = member.email
    self.username = member.username
    self.isActive = member.isActive
    self.membershipEndDate = member.membershipEndDate
  }

  func verify(using signer: JWTSigner) throws {
    try exp.verifyNotExpired()
  }
}

// MARK: - Member Model
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

  @Field(key: "revenue_cat_user_id")
  var revenueCatUserId: String?

  init() {}

  init(
    id: UUID? = nil,
    username: String,
    email: String,
    passwordHash: String,
    phoneNumber: String? = nil,
    tierId: UUID,
    points: Int = 0,
    isActive: Bool = true,
    membershipEndDate: Date? = nil,
    revenueCatUserId: String? = nil
  ) {
    self.id = id
    self.username = username
    self.email = email
    self.passwordHash = passwordHash
    self.phoneNumber = phoneNumber
    self.$tier.id = tierId
    self.points = points
    self.isActive = isActive
    self.membershipEndDate = membershipEndDate
    self.revenueCatUserId = revenueCatUserId
  }

  // MARK: - Token Generation
  func generateToken(_ app: Application) throws -> String {
    // 创建 JWT payload
    let payload = try MemberJWTPayload(member: self)

    // 使用应用程序的 JWT 签名器签名令牌
    return try app.jwt.signers.sign(payload)
  }

  // MARK: - Token Refresh
  func refreshToken(_ app: Application, currentToken: String) throws -> String {
    // 验证当前令牌
    let _ = try app.jwt.signers.verify(currentToken, as: MemberJWTPayload.self)

    // 生成新令牌
    return try generateToken(app)
  }

  // MARK: - Token Verification
  static func verify(_ token: String, using app: Application) async throws -> Member {
    // 验证令牌并解码 payload
    let payload = try app.jwt.signers.verify(token, as: MemberJWTPayload.self)

    // 从数据库获取会员信息
    guard let id = UUID(uuidString: payload.sub.value),
      let member = try await Member.find(id, on: app.db)
    else {
      throw Abort(.unauthorized, reason: "Invalid token")
    }

    // 验证会员状态
    guard member.isActive else {
      throw Abort(.forbidden, reason: "Member is inactive")
    }

    // 验证会员有效期
    if let endDate = member.membershipEndDate, endDate < Date() {
      throw Abort(.forbidden, reason: "Membership has expired")
    }

    return member
  }

  // MARK: - Update Subscription Status
  func updateSubscriptionStatus(with payload: RevenueCatWebhookPayload) {
    self.isActive = (payload.subscriptionStatus == "active")
    self.membershipEndDate = payload.expirationDate
  }
}

// MARK: - Constants
private enum Constants {
  /// 令牌有效期（24小时）
  static let tokenLifetime: TimeInterval = 24 * 60 * 60

  /// 刷新令牌的最小剩余有效期（1小时）
  static let minimumRemainingLifetime: TimeInterval = 60 * 60
}

// MARK: - Error Types
enum TokenError: Error {
  case invalidToken
  case expiredToken
  case inactiveMember
  case expiredMembership
}

extension Member: ModelAuthenticatable {
  static let usernameKey = \Member.$email
  static let passwordHashKey = \Member.$passwordHash

  func verify(password: String) throws -> Bool {
    try Bcrypt.verify(password, created: self.passwordHash)
  }
}
