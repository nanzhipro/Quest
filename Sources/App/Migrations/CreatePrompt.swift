//
//  CreatePrompt.swift
//  Quest
//
//  Created by CursorAI on 2024-02-21.
//

import Fluent
import Foundation
import Vapor

// # 确保文件存在
// docker compose run --rm app ls -l /app/Resources/Prompts/default.txt

// # 如果需要修改 Prompt
// docker compose down
// nano Resources/Prompts/default.txt
// docker compose up -d
// docker compose run migrate

struct CreatePrompt: AsyncMigration {
    func prepare(on database: Database) async throws {
        // 创建表结构
        try await database.schema("prompts")
            .id()
            .field("content", .string, .required)
            .field("version", .int, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()

        // 读取默认 Prompt 内容
        let promptPath = Environment.get("DEFAULT_PROMPT_PATH") ?? "./Resources/Prompts/default.txt"
        let version = Int(Environment.get("DEFAULT_PROMPT_VERSION") ?? "1") ?? 1
        
        do {
            let content = try String(contentsOfFile: promptPath, encoding: .utf8)
            
            let defaultPrompt = Prompt(
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                version: version
            )
            
            try await defaultPrompt.create(on: database)
            
        } catch {
            database.logger.error("Failed to load default prompt from \(promptPath): \(error)")
            
            // 使用硬编码的备用 Prompt
            let fallbackPrompt = Prompt(
                content: "你是一个智能助手。请简洁专业地回答问题。",
                version: version
            )
            try await fallbackPrompt.create(on: database)
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema("prompts").delete()
    }
} 