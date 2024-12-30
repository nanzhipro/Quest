//
//  MembershipTier.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Fluent
import Vapor

final class MembershipTier: Model, Content, @unchecked Sendable {
  static let schema = "membership_tiers"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "name")
  var name: String

  @Field(key: "description")
  var description: String

  @Field(key: "price")
  var price: Double

  @Field(key: "duration_months")
  var durationMonths: Int

  @Field(key: "benefits")
  var benefits: [String]

  @Children(for: \.$tier)
  var members: [Member]

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    name: String,
    description: String,
    price: Double,
    durationMonths: Int,
    benefits: [String]
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.price = price
    self.durationMonths = durationMonths
    self.benefits = benefits
  }
}
