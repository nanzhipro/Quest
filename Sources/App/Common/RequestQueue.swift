import Foundation

/// 异步请求队列
///
/// 一个支持优先级的异步请求队列实现，用于管理并发请求。队列中的请求按优先级排序，
/// 同优先级的请求按照先进先出（FIFO）原则处理。
///
/// ## Overview
/// RequestQueue 使用 actor 实现以确保线程安全，支持以下功能：
/// - 基于优先级的请求排序
/// - 队列大小限制
/// - 异步入队和出队操作
///
/// ## Topics
/// ### 类型
/// - ``QueuedRequest``
///
/// ### 操作
/// - ``enqueue(_:)``
/// - ``dequeue()``
/// - ``count``
///
/// ## 示例
/// ```swift
/// let queue = RequestQueue(maxQueueSize: 100)
///
/// // 创建请求
/// let request = QueuedRequest(priority: 1) {
///     // 异步操作
///     return "结果"
/// }
///
/// // 入队
/// try await queue.enqueue(request)
///
/// // 出队
/// if let request = await queue.dequeue() {
///     let result = try await request.operation()
/// }
/// ```
actor RequestQueue {
  /// 表示队列中的一个请求
  ///
  /// 每个请求包含一个唯一标识符、优先级、时间戳和异步操作。
  /// 优先级越高的请求会被优先处理，同优先级的请求按照时间戳顺序处理。
  struct QueuedRequest: Identifiable {
    /// 请求的唯一标识符
    let id: UUID

    /// 请求的优先级，数值越大优先级越高
    let priority: Int

    /// 请求创建的时间戳
    let timestamp: Date

    /// 要执行的异步操作
    let operation: () async throws -> String

    /// 创建一个新的队列请求
    /// - Parameters:
    ///   - priority: 请求的优先级，默认为 0
    ///   - operation: 要执行的异步操作
    init(priority: Int = 0, operation: @escaping () async throws -> String) {
      self.id = UUID()
      self.priority = priority
      self.timestamp = Date()
      self.operation = operation
    }
  }

  /// 存储请求的内部队列
  private var queue: [QueuedRequest]

  /// 队列的最大容量
  private let maxQueueSize: Int

  /// 创建一个新的请求队列
  /// - Parameter maxQueueSize: 队列的最大容量，默认为 100
  init(maxQueueSize: Int = 100) {
    self.queue = []
    self.maxQueueSize = maxQueueSize
  }

  /// 将请求添加到队列中
  /// - Parameter request: 要添加的请求
  /// - Throws: ``TencentHunYuanError/queueFull`` 当队列已满时
  /// - Note: 请求会按照优先级排序，同优先级的请求按照时间戳顺序排序
  func enqueue(_ request: QueuedRequest) throws {
    guard queue.count < maxQueueSize else {
        throw TencentHunyuanOpenAIError.queueFull
    }

    // 按优先级和时间戳排序
    let insertIndex = queue.firstIndex { $0.priority < request.priority } ?? queue.endIndex
    queue.insert(request, at: insertIndex)
  }

  /// 从队列中取出下一个要处理的请求
  /// - Returns: 下一个要处理的请求，如果队列为空则返回 nil
  /// - Note: 返回的请求会从队列中移除
  func dequeue() -> QueuedRequest? {
    return queue.isEmpty ? nil : queue.removeFirst()
  }

  /// 当前队列中的请求数量
  var count: Int {
    queue.count
  }
}
