//
//  LLMConfiguration.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

/// LLM 提供者配置协议
public protocol LLMProviderConfig: Sendable {
    /// 提供者标识
    var identifier: String { get }
    /// 验证配置是否有效
    func validate() throws
}

/// LLM 配置管理器
public final class LLMConfiguration {
    public static let shared = LLMConfiguration()
    
    private enum Constants {
        static let source = "LLMConfiguration"
    }
    
    private let logger: Logger
    private var providers: [String: any LLMProvider]
    private var activeProvider: (any LLMProvider)?
    
    private init() {
        self.logger = Logger(label: Constants.source)
        self.providers = [:]
    }
}

// MARK: - Public Methods
public extension LLMConfiguration {
    /// 注册 LLM 提供者
    func register(provider: any LLMProvider, isActive: Bool = false, app: Application) {
        log(.debug, "Registering provider", [
            "provider": provider.name,
            "isActive": String(isActive)
        ])
        
        providers[provider.name] = provider
        
        if isActive {
            activeProvider = provider
            log(.info, "Set active provider", ["provider": provider.name])
        }
    }
    
    /// 获取指定的 LLM 提供者
    func getProvider(name: String) throws -> any LLMProvider {
        guard let provider = providers[name] else {
            throw logError(.providerNotFound, ["provider": name])
        }
        
        log(.debug, "Retrieved provider", [
            "provider": provider.name,
            "models": provider.supportedModels.joined(separator: ", ")
        ])
        
        return provider
    }
    
    /// 获取当前活跃的 LLM 提供者
    func getProvider() throws -> any LLMProvider {
        guard let provider = activeProvider else {
            throw logError(.providerNotFound, ["error": "No active provider"])
        }
        return provider
    }
    
    /// 设置活跃的 LLM 提供者
    func setActiveProvider(name: String, app: Application) throws {
        let provider = try getProvider(name: name)
        activeProvider = provider
        log(.info, "Changed active provider", ["provider": provider.name])
    }
    
    /// 移除 LLM 提供者
    func removeProvider(name: String, app: Application) {
        providers.removeValue(forKey: name)
        
        if activeProvider?.name == name {
            activeProvider = nil
            log(.warning, "Removed active provider", ["provider": name])
        }
        
        log(.info, "Removed provider", ["provider": name])
    }
}

// MARK: - Private Methods
private extension LLMConfiguration {
    /// 记录日志事件
    func log(_ level: Logger.Level, _ message: String, _ context: [String: String]) {
        var metadata: Logger.Metadata = [:]
        context.forEach { metadata[$0.key] = .string($0.value) }
        logger.log(level: level, .init(stringLiteral: message), metadata: metadata, source: Constants.source)
    }
    
    /// 记录错误并返回
    func logError(_ error: LLMError, _ context: [String: String]) -> LLMError {
        var metadata: Logger.Metadata = [:]
        context.forEach { metadata[$0.key] = .string($0.value) }
        logger.error(.init(stringLiteral: error.localizedDescription), metadata: metadata, source: Constants.source)
        return error
    }
}
