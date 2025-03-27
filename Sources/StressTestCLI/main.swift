//
//  main.swift
//  StressTestCLI
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation
import ArgumentParser
import TencentCloudAPI

@main
struct StressTestCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "stress-test",
        abstract: "腾讯云语音识别API压力测试工具"
    )
    
    @Option(name: .long, help: "腾讯云 SecretId")
    var secretId: String
    
    @Option(name: .long, help: "腾讯云 SecretKey")
    var secretKey: String
    
    @Option(name: .long, help: "并发请求数")
    var concurrentRequests: Int = 10
    
    @Option(name: .long, help: "总请求数")
    var totalRequests: Int = 100
    
    @Option(name: .long, help: "请求间隔（毫秒）")
    var requestInterval: Int = 100
    
    @Option(name: .long, help: "超时时间（秒）")
    var timeout: Int = 30
    
    @Option(name: .long, help: "引擎类型")
    var engineType: String = "16k_zh"
    
    @Argument(help: "音频文件路径")
    var audioFilePath: String
    
    func run() async throws {
        let config = TencentCloudAPIConfig(
            secretId: secretId,
            secretKey: secretKey,
            region: "ap-guangzhou",
            endpoint: "asr.tencentcloudapi.com",
            requestTimeout: TimeInterval(timeout),
            autoRetry: true,
            maxRetries: 3
        )
        
        let client = TencentCloudAPIClient(config: config)
        let stressTest = StressTest(
            client: client,
            config: StressTestConfig(
                concurrentRequests: concurrentRequests,
                totalRequests: totalRequests,
                requestInterval: requestInterval,
                timeout: timeout,
                audioFilePath: "/Users/nanzhi/Downloads/test.mp3",
                engineType: engineType
            )
        )
        
        print("开始压力测试...")
        let result = try await stressTest.run()
        stressTest.printReport(result)
    }
} 