//
//  Prompt.swift
//  Quest
//
//  Created by CursorAI on 2024-02-21.
//

import Fluent
import Vapor

final class Prompt: Model, Content, @unchecked Sendable {
    static let schema = "prompts"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "content")
    var content: String
    
    @Field(key: "version")
    var version: Int
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, content: String, version: Int) {
        self.id = id
        self.content = content
        self.version = version
    }
} 