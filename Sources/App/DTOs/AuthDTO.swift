//
//  AuthDTO.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Vapor

/// 登录请求 DTO
struct LoginRequest: Content {
    let email: String
    let password: String
}

/// 登录响应 DTO
struct LoginResponse: Content {
    let token: String
    let member: MemberResponse
}

/// 令牌刷新请求 DTO
struct RefreshTokenRequest: Content {
    let token: String
}

/// 令牌刷新响应 DTO
struct RefreshTokenResponse: Content {
    let token: String
} 