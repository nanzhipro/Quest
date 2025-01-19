import Foundation

/// 腾讯混元 OpenAI 客户端配置
public struct TencentHunyuanOpenAIConfig: Sendable {
  /// 默认配置值
  public enum Defaults {
    public static let host = "api.hunyuan.cloud.tencent.com"
    public static let timeoutInterval: TimeInterval = 60
    public static let model = "hunyuan-large" // hunyuan-standard ｜ hunyuan-lite ｜ hunyuan-large 
    public static let maxQueueSize = 100
    public static let maxConcurrentRequests = 10
  }

  public let apiToken: String
  public let host: String
  public let timeoutInterval: TimeInterval
  public let model: String
  public let maxQueueSize: Int
  public let maxConcurrentRequests: Int

  public init(
    apiToken: String,
    host: String = Defaults.host,
    timeoutInterval: TimeInterval = Defaults.timeoutInterval,
    model: String = Defaults.model,
    maxQueueSize: Int = Defaults.maxQueueSize,
    maxConcurrentRequests: Int = Defaults.maxConcurrentRequests
  ) {
    self.apiToken = apiToken
    self.host = host
    self.timeoutInterval = timeoutInterval
    self.model = model
    self.maxQueueSize = maxQueueSize
    self.maxConcurrentRequests = maxConcurrentRequests
  }
}
