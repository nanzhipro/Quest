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
    }
    
    /// 处理语音识别请求
    /// - Parameter req: HTTP请求
    /// - Returns: 语音识别响应
    func recognizeVoice(req: Request) async throws -> VoiceRecognitionResponse {
        let voiceRequest = try req.content.decode(VoiceRecognitionRequest.self)
        
        // 验证语音数据
        guard !voiceRequest.audioData.isEmpty else {
            throw Abort(.badRequest, reason: "语音数据不能为空")
        }
        
        // 创建ASR服务实例
        let asrService = tencentCloud.asr()
        
        // 构建ASR请求
        let request = SentenceRecognitionRequest(
            engineType: voiceRequest.engineType ?? "16k_zh",
            sourceType: 1,  // 使用数据模式
            voiceFormat: voiceRequest.audioFormat ?? "wav",
            data: voiceRequest.audioData,
            dataLen: Data(base64Encoded: voiceRequest.audioData)?.count,
            wordInfo: voiceRequest.wordInfo,
            filterDirty: voiceRequest.filterDirty,
            filterModal: voiceRequest.filterModal,
            filterPunc: voiceRequest.filterPunc,
            convertNumMode: voiceRequest.convertNumMode
        )
        
        // 发送请求到腾讯云
        do {
            let response = try await asrService.sentenceRecognition(request: request)
            return VoiceRecognitionResponse(from: response)
        } catch let error as TencentCloudAPIError {
            // 处理腾讯云API特定错误
            switch error {
            case .requestFailed(let message):
                throw Abort(.serviceUnavailable, reason: "请求失败: \(message)")
            case .signatureGenerationFailed(let message):
                throw Abort(.internalServerError, reason: "签名生成失败: \(message)")
            case .invalidParameter(let paramName, let message):
                throw Abort(.badRequest, reason: "参数无效[\(paramName)]: \(message)")
            case .responseParsingFailed(let message):
                throw Abort(.internalServerError, reason: "响应解析失败: \(message)")
            case .serviceError(let code, let message):
                throw Abort(.serviceUnavailable, reason: "服务错误[\(code)]: \(message)")
            case .unknown(let message):
                throw Abort(.internalServerError, reason: "未知错误: \(message)")
            }
        } catch {
            // 处理其他错误
            throw Abort(.internalServerError, reason: "语音识别处理错误: \(error.localizedDescription)")
        }
    }
} 