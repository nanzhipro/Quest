//
//  UpdatePromptCommand.swift
//  Quest
//
//  Created by CursorAI on 2024-06-21.
//

import Fluent
import Vapor

struct UpdatePromptCommand: AsyncCommand {
    struct Signature: CommandSignature {
        @Option(name: "content", short: "c")
        var content: String?

        @Option(name: "file", short: "f")
        var filePath: String?

        @Option(name: "version", short: "v")
        var version: Int?
    }

    var help: String {
        "更新系统中的提示内容 (使用方法: update-prompt --content=\"新内容\" 或 update-prompt --file=./path/to/file.md)"
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        let app = context.application

        // 获取新内容（从参数或文件）
        let newContent: String
        if let content = signature.content, !content.isEmpty {
            newContent = content
        } else if let filePath = signature.filePath {
            do {
                newContent = try String(contentsOfFile: filePath, encoding: .utf8)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                context.console.error("无法读取文件: \(error.localizedDescription)")
                throw error
            }
        } else {
            context.console.error("必须提供 --content 或 --file 参数")
            throw Abort(.badRequest, reason: "必须提供 --content 或 --file 参数")
        }

        // 查找并更新第一个提示
        guard let prompt = try await Prompt.query(on: app.db).first() else {
            context.console.error("没有找到提示数据")
            throw Abort(.notFound, reason: "没有找到提示数据")
        }

        prompt.content = newContent
        if let version = signature.version {
            prompt.version = version
        } else {
            prompt.version += 1
        }

        try await prompt.save(on: app.db)
        context.console.success("提示已更新为版本 \(prompt.version)")
    }
}
