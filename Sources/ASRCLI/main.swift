//
//  main.swift
//  ASRCLI
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation
import TencentCloudAPI

@main
struct ASRCLI {
    static func main() async throws {
        // 从环境变量获取凭证
        guard let secretId = ProcessInfo.processInfo.environment["TENCENT_CLOUD_SECRET_ID"],
              let secretKey = ProcessInfo.processInfo.environment["TENCENT_CLOUD_SECRET_KEY"] else {
            print("错误: 请设置环境变量 TENCENT_CLOUD_SECRET_ID 和 TENCENT_CLOUD_SECRET_KEY")
            exit(1)
        }
        
        // 创建API实例
        let tencent = TencentCloud.create(
            secretId: secretId,
            secretKey: secretKey,
            region: "ap-guangzhou"
        )
        
        // 创建ASR服务
        let service = tencent.asr()
        
        // 获取音频文件路径
        guard let audioPath = CommandLine.arguments.dropFirst().first else {
            print("错误: 请提供音频文件路径")
            print("用法: ASRCLI <音频文件路径>")
            exit(1)
        }
        
        do {
            // 创建请求
            let request = try ASRService.createSentenceRecognitionRequestFromFile(
                filePath: audioPath,
                engineType: "16k_zh",
                options: [
                    "wordInfo": 1,
                    "filterDirty": 1,
                    "filterModal": 1,
                    "filterPunc": 1,
                    "convertNumMode": 1
                ]
            )
            
            // 发送请求
            let response = try await service.sentenceRecognition(request: request)
            
            // 打印结果
            print("\n识别结果:")
            print("----------------------------------------")
            print(response.result)
            print("----------------------------------------")
            print("音频时长: \(response.audioDuration)ms")
            
            // if let wordList = response.wordList {
            //     print("\n词时间戳:")
            //     for word in wordList {
            //         print("  \(word.word): \(word.startTime)ms - \(word.endTime)ms")
            //     }
            // }
            
        } catch {
            print("错误: \(error.localizedDescription)")
            exit(1)
        }
    }
} 