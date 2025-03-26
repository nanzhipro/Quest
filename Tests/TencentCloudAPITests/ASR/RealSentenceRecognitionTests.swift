//
//  RealSentenceRecognitionTests.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import XCTest
@testable import TencentCloudAPI

/// 真实的一句话识别测试
/// 注意: 这些测试需要有效的API凭证才能运行
final class RealSentenceRecognitionTests: XCTestCase {
    
    // API凭证和配置
    static let secretId = ProcessInfo.processInfo.environment["TENCENT_CLOUD_SECRET_ID"] ?? ""
    static let secretKey = ProcessInfo.processInfo.environment["TENCENT_CLOUD_SECRET_KEY"] ?? ""
    static let region = "ap-guangzhou"
    
    // 测试一句话识别 - 使用本地音频文件
    func testSentenceRecognitionWithFile() async throws {
        // 验证凭证
        guard !RealSentenceRecognitionTests.secretId.isEmpty && !RealSentenceRecognitionTests.secretKey.isEmpty else {
            XCTFail("需要有效的API凭证才能运行此测试。请设置环境变量TENCENT_CLOUD_SECRET_ID和TENCENT_CLOUD_SECRET_KEY")
            return
        }
        
        // 创建API实例
        let tencent = TencentCloud.create(
            secretId: RealSentenceRecognitionTests.secretId,
            secretKey: RealSentenceRecognitionTests.secretKey,
            region: RealSentenceRecognitionTests.region
        )
        
        // 创建ASR服务
        let asrService = tencent.asr()

        let testAudioPath = "/Users/nanzhi/Downloads/audio (2).wav"
        
        // 创建请求
        let request = try ASRService.createSentenceRecognitionRequestFromFile(
            filePath: testAudioPath,
            engineType: "16k_zh",
            options: [
                "wordInfo": 1,
                "filterDirty": 1,
                "filterModal": 1,
                "filterPunc": 1,
                "convertNumMode": 1
            ]
        )
        
        do {
            // 发送请求
            let response = try await asrService.sentenceRecognition(request: request)
            
            // 验证响应
            XCTAssertNotNil(response)
            XCTAssertFalse(response.result.isEmpty)
            XCTAssertNotNil(response.requestId)
            XCTAssertGreaterThan(response.audioDuration, 0)
            
            // 打印结果
            print("识别结果: \(response.result)")
            print("音频时长: \(response.audioDuration)ms")
            if let wordList = response.wordList {
                print("词时间戳:")
                for word in wordList {
                    print("  \(word.word): \(word.startTime)ms - \(word.endTime)ms")
                }
            }
        } catch {
            XCTFail("一句话识别请求失败: \(error.localizedDescription)")
        }
        
        // 清理临时文件
        try? FileManager.default.removeItem(atPath: testAudioPath)
    }
} 