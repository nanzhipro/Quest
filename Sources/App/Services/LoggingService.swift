//
//  LoggingService.swift
//  VaporApp
//
//  Created by CursorAI on 2024-03-20.
//

import Logging
import Vapor

/// 定义日志服务的配置选项
public struct LoggingConfiguration {
  public let label: String
  public let metadata: Logger.Metadata

  public init(
    label: String,
    metadata: Logger.Metadata = [:]
  ) {
    self.label = label
    self.metadata = metadata
  }
}

/// 统一的日志服务协议
public protocol LoggingServiceProtocol {
  /// 记录调试级别的日志
  func debug(_ message: String, metadata: Logger.Metadata?, source: String)

  /// 记录信息级别的日志
  func info(_ message: String, metadata: Logger.Metadata?, source: String)

  /// 记录警告级别的日志
  func warning(_ message: String, metadata: Logger.Metadata?, source: String)

  /// 记录错误级别的日志
  func error(_ message: String, metadata: Logger.Metadata?, source: String)

  /// 记录带有错误对象的错误级别日志
  func error(_ error: Error, message: String, metadata: Logger.Metadata?, source: String)

  /// 添加默认元数据
  func addDefaultMetadata(_ metadata: Logger.Metadata)
}

/// 日志服务实现
public final class LoggingService: LoggingServiceProtocol {
  private let logger: Logger
  private var defaultMetadata: Logger.Metadata

  public init(configuration: LoggingConfiguration) {
    let logger = Logger(label: configuration.label)
    self.defaultMetadata = configuration.metadata
    self.logger = logger
  }

  public func debug(_ message: String, metadata: Logger.Metadata? = nil, source: String) {
    let combinedMetadata = combineMetadata(metadata)
    logger.debug("\(message)", metadata: combinedMetadata, source: source)
  }

  public func info(_ message: String, metadata: Logger.Metadata? = nil, source: String) {
    let combinedMetadata = combineMetadata(metadata)
    logger.info("\(message)", metadata: combinedMetadata, source: source)
  }

  public func warning(_ message: String, metadata: Logger.Metadata? = nil, source: String) {
    let combinedMetadata = combineMetadata(metadata)
    logger.warning("\(message)", metadata: combinedMetadata, source: source)
  }

  public func error(_ message: String, metadata: Logger.Metadata? = nil, source: String) {
    let combinedMetadata = combineMetadata(metadata)
    logger.error("\(message)", metadata: combinedMetadata, source: source)
  }

  public func error(
    _ error: Error, message: String, metadata: Logger.Metadata? = nil, source: String
  ) {
    var errorMetadata: Logger.Metadata = [
      "error": "\(error)",
      "localizedDescription": "\(error.localizedDescription)",
    ]
    if let metadata = metadata {
      errorMetadata.merge(metadata) { (_, new) in new }
    }
    let combinedMetadata = combineMetadata(errorMetadata)
    logger.error("\(message)", metadata: combinedMetadata, source: source)
  }

  public func addDefaultMetadata(_ metadata: Logger.Metadata) {
    defaultMetadata.merge(metadata) { (_, new) in new }
  }

  private func combineMetadata(_ metadata: Logger.Metadata?) -> Logger.Metadata {
    guard let metadata = metadata else {
      return defaultMetadata
    }
    var combined = defaultMetadata
    combined.merge(metadata) { (_, new) in new }
    return combined
  }
}

// MARK: - Application Extension
extension Application {
  private struct LoggingServiceKey: StorageKey {
    public typealias Value = LoggingServiceProtocol
  }

  public var log: LoggingServiceProtocol {
    get {
      guard let service = storage[LoggingServiceKey.self] else {
        let configuration = LoggingConfiguration(
          label: "app.vapor",
          metadata: ["app": .string("VaporApp")]
        )
        let service = LoggingService(configuration: configuration)
        storage[LoggingServiceKey.self] = service
        return service
      }
      return service
    }
    set {
      storage[LoggingServiceKey.self] = newValue
    }
  }
}

// MARK: - Request Extension
extension Request {
  public var log: LoggingServiceProtocol {
    application.log
  }
}
