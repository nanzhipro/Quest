//
//  VoiceRecognitionController.swift
//  Quest
//
//  Created by CursorAI on 2024-03-27.
//

import Vapor
import TencentCloudAPI
import Foundation

// MARK: - 请求和响应模型

/// 语音识别请求模型
struct VoiceRecognitionRequest: Content {
    /// 语音数据（Base64编码）
    let audioData: String
    /// 音频格式，默认为wav
    let audioFormat: String?
    /// 引擎类型，默认为16k_zh
    let engineType: String?
    /// 是否显示词级别时间戳 (0: 不显示; 1: 显示，不包含标点; 2: 显示，包含标点)
    let wordInfo: Int?
    /// 是否过滤脏词 (0: 不过滤; 1: 过滤; 2: 用*替代)
    let filterDirty: Int?
    /// 是否过滤语气词 (0: 不过滤; 1: 部分过滤; 2: 严格过滤)
    let filterModal: Int?
    /// 是否过滤标点符号 (0: 不过滤; 1: 过滤句末标点; 2: 过滤所有标点)
    let filterPunc: Int?
    /// 是否进行阿拉伯数字智能转换 (0: 不转换; 1: 根据场景智能转换)
    let convertNumMode: Int?
}

/// 语音识别响应模型
struct VoiceRecognitionResponse: Content {
    /// 识别结果文本
    let text: String
    /// 请求的音频时长（毫秒）
    let audioDuration: Int
    /// 词时间戳列表（仅当请求中启用了wordInfo时有效）
    let words: [WordInfo]?
    /// 请求ID
    let requestId: String
    
    /// 从腾讯云ASR响应创建
    init(from response: SentenceRecognitionResponse) {
        self.text = response.result
        self.audioDuration = response.audioDuration
        self.requestId = response.requestId
        
        if let wordList = response.wordList {
            self.words = wordList.map { WordInfo(from: $0) }
        } else {
            self.words = nil
        }
    }
}

/// 词时间戳信息
struct WordInfo: Content {
    /// 词文本
    let text: String
    /// 开始时间（毫秒）
    let startTime: Int
    /// 结束时间（毫秒）
    let endTime: Int
    
    /// 从腾讯云ASR词时间戳创建
    init(from sentenceWord: SentenceWord) {
        self.text = sentenceWord.word
        self.startTime = sentenceWord.startTime
        self.endTime = sentenceWord.endTime
    }
}

// MARK: - 控制器实现

/// 语音识别控制器
struct VoiceRecognitionController: RouteCollection {
    // 腾讯云API客户端（全局单例）
    private let tencentCloud: TencentCloud
    
    /// 使用给定的配置初始化控制器
    /// - Parameter config: 腾讯云API配置
    init(config: TencentCloudAPIConfig) {
        self.tencentCloud = TencentCloud(config: config)
    }
    
    /// 路由注册
    func boot(routes: RoutesBuilder) throws {
        let voiceRoutes = routes.grouped("api", "v1", "voice")
        voiceRoutes.post("recognize", use: recognizeVoice)
        
        // 添加一个健康检查端点
        voiceRoutes.get("health") { req -> String in
            req.logger.info("语音识别服务健康检查", source: "VoiceRecognitionController")
            return "语音识别服务正常"
        }
    }
    
    /// 处理语音识别请求
    /// - Parameter req: HTTP请求
    /// - Returns: 语音识别响应
    func recognizeVoice(req: Request) async throws -> VoiceRecognitionResponse {
        // 生成请求ID用于日志跟踪
        let requestTraceId = UUID().uuidString.prefix(8)
        
        req.logger.info("收到语音识别请求", 
                      metadata: ["traceId": .string(String(requestTraceId))], 
                      source: "VoiceRecognitionController")
        
        // 解码请求
        let startDecodeTime = Date()
        let voiceRequest = try req.content.decode(VoiceRecognitionRequest.self)
        
        // 计算音频数据大小
        let audioDataSize = voiceRequest.audioData.count
        let audioDataSizeKB = Double(audioDataSize) / 1024.0
        
        req.logger.debug("请求解码完成", 
                       metadata: [
                           "traceId": .string(String(requestTraceId)),
                           "audioFormat": .string(voiceRequest.audioFormat ?? "wav"),
                           "engineType": .string(voiceRequest.engineType ?? "16k_zh"),
                           "audioDataSize": .string(String(format: "%.2f KB", audioDataSizeKB)),
                           "decodeTime": .string("\(Date().timeIntervalSince(startDecodeTime) * 1000) ms")
                       ], 
                       source: "VoiceRecognitionController")
        
        // 验证语音数据
        guard !voiceRequest.audioData.isEmpty else {
            req.logger.error("语音数据为空", 
                           metadata: ["traceId": .string(String(requestTraceId))], 
                           source: "VoiceRecognitionController")
            throw Abort(.badRequest, reason: "语音数据不能为空")
        }
        
        // 验证数据大小
        guard let audioBytes = Data(base64Encoded: voiceRequest.audioData) else {
            req.logger.error("Base64解码失败", 
                           metadata: ["traceId": .string(String(requestTraceId))], 
                           source: "VoiceRecognitionController")
            throw Abort(.badRequest, reason: "音频数据Base64解码失败")
        }
        
        let audioByteSize = audioBytes.count
        req.logger.debug("音频数据验证", 
                       metadata: [
                           "traceId": .string(String(requestTraceId)),
                           "audioByteSize": .string("\(audioByteSize) bytes"),
                           "audioDataSizeKB": .string(String(format: "%.2f KB", Double(audioByteSize) / 1024.0))
                       ], 
                       source: "VoiceRecognitionController")
        
        // 创建ASR服务实例
        let asrService = tencentCloud.asr()
        
        // 构建ASR请求
        let request = SentenceRecognitionRequest(
            engineType: voiceRequest.engineType ?? "16k_zh",
            sourceType: 1,  // 使用数据模式
            voiceFormat: voiceRequest.audioFormat ?? "wav",
            data: voiceRequest.audioData,
            dataLen: audioByteSize,
            wordInfo: voiceRequest.wordInfo,
            filterDirty: voiceRequest.filterDirty,
            filterModal: voiceRequest.filterModal,
            filterPunc: voiceRequest.filterPunc,
            convertNumMode: voiceRequest.convertNumMode
        )
        
        req.logger.info("发送请求到腾讯云ASR服务", 
                      metadata: [
                          "traceId": .string(String(requestTraceId)),
                          "engineType": .string(request.engineType),
                          "voiceFormat": .string(request.voiceFormat),
                          "wordInfo": .string(request.wordInfo.map { "\($0)" } ?? "nil")
                      ], 
                      source: "VoiceRecognitionController")
        
        // 发送请求到腾讯云
        let startProcessTime = Date()
        do {
            let response = try await asrService.sentenceRecognition(request: request)
            let processTime = Date().timeIntervalSince(startProcessTime) * 1000
            
            // 截取识别结果的前30个字符用于日志
            let previewText = response.result.count > 30 
                ? "\(response.result.prefix(30))..." 
                : response.result
            
            req.logger.info("语音识别成功", 
                          metadata: [
                              "traceId": .string(String(requestTraceId)),
                              "requestId": .string(response.requestId),
                              "audioDuration": .string("\(response.audioDuration) ms"),
                              "wordCount": .string("\(response.wordList?.count ?? 0)"),
                              "processTime": .string(String(format: "%.2f ms", processTime)),
                              "resultPreview": .string(previewText)
                          ], 
                          source: "VoiceRecognitionController")
            
            return VoiceRecognitionResponse(from: response)
        } catch let error as TencentCloudAPIError {
            // 处理腾讯云API特定错误
            let errorTime = Date().timeIntervalSince(startProcessTime) * 1000
            
            switch error {
            case .requestFailed(let message):
                req.logger.error("请求失败", 
                               metadata: [
                                   "traceId": .string(String(requestTraceId)),
                                   "errorTime": .string(String(format: "%.2f ms", errorTime)),
                                   "errorType": .string("RequestFailed"),
                                   "message": .string(message)
                               ], 
                               source: "VoiceRecognitionController")
                throw Abort(.serviceUnavailable, reason: "请求失败: \(message)")
                
            case .signatureGenerationFailed(let message):
                req.logger.error("签名生成失败", 
                               metadata: [
                                   "traceId": .string(String(requestTraceId)),
                                   "errorTime": .string(String(format: "%.2f ms", errorTime)),
                                   "errorType": .string("SignatureGenerationFailed"),
                                   "message": .string(message)
                               ], 
                               source: "VoiceRecognitionController")
                throw Abort(.internalServerError, reason: "签名生成失败: \(message)")
                
            case .invalidParameter(let paramName, let message):
                req.logger.error("参数无效", 
                               metadata: [
                                   "traceId": .string(String(requestTraceId)),
                                   "errorTime": .string(String(format: "%.2f ms", errorTime)),
                                   "errorType": .string("InvalidParameter"),
                                   "paramName": .string(paramName),
                                   "message": .string(message)
                               ], 
                               source: "VoiceRecognitionController")
                throw Abort(.badRequest, reason: "参数无效[\(paramName)]: \(message)")
                
            case .responseParsingFailed(let message):
                req.logger.error("响应解析失败", 
                               metadata: [
                                   "traceId": .string(String(requestTraceId)),
                                   "errorTime": .string(String(format: "%.2f ms", errorTime)),
                                   "errorType": .string("ResponseParsingFailed"),
                                   "message": .string(message)
                               ], 
                               source: "VoiceRecognitionController")
                throw Abort(.internalServerError, reason: "响应解析失败: \(message)")
                
            case .serviceError(let code, let message):
                req.logger.error("腾讯云服务错误", 
                               metadata: [
                                   "traceId": .string(String(requestTraceId)),
                                   "errorTime": .string(String(format: "%.2f ms", errorTime)),
                                   "errorType": .string("ServiceError"),
                                   "errorCode": .string(code),
                                   "message": .string(message)
                               ], 
                               source: "VoiceRecognitionController")
                throw Abort(.serviceUnavailable, reason: "服务错误[\(code)]: \(message)")
                
            case .unknown(let message):
                req.logger.error("未知错误", 
                               metadata: [
                                   "traceId": .string(String(requestTraceId)),
                                   "errorTime": .string(String(format: "%.2f ms", errorTime)),
                                   "errorType": .string("Unknown"),
                                   "message": .string(message)
                               ], 
                               source: "VoiceRecognitionController")
                throw Abort(.internalServerError, reason: "未知错误: \(message)")
            }
        } catch {
            // 处理其他错误
            let errorTime = Date().timeIntervalSince(startProcessTime) * 1000
            
            req.logger.error("处理异常", 
                           metadata: [
                               "traceId": .string(String(requestTraceId)),
                               "errorTime": .string(String(format: "%.2f ms", errorTime)),
                               "errorType": .string("\(type(of: error))"),
                               "message": .string(error.localizedDescription)
                           ], 
                           source: "VoiceRecognitionController")
            
            throw Abort(.internalServerError, reason: "语音识别处理错误: \(error.localizedDescription)")
        }
    }
} 