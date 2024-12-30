import Foundation
import OpenAI
import Vapor

public final class TencentHunyuanOpenAIProvider: LLMProvider {
    
    public let name = "TencentHunyuanOpenAI"
    public let supportedModels = ["hunyuan-lite"]
    
  private let openAI: OpenAI
  private let configuration: TencentHunyuanOpenAIConfig
  private let requestQueue: RequestQueue
  private let semaphore: AsyncSemaphore
  private var activeRequestCount: Int
  private var requestCounter: Int = 0
  let app: Application

  init(config: TencentHunyuanOpenAIConfig, app: Application) {
    self.configuration = config
    self.app = app

    self.requestQueue = RequestQueue(maxQueueSize: configuration.maxQueueSize)
    self.semaphore = AsyncSemaphore(value: configuration.maxConcurrentRequests)
    self.activeRequestCount = 0

    let openAIConfig = OpenAI.Configuration(
      token: configuration.apiToken,
      host: configuration.host,
      timeoutInterval: configuration.timeoutInterval
    )

    self.openAI = OpenAI(configuration: openAIConfig)
  }
  
  public func execute(_ request: LLMRequest) async throws -> LLMResponse {
      let responseContent = try await chat(request.messages[0].content, priority: 0)
      return LLMResponse(content: responseContent, requestId: UUID().uuidString)
  }
    
    public func validateConfig(_ config: LLMConfig) -> Bool {
        return true
    }

  /// 处理队列中的请求
  /// 这是一个长期运行的任务，会持续处理队列中的请求直到队列为空
  /// - Note: 该方法会在后台持续运行，直到队列为空才会返回
  /// - Important: 此方法应该在 Task 中调用，以避免阻塞主线程
  private func processQueuedRequests() async {
    print("🔄 Starting queue processor")
    while true {
      guard let request = await requestQueue.dequeue() else {
        print("📭 Queue empty, processor stopped")
        return
      }

      print("📦 Processing next queued request")
      Task {
        do {
          _ = try await request.operation()
          print("✅ Queued request completed successfully")
        } catch {
          print("❌ Queued request failed: \(error)")
        }
      }

      await Task.yield()
    }
  }

  // MARK: - Public Methods

  /// 发送单次聊天请求
  ///
  /// 该方法向腾讯混元 AI 发送单次对话请求，支持请求优先级设置和自动队列管理。
  ///
  /// - Parameters:
  ///   - message: 用户输入的消息文本
  ///   - priority: 请求优先级，数值越大优先级越高，默认为 0
  /// - Returns: AI 的响应文本
  /// - Throws: 可能抛出以下错误：
  ///   - ``TencentHunyuanOpenAIError/noResponse``：未收到有效响应
  ///   - ``TencentHunyuanOpenAIError/invalidConfiguration``：配置无效
  ///   - ``TencentHunyuanOpenAIError/queueFull``：请求队列已满
  ///   - ``TencentHunyuanOpenAIError/requestTimeout``：请求超时
  ///   - ``TencentHunyuanOpenAIError/requestCancelled``：请求被取消
  ///
  /// ## 示例
  /// ```swift
  /// // 发送普通请求
  /// let response = try await client.chat("你好")
  ///
  /// // 发送高优先级请求
  /// let response = try await client.chat("紧急问题", priority: 10)
  /// ```
  public func chat(_ message: String, priority: Int = 0) async throws -> String {
    let requestId = getNextRequestId()
    print("🚀 [\(requestId)] New request initiated: \(message.prefix(50))...")

    let operation: () async throws -> String = { [weak self] in
      guard let self: TencentHunyuanOpenAIProvider = self else { throw TencentHunyuanOpenAIError.invalidConfiguration }

      await self.incrementActiveRequests()
      print("📈 [\(requestId)] Active requests: \(await self.activeRequestCount)")

      let model = await self.configuration.model

      defer {
        Task.detached {
          await self.decrementActiveRequests()
        }
      }

      let query = ChatQuery(
        messages: [.init(role: .user, content: message)!],
        model: model
      )

      let result = try await self.openAI.chats(query: query)
      guard let response = result.choices.first?.message.content else {
        throw TencentHunyuanOpenAIError.noResponse
      }

      print("✅ [\(requestId)] Request completed successfully")
      return String(describing: response)
    }

    if activeRequestCount >= configuration.maxConcurrentRequests {
      print("⏳ [\(requestId)] Max concurrent requests reached, queueing")
      let queuedRequest = RequestQueue.QueuedRequest(priority: priority, operation: operation)
      try await requestQueue.enqueue(queuedRequest)
      print("📥 [\(requestId)] Request queued successfully")

      Task {
        await processQueuedRequests()
      }

      print("🔒 [\(requestId)] Waiting for semaphore...")
      await semaphore.wait()
      print("🔓 [\(requestId)] Semaphore acquired")
    }

    defer {
      Task {
        await semaphore.signal()
        print("📤 [\(requestId)] Semaphore released")
      }
    }
    return try await operation()
  }

  /// 发送流式聊天请求，支持实时获取 AI 的响应
  /// - Parameter message: 用户输入的消息文本
  /// - Returns: 异步字符串流，每个元素代表 AI 响应的一个片段
  /// - Note: 流式响应不支持请求队列和并发限制
  /// - Important: 使用 for-await-in 循环处理响应流
  ///
  /// 使用示例:
  /// ```swift
  /// for try await response in tencentHunYuan.chatStream("你好") {
  ///     print(response) // 处理每个响应片段
  /// }
  /// ```
  public func chatStream(_ message: String) -> AsyncThrowingStream<String, Error> {
    let requestId = getNextRequestId()

    return AsyncThrowingStream { continuation in
      Task {
        do {
          print("🚀 [\(requestId)] Starting stream request: \(message.prefix(50))...")

          let query = ChatQuery(
            messages: [.init(role: .user, content: message)!],
            model: configuration.model
          )

          for try await result in openAI.chatsStream(query: query) {
            if let content = result.choices.first?.delta.content {
              continuation.yield(content)
            }
          }

          print("✅ [\(requestId)] Stream completed successfully")
          continuation.finish()
        } catch {
          print("❌ [\(requestId)] Stream failed: \(error)")
          continuation.finish(throwing: error)
        }
      }
    }
  }

  /// 增加活动请求计数
  /// - Important: 此方法会自动记录日志
  private func incrementActiveRequests() {
    activeRequestCount += 1
    print("⬆️ Active requests increased to: \(activeRequestCount)")
  }

  /// 减少活动请求计数
  /// - Note: 当活动请求数低于最大并发数，会触发队列处理器
  /// - Important: 此方法会自动记录日志
  private func decrementActiveRequests() {
    activeRequestCount -= 1
    print("⬇️ Active requests decreased to: \(activeRequestCount)")
    if activeRequestCount < configuration.maxConcurrentRequests {
      print("🔄 Queue processor check triggered")
      Task {
        await processQueuedRequests()
      }
    }
  }

  /// 生成下一个请求 ID
  /// - Returns: 递增的整数 ID
  /// - Important: 此方法是线程安全的，因为它在 actor 内部运行
  private func getNextRequestId() -> Int {
    requestCounter += 1
    return requestCounter
  }
}

/// 异步信号量实现
/// 用于控制并发访问的计数信号量
private actor AsyncSemaphore {
  private var value: Int
  private var waiters: [CheckedContinuation<Void, Never>] = []

  init(value: Int) {
    self.value = value
  }

  /// 等待获取信号量
  /// - Note: 如果当前没有可用的信号量，调用者将被挂起直到有信号量可用
  /// - Important: 此方法会自动记录信号量状态变化
  func wait() async {
    print("🚦 Semaphore wait requested (current value: \(value))")
    if value > 0 {
      value -= 1
      print("✅ Semaphore acquired (new value: \(value))")
      return
    }

    print("⏳ Insufficient semaphore value, joining wait queue")
    await withCheckedContinuation { continuation in
      waiters.append(continuation)
    }
  }

  /// 释放信号量
  /// - Note: 如果有等待的请求会立即唤醒一个等待者
  ///         否则增加信号量的值
  /// - Important: 此方法会自动记录信号量状态变化
  func signal() {
    if let waiter = waiters.first {
      waiters.removeFirst()
      print("🔔 Resuming waiting request (queue length: \(waiters.count))")
      waiter.resume()
    } else {
      value += 1
      print("⬆️ Semaphore value increased to: \(value)")
    }
  }
}
