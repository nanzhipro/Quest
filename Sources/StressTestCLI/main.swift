//
//  main.swift
//  StressTestCLI
//
//  Created by CursorAI on 2024-03-26.
//

import ArgumentParser
import Foundation
import TencentCloudAPI

struct StressTestCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "stress-test",
        abstract: "腾讯云语音识别API压力测试工具",
        discussion: """
        示例：
        stress-test secretId secretKey audioFilePath
        """
    )
    
    @Argument(help: "腾讯云 SecretId")
    var secretId: String
    
    @Argument(help: "腾讯云 SecretKey")
    var secretKey: String
    
    @Argument(help: "要识别的音频文件路径（支持格式：wav、mp3、m4a、flac等）")
    var audioFilePath: String
    
    @Option(help: "并发请求数")
    var concurrentRequests: Int = 10
    
    @Option(help: "总请求数")
    var totalRequests: Int = 100
    
    @Option(help: "请求间隔（毫秒）")
    var requestInterval: Int = 100
    
    @Option(help: "超时时间（秒）")
    var timeout: Int = 30
    
    @Option(help: "引擎类型")
    var engineType: String = "16k_zh"
    
    func validate() throws {
        print("验证参数中...")
        print("SecretId: \(secretId)")
        print("SecretKey: \(secretKey)")
        print("AudioFilePath: \(audioFilePath)")
        
        // 验证音频文件是否存在
        guard FileManager.default.fileExists(atPath: audioFilePath) else {
            throw ValidationError("音频文件不存在：\(audioFilePath)")
        }
    }
    
    func run() throws {
        print("参数解析成功，开始执行...")
        
        // 在同步run方法中启动异步任务
        Task {
            do {
                print("SecretId: \(secretId)")
                print("SecretKey: \(secretKey)")
                print("AudioFilePath: \(audioFilePath)")
                
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
                        audioFilePath: audioFilePath,
                        engineType: engineType
                    )
                )
                
                print("开始压力测试...")
                let result = try await stressTest.run()
                stressTest.printReport(result)
                
                print("压力测试完成!")
                Foundation.exit(0)
            } catch {
                print("压力测试失败: \(error)")
                Foundation.exit(1)
            }
        }
        
        // 保持主线程运行直到异步任务完成
        RunLoop.main.run()
    }
}

StressTestCLI.main() 