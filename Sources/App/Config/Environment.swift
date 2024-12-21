//
//  Environment.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor
import Logging

enum AppEnvironment {
    static let jwtSecret = ProcessInfo.processInfo.environment["JWT_SECRET"] ?? "your-256-bit-secret"
    
    enum LLM {
        static let secretId = ProcessInfo.processInfo.environment["TENCENT_SECRET_ID"] ?? ""
        static let secretKey = ProcessInfo.processInfo.environment["TENCENT_SECRET_KEY"] ?? ""
        static let region = ProcessInfo.processInfo.environment["TENCENT_REGION"] ?? "ap-beijing"
    }
}

extension Environment {
    static var logLevel: Logger.Level {
        guard let levelString = Environment.get("LOG_LEVEL")?.lowercased() else {
            return .info // 默认级别
        }
        
        switch levelString {
        case "trace": return .trace
        case "debug": return .debug
        case "info": return .info
        case "notice": return .notice
        case "warning": return .warning
        case "error": return .error
        case "critical": return .critical
        default: return .info
        }
    }
} 