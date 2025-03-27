//
//  StressTest.swift
//  StressTestCLI
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation
import AsyncHTTPClient
import NIOCore
import NIOPosix
import TencentCloudAPI

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
    /// 识别结果 (仅保存最后一次结果作为示例)
    public let recognitionResult: String?
    /// 词频统计（出现次数超过1次的词）
    public let wordFrequency: [(word: String, count: Int)]
    /// 音频时长（毫秒）
    public let audioDuration: Int?
    /// 识别结果一致性（相同结果的百分比）
    public let resultConsistency: Double
    /// 所有不同的识别结果
    public let uniqueResults: [(result: String, count: Int)]
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
        // 验证音频文件是否存在并可读
        guard FileManager.default.fileExists(atPath: config.audioFilePath) else {
            throw TencentCloudAPIError.requestFailed(message: "音频文件不存在：\(config.audioFilePath)")
        }
        
        var responseTimes: [Double] = []
        var errors: [String: Int] = [:]
        var successfulRequests = 0
        var failedRequests = 0
        var lastRecognitionResult: String? = nil
        var audioDuration: Int? = nil
        
        // 词频统计
        let wordCounter = WordCounter()
        
        // 结果一致性统计
        var resultCounter: [String: Int] = [:]
        
        print("使用音频文件: \(config.audioFilePath)")
        print("引擎类型: \(config.engineType)")
        print("并发数: \(config.concurrentRequests)")
        print("总请求数: \(config.totalRequests)")
        
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
            for await requestIndex in requestQueue {
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
                        
                        let response = try await self.client.sendRequest(
                            action: "SentenceRecognition",
                            version: "2019-06-14",
                            request: request,
                            responseType: SentenceRecognitionResponse.self
                        )
                        
                        let responseTime = Date().timeIntervalSince(startTime) * 1000
                        await limiter.signal()
                        print("请求 \(requestIndex+1)/\(self.config.totalRequests) 成功，响应时间: \(String(format: "%.2f", responseTime))ms")
                        print("识别结果: \(response.result)")
                        
                        // 在主线程外更新共享变量
                        Task.detached {
                            lastRecognitionResult = response.result
                            // 统计词频
                            wordCounter.addText(response.result)
                            
                            // 记录音频时长
                            audioDuration = response.audioDuration
                            
                            // 统计结果一致性
                            resultCounter[response.result, default: 0] += 1
                        }
                        
                        return (responseTime, nil)
                    } catch {
                        await limiter.signal()
                        print("请求 \(requestIndex+1)/\(self.config.totalRequests) 失败: \(error.localizedDescription)")
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
        let p95Index = min(Int(Double(sortedTimes.count) * 0.95), max(0, sortedTimes.count - 1))
        let p99Index = min(Int(Double(sortedTimes.count) * 0.99), max(0, sortedTimes.count - 1))
        
        // 获取词频统计
        let wordFrequency = wordCounter.getFrequency()
            .filter { $0.count > 1 } // 只保留出现超过1次的词
            .sorted { $0.count > $1.count } // 按出现次数排序
        
        // 计算结果一致性
        let uniqueResults = resultCounter.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
        
        let totalSuccessfulRequests = Double(successfulRequests)
        let mostCommonCount = Double(uniqueResults.first?.1 ?? 0)
        let resultConsistency = totalSuccessfulRequests > 0 ? (mostCommonCount / totalSuccessfulRequests) * 100.0 : 0
        
        return StressTestResult(
            totalRequests: config.totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: failedRequests,
            averageResponseTime: responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count),
            minResponseTime: responseTimes.min() ?? 0,
            maxResponseTime: responseTimes.max() ?? 0,
            p95ResponseTime: sortedTimes.isEmpty ? 0 : sortedTimes[p95Index],
            p99ResponseTime: sortedTimes.isEmpty ? 0 : sortedTimes[p99Index],
            errors: errors.map { ($0.key, $0.value) },
            recognitionResult: lastRecognitionResult,
            wordFrequency: wordFrequency,
            audioDuration: audioDuration,
            resultConsistency: resultConsistency,
            uniqueResults: uniqueResults.prefix(5).map { ($0.0, $0.1) } // 最多保留前5个不同结果
        )
    }
    
    /// 打印测试报告
    /// - Parameter result: 测试结果
    public func printReport(_ result: StressTestResult) {
        print("""
        
        ====== 压力测试报告 ======
        音频文件: \(config.audioFilePath)
        引擎类型: \(config.engineType)
        \(result.audioDuration != nil ? "音频时长: \(result.audioDuration!)ms (\(String(format: "%.2f", Double(result.audioDuration!) / 1000))秒)\n" : "")
        总请求数: \(result.totalRequests)
        成功请求: \(result.successfulRequests)
        失败请求: \(result.failedRequests)
        成功率: \(String(format: "%.2f%%", Double(result.successfulRequests) / Double(result.totalRequests) * 100))
        
        识别结果一致性: \(String(format: "%.2f%%", result.resultConsistency))
        \(result.uniqueResults.isEmpty ? "" : """
        识别结果分布:
        \(result.uniqueResults.map { "- \($0.result) (\($0.count)次, \(String(format: "%.1f%%", Double($0.count) / Double(result.successfulRequests) * 100)))" }.joined(separator: "\n"))
        """)
        
        响应时间统计（毫秒）:
        平均: \(String(format: "%.2f", result.averageResponseTime))
        最小: \(String(format: "%.2f", result.minResponseTime))
        最大: \(String(format: "%.2f", result.maxResponseTime))
        95分位: \(String(format: "%.2f", result.p95ResponseTime))
        99分位: \(String(format: "%.2f", result.p99ResponseTime))
        
        \(result.recognitionResult != nil ? "最后一次识别结果: \(result.recognitionResult!)\n" : "")
        
        \(result.wordFrequency.isEmpty ? "" : """
        高频词统计 (出现>1次):
        \(result.wordFrequency.prefix(10).map { "- \($0.word): \($0.count)次" }.joined(separator: "\n"))
        
        """)
        
        错误统计:
        \(result.errors.isEmpty ? "无错误" : result.errors.map { "- \($0.error): \($0.count)次" }.joined(separator: "\n"))
        ======================
        """)
    }
}

/// 词频统计工具
private class WordCounter {
    private var wordCounts: [String: Int] = [:]
    private let lock = NSLock()
    
    /// 添加文本并统计词频
    func addText(_ text: String) {
        // 改进的中文分词方法
        // 使用简单的基于字典的分词算法
        let words = chineseSegmentation(text)
        
        lock.lock()
        defer { lock.unlock() }
        
        for word in words {
            if word.count >= 2 { // 只统计长度>=2的词
                wordCounts[word, default: 0] += 1
            }
        }
    }
    
    /// 获取词频统计结果
    func getFrequency() -> [(word: String, count: Int)] {
        lock.lock()
        defer { lock.unlock() }
        
        return wordCounts.map { ($0.key, $0.value) }
    }
    
    /// 简单的中文分词算法
    /// 使用最大匹配法进行简单分词
    private func chineseSegmentation(_ text: String) -> [String] {
        // 定义一些常见的中文词语
        let commonWords: Set<String> = [
            "语音识别", "腾讯云", "人工智能", "机器学习", "深度学习", "神经网络", 
            "自然语言", "处理", "语音合成", "压力测试", "高并发", "测试报告",
            "请求", "响应", "时间", "毫秒", "成功", "失败", "统计", "平均",
            "最小", "最大", "百分位", "错误", "详情", "总数", "并发", "引擎",
            "模型", "音频", "文件", "测试", "报告", "结果", "详细", "信息",
            "你好", "世界", "中国", "北京", "上海", "广州", "深圳", "杭州",
            "今天", "明天", "昨天", "早上", "中午", "下午", "晚上", "时间",
            "我们", "你们", "他们", "大家", "一起", "开始", "结束", "完成"
        ]
        
        var result: [String] = []
        var remainingText = text
        
        // 从长到短匹配常见词
        while !remainingText.isEmpty {
            var foundMatch = false
            
            // 尝试匹配最长词
            for wordLength in (2...4).reversed() {
                if remainingText.count < wordLength {
                    continue
                }
                
                let start = remainingText.startIndex
                let end = remainingText.index(start, offsetBy: wordLength, limitedBy: remainingText.endIndex) ?? remainingText.endIndex
                let possibleWord = String(remainingText[start..<end])
                
                if commonWords.contains(possibleWord) {
                    result.append(possibleWord)
                    remainingText.removeFirst(wordLength)
                    foundMatch = true
                    break
                }
            }
            
            // 如果没有匹配到常见词，则按字符切分
            if !foundMatch {
                if let firstChar = remainingText.first {
                    result.append(String(firstChar))
                    remainingText.removeFirst()
                }
            }
        }
        
        return result
    }
} 