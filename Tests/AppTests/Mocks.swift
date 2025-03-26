//
//  Mocks.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation
import Fluent
import Vapor

// 临时模拟类型，用于让测试通过编译
final class Todo: Model, Content {
    static let schema = "todos"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    init() { }
    
    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
    
    func toDTO() -> TodoDTO {
        return TodoDTO(id: id, title: title)
    }
}

struct TodoDTO: Content {
    var id: UUID?
    var title: String
}

extension Todo {
    static func find(_ id: UUID?, on db: Database) async throws -> Todo? {
        return nil
    }
}

extension TodoDTO: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

extension Sequence where Element == Todo {
    func create(on database: Database) async throws {
        // 模拟方法，不做任何实际操作
    }
} 