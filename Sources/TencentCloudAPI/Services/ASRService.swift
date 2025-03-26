//
//  ASRService.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation

/// 语音识别服务
public class ASRService {
    /// API客户端
    private let client: TencentCloudAPIClient
    /// API版本
    private let version: String
    
    /// 初始化语音识别服务
    /// - Parameters:
    ///   - client: API客户端
    ///   - version: API版本
    public init(client: TencentCloudAPIClient, version: String? = nil) {
        self.client = client
        self.version = version ?? client.config.defaultVersion
    }
    
    /// 一句话识别
    /// - Parameters:
    ///   - request: 请求参数
    /// - Returns: 识别结果
    public func sentenceRecognition(request: SentenceRecognitionRequest) async throws -> SentenceRecognitionResponse {
        // 参数验证
        try validateSentenceRecognitionRequest(request)
        
        // 发送请求
        return try await client.sendRequest(
            action: "SentenceRecognition",
            version: version,
            request: request,
            responseType: SentenceRecognitionResponse.self
        )
    }
    
    /// 校验一句话识别请求参数
    /// - Parameter request: 请求参数
    internal func validateSentenceRecognitionRequest(_ request: SentenceRecognitionRequest) throws {
        // 验证引擎模型类型
        guard !request.engineType.isEmpty else {
            throw TencentCloudAPIError.invalidParameter(
                paramName: "EngSerViceType", 
                message: "引擎模型类型不能为空"
            )
        }
        
        // 验证数据来源
        switch request.sourceType {
        case 0:
            // URL模式
            guard let url = request.url, !url.isEmpty else {
                throw TencentCloudAPIError.invalidParameter(
                    paramName: "Url", 
                    message: "当SourceType=0时，Url不能为空"
                )
            }
        case 1:
            // 数据模式
            guard let data = request.data, !data.isEmpty else {
                throw TencentCloudAPIError.invalidParameter(
                    paramName: "Data", 
                    message: "当SourceType=1时，Data不能为空"
                )
            }
            
            guard let dataLen = request.dataLen, dataLen > 0 else {
                throw TencentCloudAPIError.invalidParameter(
                    paramName: "DataLen", 
                    message: "当SourceType=1时，DataLen必须大于0"
                )
            }
        default:
            throw TencentCloudAPIError.invalidParameter(
                paramName: "SourceType", 
                message: "无效的SourceType值，必须为0或1"
            )
        }
        
        // 验证音频格式
        let validFormats = ["wav", "pcm", "ogg-opus", "speex", "silk", "mp3", "m4a", "aac", "amr"]
        guard validFormats.contains(request.voiceFormat.lowercased()) else {
            throw TencentCloudAPIError.invalidParameter(
                paramName: "VoiceFormat", 
                message: "无效的音频格式，支持的格式有：\(validFormats.joined(separator: ", "))"
            )
        }
    }
    
    /// 从本地音频文件创建一句话识别请求
    /// - Parameters:
    ///   - filePath: 音频文件路径
    ///   - engineType: 引擎模型类型
    ///   - voiceFormat: 音频格式
    ///   - options: 附加选项
    /// - Returns: 一句话识别请求
    public static func createSentenceRecognitionRequestFromFile(
        filePath: String,
        engineType: String = "16k_zh",
        voiceFormat: String? = nil,
        options: [String: Any] = [:]
    ) throws -> SentenceRecognitionRequest {
        // 读取文件
        guard let audioData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            throw TencentCloudAPIError.requestFailed(message: "无法读取音频文件：\(filePath)")
        }
        
        // 确定音频格式
        var format = voiceFormat
        if format == nil {
            let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
            format = fileExtension.isEmpty ? "wav" : fileExtension
        }
        
        // 确保音频大小在限制范围内（3MB）
        let maxSize = 3 * 1024 * 1024
        guard audioData.count <= maxSize else {
            throw TencentCloudAPIError.invalidParameter(
                paramName: "Data",
                message: "音频文件大小超过限制（3MB）"
            )
        }
        
        // 创建请求
        var request = SentenceRecognitionRequest(
            engineType: engineType,
            sourceType: 1, // 使用数据模式
            voiceFormat: format ?? "wav",
            data: audioData.base64EncodedString(),
            dataLen: audioData.count
        )
        
        // 设置附加选项
        if let wordInfo = options["wordInfo"] as? Int {
            request.wordInfo = wordInfo
        }
        
        if let filterDirty = options["filterDirty"] as? Int {
            request.filterDirty = filterDirty
        }
        
        if let filterModal = options["filterModal"] as? Int {
            request.filterModal = filterModal
        }
        
        if let filterPunc = options["filterPunc"] as? Int {
            request.filterPunc = filterPunc
        }
        
        if let convertNumMode = options["convertNumMode"] as? Int {
            request.convertNumMode = convertNumMode
        }
        
        if let hotwordId = options["hotwordId"] as? String {
            request.hotwordId = hotwordId
        }
        
        if let customizationId = options["customizationId"] as? String {
            request.customizationId = customizationId
        }
        
        if let hotwordList = options["hotwordList"] as? String {
            request.hotwordList = hotwordList
        }
        
        if let inputSampleRate = options["inputSampleRate"] as? Int {
            request.inputSampleRate = inputSampleRate
        }
        
        return request
    }
    
    /// 从URL创建一句话识别请求
    /// - Parameters:
    ///   - url: 音频URL
    ///   - engineType: 引擎模型类型
    ///   - voiceFormat: 音频格式
    ///   - options: 附加选项
    /// - Returns: 一句话识别请求
    public static func createSentenceRecognitionRequestFromURL(
        url: String,
        engineType: String = "16k_zh",
        voiceFormat: String,
        options: [String: Any] = [:]
    ) -> SentenceRecognitionRequest {
        // 创建请求
        var request = SentenceRecognitionRequest(
            engineType: engineType,
            sourceType: 0, // 使用URL模式
            voiceFormat: voiceFormat,
            url: url
        )
        
        // 设置附加选项
        if let wordInfo = options["wordInfo"] as? Int {
            request.wordInfo = wordInfo
        }
        
        if let filterDirty = options["filterDirty"] as? Int {
            request.filterDirty = filterDirty
        }
        
        if let filterModal = options["filterModal"] as? Int {
            request.filterModal = filterModal
        }
        
        if let filterPunc = options["filterPunc"] as? Int {
            request.filterPunc = filterPunc
        }
        
        if let convertNumMode = options["convertNumMode"] as? Int {
            request.convertNumMode = convertNumMode
        }
        
        if let hotwordId = options["hotwordId"] as? String {
            request.hotwordId = hotwordId
        }
        
        if let customizationId = options["customizationId"] as? String {
            request.customizationId = customizationId
        }
        
        if let hotwordList = options["hotwordList"] as? String {
            request.hotwordList = hotwordList
        }
        
        if let inputSampleRate = options["inputSampleRate"] as? Int {
            request.inputSampleRate = inputSampleRate
        }
        
        return request
    }
} 