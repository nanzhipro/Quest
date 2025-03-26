# 腾讯云API SDK

## 简介

这是一个用于访问腾讯云API的Swift SDK。目前支持以下服务：

- ASR (语音识别)：一句话识别

## 安装

### Swift Package Manager

在`Package.swift`中添加以下依赖：

```swift
dependencies: [
    .package(url: "YOUR_REPOSITORY_URL", from: "1.0.0")
]
```

并在目标依赖中添加：

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "TencentCloudAPI", package: "YOUR_PACKAGE_NAME")
        ]
    )
]
```

## 使用示例

### 初始化

```swift
import TencentCloudAPI

// 方法1：使用配置对象
let config = TencentCloudAPIConfig(
    secretId: "your-secret-id",
    secretKey: "your-secret-key",
    region: "ap-guangzhou"
)
let tencent = TencentCloud(config: config)

// 方法2：使用简便方法
let tencent = TencentCloud.create(
    secretId: "your-secret-id",
    secretKey: "your-secret-key",
    region: "ap-guangzhou"
)
```

### 语音识别 - 一句话识别

```swift
// 获取ASR服务
let asrService = tencent.asr()

// 示例1：使用音频URL
let urlRequest = ASRService.createSentenceRecognitionRequestFromURL(
    url: "https://example.com/audio.wav",
    engineType: "16k_zh",
    voiceFormat: "wav",
    options: ["wordInfo": 1]
)

// 示例2：使用本地音频文件
let fileRequest = try ASRService.createSentenceRecognitionRequestFromFile(
    filePath: "/path/to/audio.wav",
    engineType: "16k_zh"
)

// 示例3：手动构建请求
let request = SentenceRecognitionRequest(
    engineType: "16k_zh",
    sourceType: 0,  // 0: URL, 1: 数据
    voiceFormat: "wav",
    url: "https://example.com/audio.wav",
    wordInfo: 1
)

// 发送请求
do {
    let response = try await asrService.sentenceRecognition(request: request)
    print("识别结果：\(response.result)")
    print("音频时长：\(response.audioDuration)ms")
    
    // 访问词时间戳（如果请求中设置了wordInfo）
    if let wordList = response.wordList {
        for word in wordList {
            print("\(word.word): \(word.startTime)ms - \(word.endTime)ms")
        }
    }
} catch {
    print("错误：\(error.localizedDescription)")
}
```

### 高级配置

```swift
// 自定义配置
let config = TencentCloudAPIConfig(
    secretId: "your-secret-id",
    secretKey: "your-secret-key",
    region: "ap-guangzhou",
    endpoint: "asr.tencentcloudapi.com",  // 自定义端点
    requestTimeout: 120,                  // 请求超时时间（秒）
    autoRetry: true,                      // 是否自动重试
    maxRetries: 3,                        // 最大重试次数
    defaultVersion: "2019-06-14"          // API 版本
)

// 使用便捷方法设置高级选项
let tencent = TencentCloud.create(
    secretId: "your-secret-id", 
    secretKey: "your-secret-key",
    region: "ap-guangzhou",
    options: [
        "endpoint": "asr.tencentcloudapi.com",
        "timeout": 120,
        "autoRetry": true,
        "maxRetries": 3,
        "defaultVersion": "2019-06-14"
    ]
)
```

### 错误处理

```swift
do {
    let response = try await asrService.sentenceRecognition(request: request)
    // 处理成功响应
} catch let error as TencentCloudAPIError {
    switch error {
    case .requestFailed(let message):
        print("请求失败: \(message)")
    case .signatureGenerationFailed(let message):
        print("签名生成失败: \(message)")
    case .invalidParameter(let paramName, let message):
        print("参数无效[\(paramName)]: \(message)")
    case .responseParsingFailed(let message):
        print("响应解析失败: \(message)")
    case .serviceError(let code, let message):
        print("服务错误[\(code)]: \(message)")
    case .unknown(let message):
        print("未知错误: \(message)")
    }
} catch {
    print("其他错误: \(error.localizedDescription)")
}
```

## 扩展

这个SDK被设计为可扩展的。未来可以轻松添加更多腾讯云API服务：

1. 为新API创建请求和响应模型
2. 实现新的服务类
3. 向`TencentCloud`类添加新的便捷方法

## 贡献

欢迎贡献代码、报告问题或提出改进建议。 