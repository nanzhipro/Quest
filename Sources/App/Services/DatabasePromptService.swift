//
//  DatabasePromptService.swift
//  Quest
//
//  Created by CursorAI on 2024-02-21.
//

import Vapor
import Fluent

final class DatabasePromptService: PromptService {
    let db: Database
    
    init(db: Database) {
        self.db = db
    }
    
    func getLatestPrompt() async throws -> Prompt {
        return try await Prompt.query(on: db)
            .sort(\.$version, .descending)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No prompts available"))
            .get()
    }
}

extension DatabasePromptService {
    static func `default`(for req: Request) -> DatabasePromptService {
        return DatabasePromptService(db: req.db)
    }
}