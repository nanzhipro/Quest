//
//  StressTest.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation
import AsyncHTTPClient
import NIOCore
import NIOPosix

/// 并发限制器
private actor ConcurrencyLimiter {
    private var available: Int
    
    init(value: Int) {
        self.available = value
    }
    
    func wait() async {
        while available <= 0 {
            try? await Task.sleep(for: .milliseconds(10))
        }
        available -= 1
    }
    
    func signal() {
        available += 1
    }
}

/// 压力测试结果
public struct StressTestResult {
    /// 总请求数
    public let totalRequests: Int
    /// 成功请求数
    public let successfulRequests: Int
    /// 失败请求数
    public let failedRequests: Int
    /// 平均响应时间（毫秒）
    public let averageResponseTime: Double
    /// 最小响应时间（毫秒）
    public let minResponseTime: Double
    /// 最大响应时间（毫秒）
    public let maxResponseTime: Double
    /// 95分位响应时间（毫秒）
    public let p95ResponseTime: Double
    /// 99分位响应时间（毫秒）
    public let p99ResponseTime: Double
    /// 错误详情
    public let errors: [(error: String, count: Int)]
}

/// 压力测试配置
public struct StressTestConfig {
    /// 并发请求数
    public let concurrentRequests: Int
    /// 总请求数
    public let totalRequests: Int
    /// 请求间隔（毫秒）
    public let requestInterval: Int
    /// 超时时间（秒）
    public let timeout: Int
    /// 音频文件路径
    public let audioFilePath: String
    /// 引擎类型
    public let engineType: String
    
    public init(
        concurrentRequests: Int = 10,
        totalRequests: Int = 100,
        requestInterval: Int = 100,
        timeout: Int = 30,
        audioFilePath: String,
        engineType: String = "16k_zh"
    ) {
        self.concurrentRequests = concurrentRequests
        self.totalRequests = totalRequests
        self.requestInterval = requestInterval
        self.timeout = timeout
        self.audioFilePath = audioFilePath
        self.engineType = engineType
    }
}

/// 压力测试工具
public class StressTest {
    private let client: TencentCloudAPIClient
    private let config: StressTestConfig
    
    public init(client: TencentCloudAPIClient, config: StressTestConfig) {
        self.client = client
        self.config = config
    }
    
    /// 执行压力测试
    /// - Returns: 测试结果
    public func run() async throws -> StressTestResult {
        var responseTimes: [Double] = []
        var errors: [String: Int] = [:]
        var successfulRequests = 0
        var failedRequests = 0
        
        // 创建任务组
        await withTaskGroup(of: (responseTime: Double?, error: String?).self) { group in
            // 创建请求队列
            let requestQueue = AsyncStream<Int> { continuation in
                for i in 0..<config.totalRequests {
                    continuation.yield(i)
                }
                continuation.finish()
            }
            
            // 创建并发限制器
            let limiter = ConcurrencyLimiter(value: config.concurrentRequests)
            
            // 处理请求队列
            for await _ in requestQueue {
                await limiter.wait()
                
                group.addTask {
                    let startTime = Date()
                    do {
                        // 创建请求
                        let request = try ASRService.createSentenceRecognitionRequestFromFile(
                            filePath: self.config.audioFilePath,
                            engineType: self.config.engineType,
                            options: [
                                "wordInfo": 1,
                                "filterDirty": 1,
                                "filterModal": 1,
                                "filterPunc": 1,
                                "convertNumMode": 1
                            ]
                        )
                        
                        _ = try await self.client.sendRequest(
                            action: "SentenceRecognition",
                            version: "2019-06-14",
                            request: request,
                            responseType: SentenceRecognitionResponse.self
                        )
                        
                        let responseTime = Date().timeIntervalSince(startTime) * 1000
                        await limiter.signal()
                        return (responseTime, nil)
                    } catch {
                        await limiter.signal()
                        return (nil, error.localizedDescription)
                    }
                }
                
                // 控制请求速率
                try? await Task.sleep(for: .milliseconds(config.requestInterval))
            }
            
            // 收集结果
            for await result in group {
                if let responseTime = result.responseTime {
                    responseTimes.append(responseTime)
                    successfulRequests += 1
                } else if let error = result.error {
                    errors[error, default: 0] += 1
                    failedRequests += 1
                }
            }
        }
        
        // 计算统计指标
        let sortedTimes = responseTimes.sorted()
        let p95Index = Int(Double(sortedTimes.count) * 0.95)
        let p99Index = Int(Double(sortedTimes.count) * 0.99)
        
        return StressTestResult(
            totalRequests: config.totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: failedRequests,
            averageResponseTime: responseTimes.reduce(0, +) / Double(responseTimes.count),
            minResponseTime: responseTimes.min() ?? 0,
            maxResponseTime: responseTimes.max() ?? 0,
            p95ResponseTime: sortedTimes[p95Index],
            p99ResponseTime: sortedTimes[p99Index],
            errors: errors.map { ($0.key, $0.value) }
        )
    }
    
    /// 打印测试报告
    /// - Parameter result: 测试结果
    public func printReport(_ result: StressTestResult) {
        print("""
        ====== 压力测试报告 ======
        音频文件: \(config.audioFilePath)
        引擎类型: \(config.engineType)
        总请求数: \(result.totalRequests)
        成功请求: \(result.successfulRequests)
        失败请求: \(result.failedRequests)
        成功率: \(String(format: "%.2f%%", Double(result.successfulRequests) / Double(result.totalRequests) * 100))
        
        响应时间统计（毫秒）:
        平均: \(String(format: "%.2f", result.averageResponseTime))
        最小: \(String(format: "%.2f", result.minResponseTime))
        最大: \(String(format: "%.2f", result.maxResponseTime))
        95分位: \(String(format: "%.2f", result.p95ResponseTime))
        99分位: \(String(format: "%.2f", result.p99ResponseTime))
        
        错误统计:
        \(result.errors.map { "- \($0.error): \($0.count)次" }.joined(separator: "\n"))
        ======================
        """)
    }
}

/// 示例用法
extension StressTest {
    public static func runExample() async throws {
        let config = TencentCloudAPIConfig(
            secretId: "your-secret-id",
            secretKey: "your-secret-key",
            region: "ap-guangzhou",
            endpoint: "asr.tencentcloudapi.com",
            requestTimeout: 30,
            autoRetry: true,
            maxRetries: 3
        )
        
        let client = TencentCloudAPIClient(config: config)
        let stressTest = StressTest(
            client: client,
            config: StressTestConfig(
                concurrentRequests: 10,
                totalRequests: 100,
                requestInterval: 100,
                timeout: 30,
                audioFilePath: "path/to/your/audio/file.wav"
            )
        )
        
        let result = try await stressTest.run()
        stressTest.printReport(result)
    }
} 