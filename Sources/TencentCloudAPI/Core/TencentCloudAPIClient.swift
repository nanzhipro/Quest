//
//  TencentCloudAPIClient.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation
import AsyncAlgorithms

/// 腾讯云API客户端
public class TencentCloudAPIClient {
    /// API配置
    public let config: TencentCloudAPIConfig
    /// 签名生成器
    private let signatureGenerator: TC3SignatureGenerator
    /// URL会话
    private let urlSession: URLSession
    /// JSON编码器
    private let jsonEncoder: JSONEncoder
    /// JSON解码器
    private let jsonDecoder: JSONDecoder
    
    /// 初始化腾讯云API客户端
    /// - Parameter config: API配置
    public init(config: TencentCloudAPIConfig) {
        self.config = config
        self.signatureGenerator = TC3SignatureGenerator(
            secretId: config.secretId,
            secretKey: config.secretKey
        )
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.requestTimeout
        sessionConfig.timeoutIntervalForResource = config.requestTimeout
        self.urlSession = URLSession(configuration: sessionConfig)
        
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
    }
    
    /// 发送API请求
    /// - Parameters:
    ///   - action: API操作名称
    ///   - version: API版本
    ///   - request: 请求参数
    ///   - responseType: 响应类型
    /// - Returns: API响应
    public func sendRequest<T: Encodable, R: Decodable>(
        action: String,
        version: String,
        request: T,
        responseType: R.Type
    ) async throws -> R {
        let host = config.endpoint
        let url = URL(string: "https://\(host)")!
        
        // 生成请求体JSON
        let requestData = try jsonEncoder.encode(request)
        let requestBody = String(data: requestData, encoding: .utf8)!
        
        // 创建HTTP请求
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        
        // 设置公共头部
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(host, forHTTPHeaderField: "Host")
        urlRequest.setValue(action, forHTTPHeaderField: "X-TC-Action")
        urlRequest.setValue(version, forHTTPHeaderField: "X-TC-Version")
        urlRequest.setValue(config.region, forHTTPHeaderField: "X-TC-Region")
        
        // 生成时间戳
        let timestamp = Int(Date().timeIntervalSince1970)
        urlRequest.setValue("\(timestamp)", forHTTPHeaderField: "X-TC-Timestamp")
        
        // 构建规范头部字符串
        let canonicalHeaders = """
        content-type:application/json; charset=utf-8
        host:\(host)
        x-tc-action:\(action.lowercased())
        
        """
        
        // 构建签名信息
        let requestInfo = TC3RequestInfo(
            httpMethod: "POST",
            canonicalURI: "/",
            canonicalQueryString: "",
            canonicalHeaders: canonicalHeaders,
            signedHeaders: "content-type;host;x-tc-action",
            requestPayload: requestBody
        )
        
        // 生成授权头部
        let authorizationHeader = try signatureGenerator.generateAuthorizationHeader(
            service: host.split(separator: ".").first.map(String.init) ?? "asr",
            timestamp: timestamp,
            requestInfo: requestInfo
        )
        
        // 设置授权头部
        urlRequest.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        
        // 发送请求
        let (data, response) = try await executeRequest(urlRequest: urlRequest)
        
        // 验证HTTP响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TencentCloudAPIError.requestFailed(message: "无效的HTTP响应")
        }
        
        // 检查HTTP状态码
        guard (200...299).contains(httpResponse.statusCode) else {
            // 尝试解析错误响应
            do {
                let errorResponse = try jsonDecoder.decode(TencentCloudAPIErrorResponse.self, from: data)
                throw TencentCloudAPIError.serviceError(
                    code: errorResponse.error.code,
                    message: errorResponse.error.message
                )
            } catch {
                if let error = error as? TencentCloudAPIError {
                    throw error
                }
                
                throw TencentCloudAPIError.responseParsingFailed(
                    message: "HTTP状态码: \(httpResponse.statusCode), 无法解析错误响应: \(String(data: data, encoding: .utf8) ?? "")"
                )
            }
        }
        
        // 解析响应数据
        do {
            // 先尝试解析包装器响应
            let wrapperResponse = try jsonDecoder.decode(TencentCloudAPIResponse<R>.self, from: data)
            return wrapperResponse.response
        } catch {
            // 如果解析包装器失败，尝试直接解析响应
            return try jsonDecoder.decode(R.self, from: data)
        }
    }
    
    /// 执行HTTP请求，支持自动重试
    /// - Parameter urlRequest: URL请求
    /// - Returns: 响应数据和响应对象
    private func executeRequest(urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        if !config.autoRetry {
            // 不启用自动重试，直接发送请求
            return try await urlSession.data(for: urlRequest)
        }
        
        // 启用自动重试
        var lastError: Error?
        var retryCount = 0
        
        // 重试策略：指数退避
        let retryDelays = [0.5, 1.0, 2.0, 4.0, 8.0]
        
        while retryCount <= config.maxRetries {
            do {
                return try await urlSession.data(for: urlRequest)
            } catch {
                lastError = error
                retryCount += 1
                
                // 如果达到最大重试次数，抛出最后一个错误
                if retryCount > config.maxRetries {
                    throw TencentCloudAPIError.requestFailed(message: "请求失败，已重试\(retryCount - 1)次: \(error.localizedDescription)")
                }
                
                // 等待一段时间后重试
                let delay = retryCount - 1 < retryDelays.count ? retryDelays[retryCount - 1] : retryDelays.last!
                try await Task.sleep(for: .seconds(delay))
            }
        }
        
        // 不应该到达这里，但为了代码安全性
        throw lastError ?? TencentCloudAPIError.unknown(message: "未知错误")
    }
} 