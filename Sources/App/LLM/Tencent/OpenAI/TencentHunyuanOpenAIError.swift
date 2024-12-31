import Foundation

/// 腾讯混元 OpenAI 客户端错误类型
///
/// ## Overview
/// 定义了在使用腾讯混元 OpenAI 时可能遇到的各种错误情况。
///
/// ## Topics
/// ### 错误类型
/// - ``noResponse``
/// - ``invalidConfiguration``
/// - ``queueFull``
/// - ``requestTimeout``
/// - ``requestCancelled``
///
/// ## 示例
/// ```swift
/// do {
///     let response = try await client.chat("你好")
/// } catch TencentHunyuanOpenAIError.noResponse {
///     print("未收到 AI 响应")
/// } catch TencentHunyuanOpenAIError.queueFull {
///     print("请求队列已满")
/// } catch {
///     print("其他错误：\(error)")
/// }
/// ```
public enum TencentHunyuanOpenAIError: LocalizedError {
  /// AI 未返回有效响应
  case noResponse
  /// 客户端配置无效
  case invalidConfiguration
  /// 请求队列已满
  case queueFull
  /// 请求超时
  case requestTimeout
  /// 请求被取消
  case requestCancelled

  public var errorDescription: String? {
    switch self {
    case .noResponse:
      return "未收到有效的响应"
    case .invalidConfiguration:
      return "配置无效"
    case .queueFull:
      return "请求队列已满"
    case .requestTimeout:
      return "请求超时"
    case .requestCancelled:
      return "请求已取消"
    }
  }
}
