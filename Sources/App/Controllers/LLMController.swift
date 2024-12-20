//
//  LLMController.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

/// LLM API 请求 DTO
struct LLMRequestDTO: Content {
    /// 消息列表
    let messages: [LLMMessage]
    /// 模型名称
    let model: String
    /// 采样温度
    let temperature: Double?
    /// 是否使用流式响应
    let stream: Bool?
}

/// LLM API 响应 DTO
struct LLMResponseDTO: Content {
    /// 响应内容
    let content: String
    /// Token 使用统计
    let usage: LLMUsage
    /// 请求 ID
    let requestId: String
}

/// LLM API 控制器
struct LLMController {
    /// 创建路由
    func routes(_ app: Application) throws {
        let llm = app.grouped("api", "v1", "llm")
        
        // 聊天补全接口
        llm.post("chat") { req -> LLMResponseDTO in
            let requestDTO = try req.content.decode(LLMRequestDTO.self)
            
            // 获取 LLM 提供者
            let provider = try LLMConfiguration.shared.getProvider()
            
            // 构建请求配置
            let config = LLMConfig(
                model: requestDTO.model,
                temperature: requestDTO.temperature ?? 0.7,
                stream: requestDTO.stream ?? false
            )
            
            // 执行请求
            let request = LLMRequest(
                messages: requestDTO.messages,
                config: config
            )
            
            let response = try await provider.execute(request)
            
            // 转换为 DTO
            return LLMResponseDTO(
                content: response.content,
                usage: response.usage,
                requestId: response.requestId
            )
        }
        
        // 流式聊天补全接口
        llm.post("chat", "stream") { req async throws -> Response in
            let requestDTO = try req.content.decode(LLMRequestDTO.self)
            
            // 获取 LLM 提供者
            let provider = try LLMConfiguration.shared.getProvider()
            
            // 构建请求配置
            let config = LLMConfig(
                model: requestDTO.model,
                temperature: requestDTO.temperature ?? 0.7,
                stream: true
            )
            
            // 执行请求
            let request = LLMRequest(
                messages: requestDTO.messages,
                config: config
            )
            
            // 创建流式响应
            let response = Response(body: .init())
            response.headers.replaceOrAdd(
                name: .contentType,
                value: "text/event-stream; charset=utf-8"
            )
            
            let stream = try await provider.executeStream(request)
            
            // 写入响应流
            response.body = .init(stream: { writer in
                Task {
                    do {
                        for try await chunk in stream {
                            let buffer = ByteBuffer(string: "data: \(chunk)\n\n")
                            _ = writer.write(.buffer(buffer))
                        }
                        
                        let doneBuffer = ByteBuffer(string: "data: [DONE]\n\n")
                        _ = writer.write(.buffer(doneBuffer))
                    } catch {
                        _ = writer.write(.error(error))
                    }
                }
            })
            
            return response
        }
    }
} 