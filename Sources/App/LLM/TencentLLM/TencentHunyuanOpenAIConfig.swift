import Foundation

/// 腾讯混元OpenAI客户端配置
///
/// ## Overview
/// 包含初始化腾讯混元客户端所需的所有配置参数，支持自定义 API 主机、超时时间、
/// 模型选择以及并发控制参数。
///
/// ## Topics
/// ### 必需参数
/// - ``apiToken``
///
/// ### 可选参数
/// - ``host``
/// - ``timeoutInterval``
/// - ``model``
/// - ``maxQueueSize``
/// - ``maxConcurrentRequests``
///
/// ## 示例
/// ### 基本配置
/// ```swift
/// let config = TencentHunyuanOpenAIConfig(apiToken: "your-token")
/// ```
///
/// ### 完整配置
/// ```swift
/// let config = TencentHunyuanOpenAIConfig(
///     apiToken: "your-token",
///     host: "custom.api.host",
///     timeoutInterval: 60,
///     model: "custom-model",
///     maxQueueSize: 200,
///     maxConcurrentRequests: 20
/// )
/// ```
public struct TencentHunyuanOpenAIConfig {
  /// API Token
  public let apiToken: String
  /// API 主机地址
  public let host: String
  /// 请求超时时间
  public let timeoutInterval: TimeInterval
  /// AI 模型名称
  public let model: String
  /// 最大队列大小
  public let maxQueueSize: Int
  /// 最大并发请求数
  public let maxConcurrentRequests: Int

  /// 创建配置
  public init(
    apiToken: String,
    host: String = "api.hunyuan.cloud.tencent.com",
    timeoutInterval: TimeInterval = 60,
    model: String = "hunyuan-lite",
    maxQueueSize: Int = 100,
    maxConcurrentRequests: Int = 10
  ) {
    self.apiToken = apiToken
    self.host = host
    self.timeoutInterval = timeoutInterval
    self.model = model
    self.maxQueueSize = maxQueueSize
    self.maxConcurrentRequests = maxConcurrentRequests
  }
}
