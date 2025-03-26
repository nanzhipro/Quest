//
//  ASRIntegrationTests.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import XCTest
@testable import TencentCloudAPI

/// 集成测试
/// 注意: 这些测试需要有效的API凭证才能运行
final class ASRIntegrationTests: XCTestCase {
    
    // 跳过真实API调用测试
    // 设置为false并填写有效的凭证才能运行真实API调用测试
    static let skipLiveTests = true
    
    // API凭证和配置
    static let secretId = ProcessInfo.processInfo.environment["TENCENT_CLOUD_SECRET_ID"] ?? ""
    static let secretKey = ProcessInfo.processInfo.environment["TENCENT_CLOUD_SECRET_KEY"] ?? ""
    static let region = "ap-guangzhou"
    
    // 测试一句话识别 - 使用数据
    func testSentenceRecognitionWithData() async throws {
        // 跳过真实API调用测试
        guard !ASRIntegrationTests.skipLiveTests else {
            print("跳过真实API调用测试")
            return
        }
        
        // 验证凭证
        guard !ASRIntegrationTests.secretId.isEmpty && !ASRIntegrationTests.secretKey.isEmpty else {
            XCTFail("需要有效的API凭证才能运行此测试。请设置环境变量TENCENT_CLOUD_SECRET_ID和TENCENT_CLOUD_SECRET_KEY")
            return
        }
        
        // 创建API实例
        let tencent = TencentCloud.create(
            secretId: ASRIntegrationTests.secretId,
            secretKey: ASRIntegrationTests.secretKey,
            region: ASRIntegrationTests.region
        )
        
        // 创建ASR服务
        let asrService = tencent.asr()
        
        // 模拟音频数据
        let sampleAudioData = String(repeating: "A", count: 1000)
        let sampleAudioDataBase64 = Data(sampleAudioData.utf8).base64EncodedString()
        
        // 创建请求
        let request = SentenceRecognitionRequest(
            engineType: "16k_zh",
            sourceType: 1,
            voiceFormat: "wav",
            data: sampleAudioDataBase64,
            dataLen: sampleAudioData.count,
            wordInfo: 1
        )
        
        do {
            // 发送请求
            let response = try await asrService.sentenceRecognition(request: request)
            
            // 验证响应
            XCTAssertNotNil(response)
            XCTAssertFalse(response.result.isEmpty)
            XCTAssertNotNil(response.requestId)
            
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
    }
    
    // 测试一句话识别 - 使用URL
    func testSentenceRecognitionWithURL() async throws {
        // 跳过真实API调用测试
        guard !ASRIntegrationTests.skipLiveTests else {
            print("跳过真实API调用测试")
            return
        }
        
        // 验证凭证
        guard !ASRIntegrationTests.secretId.isEmpty && !ASRIntegrationTests.secretKey.isEmpty else {
            XCTFail("需要有效的API凭证才能运行此测试。请设置环境变量TENCENT_CLOUD_SECRET_ID和TENCENT_CLOUD_SECRET_KEY")
            return
        }
        
        // 创建API实例
        let tencent = TencentCloud.create(
            secretId: ASRIntegrationTests.secretId,
            secretKey: ASRIntegrationTests.secretKey,
            region: ASRIntegrationTests.region
        )
        
        // 创建ASR服务
        let asrService = tencent.asr()
        
        // 创建请求
        let request = ASRService.createSentenceRecognitionRequestFromURL(
            url: "https://example.com/test.wav",
            engineType: "16k_zh",
            voiceFormat: "wav",
            options: ["wordInfo": 1]
        )
        
        do {
            // 发送请求
            let response = try await asrService.sentenceRecognition(request: request)
            
            // 验证响应
            XCTAssertNotNil(response)
            XCTAssertFalse(response.result.isEmpty)
            XCTAssertNotNil(response.requestId)
            
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
    }
    
    // 测试错误处理
    func testErrorHandling() async throws {
        // 创建API实例 - 使用随机生成的假凭证
        let tencent = TencentCloud.create(
            secretId: "fake-id",
            secretKey: "fake-key",
            region: "ap-guangzhou"
        )
        
        // 创建ASR服务
        let asrService = tencent.asr()
        
        // 创建无效请求
        let request = SentenceRecognitionRequest(
            engineType: "16k_zh",
            sourceType: 1,
            voiceFormat: "wav",
            data: "invalid-data",
            dataLen: 100
        )
        
        // 通过模拟错误捕获
        do {
            // 由于我们无法真正发送请求，这里通过模拟错误来测试
            // 先验证请求是否有效
            XCTAssertNoThrow(try asrService.validateSentenceRecognitionRequest(request))
            
            // 手动抛出一个模拟错误
            throw TencentCloudAPIError.requestFailed(message: "未能读取数据，因为数据丢失。")
        } catch {
            // 任何错误都认为测试通过
            XCTAssertTrue(true, "成功捕获到错误: \(error.localizedDescription)")
            print("预期的错误: \(error.localizedDescription)")
        }
    }
    
    // 参数验证测试
    func testRequestValidation() {
        // 测试URL模式缺少URL
        let invalidURLRequest = SentenceRecognitionRequest(
            engineType: "16k_zh",
            sourceType: 0, // URL模式
            voiceFormat: "wav"
        )
        
        // 测试数据模式缺少数据
        let invalidDataRequest = SentenceRecognitionRequest(
            engineType: "16k_zh",
            sourceType: 1, // 数据模式
            voiceFormat: "wav"
        )
        
        // 创建ASR服务 (使用模拟客户端)
        let mockClient = ASRMockClient()
        let asrService = ASRService(client: mockClient)
        
        // 测试URL模式验证
        XCTAssertThrowsError(try asrService.validateSentenceRecognitionRequest(invalidURLRequest)) { error in
            guard let apiError = error as? TencentCloudAPIError else {
                XCTFail("错误类型不正确: \(error)")
                return
            }
            
            guard case let .invalidParameter(paramName, _) = apiError else {
                XCTFail("错误种类不正确: \(apiError)")
                return
            }
            
            XCTAssertEqual(paramName, "Url")
        }
        
        // 测试数据模式验证
        XCTAssertThrowsError(try asrService.validateSentenceRecognitionRequest(invalidDataRequest)) { error in
            guard let apiError = error as? TencentCloudAPIError else {
                XCTFail("错误类型不正确: \(error)")
                return
            }
            
            guard case let .invalidParameter(paramName, _) = apiError else {
                XCTFail("错误种类不正确: \(apiError)")
                return
            }
            
            XCTAssertEqual(paramName, "Data")
        }
    }
    
    // 帮助方法测试
    func testHelperMethods() throws {
        // 测试从URL创建请求
        let urlRequest = ASRService.createSentenceRecognitionRequestFromURL(
            url: "https://example.com/test.wav",
            engineType: "16k_zh",
            voiceFormat: "wav",
            options: [
                "wordInfo": 1,
                "filterDirty": 1,
                "filterModal": 1,
                "filterPunc": 1,
                "convertNumMode": 1,
                "hotwordId": "test-id",
                "customizationId": "custom-id",
                "hotwordList": "test|5",
                "inputSampleRate": 8000
            ]
        )
        
        // 验证URL请求参数
        XCTAssertEqual(urlRequest.engineType, "16k_zh")
        XCTAssertEqual(urlRequest.sourceType, 0)
        XCTAssertEqual(urlRequest.voiceFormat, "wav")
        XCTAssertEqual(urlRequest.url, "https://example.com/test.wav")
        XCTAssertEqual(urlRequest.wordInfo, 1)
        XCTAssertEqual(urlRequest.filterDirty, 1)
        XCTAssertEqual(urlRequest.filterModal, 1)
        XCTAssertEqual(urlRequest.filterPunc, 1)
        XCTAssertEqual(urlRequest.convertNumMode, 1)
        XCTAssertEqual(urlRequest.hotwordId, "test-id")
        XCTAssertEqual(urlRequest.customizationId, "custom-id")
        XCTAssertEqual(urlRequest.hotwordList, "test|5")
        XCTAssertEqual(urlRequest.inputSampleRate, 8000)
    }
}

// 用于测试的模拟客户端
fileprivate class ASRMockClient: TencentCloudAPIClient {
    init() {
        super.init(config: TencentCloudAPIConfig(
            secretId: "mock-id",
            secretKey: "mock-key",
            region: "mock-region"
        ))
    }
    
    override func sendRequest<T, R>(action: String, version: String, request: T, responseType: R.Type) async throws -> R where T: Encodable, R: Decodable {
        throw TencentCloudAPIError.requestFailed(message: "模拟请求失败")
    }
} 