//
//  SentenceRecognitionModels.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation

// MARK: - 一句话识别请求
public struct SentenceRecognitionRequest: Codable {
    /// 引擎模型类型
    public var engineType: String
    /// 语音数据来源。0：语音URL；1：语音数据
    public var sourceType: Int
    /// 识别音频的音频格式
    public var voiceFormat: String
    /// 语音URL（当sourceType=0时必须）
    public var url: String?
    /// 语音数据，base64编码（当sourceType=1时必须）
    public var data: String?
    /// 数据长度，单位为字节（当sourceType=1时必须）
    public var dataLen: Int?
    /// 是否显示词级别时间戳。0：不显示；1：显示，不包含标点时间戳，2：显示，包含标点时间戳
    public var wordInfo: Int?
    /// 是否过滤脏词。0：不过滤；1：过滤；2：用*替代
    public var filterDirty: Int?
    /// 是否过滤语气词。0：不过滤；1：部分过滤；2：严格过滤
    public var filterModal: Int?
    /// 是否过滤标点符号。0：不过滤；1：过滤句末标点；2：过滤所有标点
    public var filterPunc: Int?
    /// 是否进行阿拉伯数字智能转换。0：不转换；1：根据场景智能转换
    public var convertNumMode: Int?
    /// 热词ID
    public var hotwordId: String?
    /// 自学习模型ID
    public var customizationId: String?
    /// 临时热词表
    public var hotwordList: String?
    /// 音频采样率
    public var inputSampleRate: Int?
    
    enum CodingKeys: String, CodingKey {
        case engineType = "EngSerViceType"
        case sourceType = "SourceType"
        case voiceFormat = "VoiceFormat"
        case url = "Url"
        case data = "Data"
        case dataLen = "DataLen"
        case wordInfo = "WordInfo"
        case filterDirty = "FilterDirty"
        case filterModal = "FilterModal"
        case filterPunc = "FilterPunc"
        case convertNumMode = "ConvertNumMode"
        case hotwordId = "HotwordId"
        case customizationId = "CustomizationId"
        case hotwordList = "HotwordList"
        case inputSampleRate = "InputSampleRate"
    }
    
    public init(
        engineType: String,
        sourceType: Int,
        voiceFormat: String,
        url: String? = nil,
        data: String? = nil,
        dataLen: Int? = nil,
        wordInfo: Int? = nil,
        filterDirty: Int? = nil,
        filterModal: Int? = nil,
        filterPunc: Int? = nil,
        convertNumMode: Int? = nil,
        hotwordId: String? = nil,
        customizationId: String? = nil,
        hotwordList: String? = nil,
        inputSampleRate: Int? = nil
    ) {
        self.engineType = engineType
        self.sourceType = sourceType
        self.voiceFormat = voiceFormat
        self.url = url
        self.data = data
        self.dataLen = dataLen
        self.wordInfo = wordInfo
        self.filterDirty = filterDirty
        self.filterModal = filterModal
        self.filterPunc = filterPunc
        self.convertNumMode = convertNumMode
        self.hotwordId = hotwordId
        self.customizationId = customizationId
        self.hotwordList = hotwordList
        self.inputSampleRate = inputSampleRate
    }
}

// MARK: - 一句话识别响应
public struct SentenceRecognitionResponse: Codable {
    /// 识别结果
    public let result: String
    /// 请求的音频时长，单位为ms
    public let audioDuration: Int
    /// 词时间戳列表的长度
    public let wordSize: Int?
    /// 词时间戳列表
    public let wordList: [SentenceWord]?
    /// 唯一请求ID
    public let requestId: String
    
    enum CodingKeys: String, CodingKey {
        case result = "Result"
        case audioDuration = "AudioDuration"
        case wordSize = "WordSize"
        case wordList = "WordList"
        case requestId = "RequestId"
    }
    
    public init(
        result: String,
        audioDuration: Int,
        wordSize: Int? = nil,
        wordList: [SentenceWord]? = nil,
        requestId: String
    ) {
        self.result = result
        self.audioDuration = audioDuration
        self.wordSize = wordSize
        self.wordList = wordList
        self.requestId = requestId
    }
}

// MARK: - 词时间戳
public struct SentenceWord: Codable {
    /// 词
    public let word: String
    /// 开始时间，单位为ms
    public let startTime: Int
    /// 结束时间，单位为ms
    public let endTime: Int
    
    enum CodingKeys: String, CodingKey {
        case word = "Word"
        case startTime = "StartTime"
        case endTime = "EndTime"
    }
    
    public init(word: String, startTime: Int, endTime: Int) {
        self.word = word
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - 腾讯云API通用响应包装器
public struct TencentCloudAPIResponse<T: Decodable>: Decodable {
    public let response: T
    
    enum CodingKeys: String, CodingKey {
        case response = "Response"
    }
    
    public init(response: T) {
        self.response = response
    }
} 