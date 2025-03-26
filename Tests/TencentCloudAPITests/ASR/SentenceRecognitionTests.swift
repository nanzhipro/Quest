//
//  SentenceRecognitionTests.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import XCTest
@testable import TencentCloudAPI

final class SentenceRecognitionTests: XCTestCase {
    
    // 测试API客户端配置
    func testAPIClientConfiguration() async throws {
        // 创建配置
        let config = TencentCloudAPIConfig(
            secretId: "test-secret-id",
            secretKey: "test-secret-key",
            region: "ap-guangzhou"
        )
        
        // 创建客户端
        let client = TencentCloudAPIClient(config: config)
        
        // 验证配置
        XCTAssertEqual(client.config.secretId, "test-secret-id")
        XCTAssertEqual(client.config.secretKey, "test-secret-key")
        XCTAssertEqual(client.config.region, "ap-guangzhou")
    }
    
    // 测试一句话识别服务的初始化
    func testSentenceRecognitionServiceInitialization() {
        // 创建配置
        let config = TencentCloudAPIConfig(
            secretId: "test-secret-id",
            secretKey: "test-secret-key",
            region: "ap-guangzhou"
        )
        
        // 创建客户端
        let client = TencentCloudAPIClient(config: config)
        
        // 创建一句话识别服务
        let service = ASRService(client: client)
        
        // 验证服务已创建
        XCTAssertNotNil(service)
    }
    
    // 测试一句话识别请求参数构建
    func testSentenceRecognitionRequestParameters() {
        // 创建请求参数
        let params = SentenceRecognitionRequest(
            engineType: "16k_zh",
            sourceType: 1,
            voiceFormat: "wav",
            data: "base64-encoded-audio-data",
            dataLen: 1000
        )
        
        // 验证参数
        XCTAssertEqual(params.engineType, "16k_zh")
        XCTAssertEqual(params.sourceType, 1)
        XCTAssertEqual(params.voiceFormat, "wav")
        XCTAssertEqual(params.data, "base64-encoded-audio-data")
        XCTAssertEqual(params.dataLen, 1000)
    }
    
    // 测试签名生成
    func testSignatureGeneration() throws {
        // 创建签名生成器
        let generator = TC3SignatureGenerator(
            secretId: "test-secret-id",
            secretKey: "test-secret-key"
        )
        
        let timestamp = 1551113065
        let date = "2019-02-25"
        
        // 构建请求信息
        let requestInfo = TC3RequestInfo(
            httpMethod: "POST",
            canonicalURI: "/",
            canonicalQueryString: "",
            canonicalHeaders: "content-type:application/json; charset=utf-8\nhost:asr.tencentcloudapi.com\nx-tc-action:sentencerecognition\n",
            signedHeaders: "content-type;host;x-tc-action",
            requestPayload: "{\"EngSerViceType\":\"16k_zh\",\"SourceType\":1,\"VoiceFormat\":\"wav\",\"Data\":\"base64-encoded-audio-data\",\"DataLen\":1000}"
        )
        
        // 生成签名
        let signature = try generator.generateSignature(
            service: "asr",
            timestamp: timestamp,
            date: date, 
            requestInfo: requestInfo
        )
        
        // 验证签名不为空
        XCTAssertFalse(signature.isEmpty)
    }
    
    // 测试模拟一句话识别请求
    func testMockSentenceRecognition() async throws {
        // 创建模拟客户端
        let mockClient = MockTencentCloudAPIClient()
        
        // 设置模拟响应
        let mockResponse = SentenceRecognitionResponse(
            result: "腾讯云语音识别欢迎您。",
            audioDuration: 2430,
            wordSize: 4,
            wordList: [
                SentenceWord(word: "腾讯云", startTime: 120, endTime: 810),
                SentenceWord(word: "语音识别", startTime: 810, endTime: 1530),
                SentenceWord(word: "欢迎", startTime: 1530, endTime: 1890),
                SentenceWord(word: "您", startTime: 1890, endTime: 2250)
            ],
            requestId: "41ed9283-0c09-46fb-917b-0b83fa95f0be"
        )
        mockClient.mockResponse = mockResponse
        
        // 创建服务
        let service = ASRService(client: mockClient)
        
        // 创建请求
        let request = SentenceRecognitionRequest(
            engineType: "16k_zh",
            sourceType: 1,
            voiceFormat: "wav",
            data: "base64-encoded-audio-data",
            dataLen: 1000
        )
        
        // 执行请求
        let response = try await service.sentenceRecognition(request: request)
        
        // 验证响应
        XCTAssertEqual(response.result, "腾讯云语音识别欢迎您。")
        XCTAssertEqual(response.audioDuration, 2430)
        XCTAssertEqual(response.wordSize, 4)
        XCTAssertEqual(response.wordList?.count, 4)
        XCTAssertEqual(response.wordList?[0].word, "腾讯云")
        XCTAssertEqual(response.requestId, "41ed9283-0c09-46fb-917b-0b83fa95f0be")
    }
}

// 模拟API客户端
class MockTencentCloudAPIClient: TencentCloudAPIClient {
    var mockResponse: Any?
    
    init() {
        super.init(config: TencentCloudAPIConfig(
            secretId: "mock-id",
            secretKey: "mock-key",
            region: "mock-region"
        ))
    }
    
    override func sendRequest<T, R>(action: String, version: String, request: T, responseType: R.Type) async throws -> R where T: Encodable, R: Decodable {
        if let response = mockResponse as? R {
            return response
        }
        throw TencentCloudAPIError.requestFailed(message: "Mock response not provided or wrong type")
    }
} 