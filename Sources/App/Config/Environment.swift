//
//  Environment.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

enum AppEnvironment {
    static let jwtSecret = ProcessInfo.processInfo.environment["JWT_SECRET"] ?? "your-256-bit-secret"
    
    enum LLM {
        static let secretId = ProcessInfo.processInfo.environment["TENCENT_SECRET_ID"] ?? ""
        static let secretKey = ProcessInfo.processInfo.environment["TENCENT_SECRET_KEY"] ?? ""
        static let region = ProcessInfo.processInfo.environment["TENCENT_REGION"] ?? "ap-beijing"
    }
} 