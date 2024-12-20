//
//  APIEndpoint.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation

/// API 端点协议
/// 定义了 API 端点的基本属性和行为
public protocol APIEndpoint {
    /// 端点路径
    var path: String { get }
    
    /// HTTP 方法
    var method: HTTPMethod { get }
    
    /// HTTP 头部
    var headers: [String: String]? { get }
    
    /// 请求体
    var body: Encodable? { get }
} 