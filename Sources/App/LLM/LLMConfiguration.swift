//
//  LLMConfiguration.swift
//  Quest
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import Vapor

/// LLM 提供者配置协议
public protocol LLMProviderConfig {
    /// 提供者标识
    var identifier: String { get }
    /// 验证配置是否有效
    func validate() -> Bool
}

/// LLM 配置管理器
public final class LLMConfiguration {
    public static let shared = LLMConfiguration()
    private let source = "LLMConfiguration"
    
    /// 已注册的提供者映射
    private var providers: [String: any LLMProvider] = [:]
    /// 当前活跃的提供者
    private var activeProvider: (any LLMProvider)?
    
    private init() {}
    
    /// 注册 LLM 提供者
    /// - Parameters:
    ///   - provider: LLM 提供者实例
    ///   - isActive: 是否设置为活跃提供者
    public func register(
        provider: any LLMProvider,
        isActive: Bool = false,
        app: Application
    ) {
        app.logger.debug(
            "Registering LLM provider",
            metadata: [
                "provider": .string(provider.name),
                "isActive": .string(String(isActive))
            ],
            source: source
        )
        
        providers[provider.name] = provider
        
        if isActive {
            activeProvider = provider
            app.logger.info(
                "Set active LLM provider",
                metadata: ["provider": .string(provider.name)],
                source: source
            )
        }
    }
    
    /// 获取指定的 LLM 提供者
    /// - Parameter name: 提供者名称
    /// - Returns: LLM 提供者实例
    public func getProvider(name: String) throws -> any LLMProvider {
        guard let provider = providers[name] else {
            let error = LLMError.providerNotFound
            Logger(label: source).error(
                "Provider not found",
                metadata: [
                    "provider": .string(name),
                    "error": .string(String(describing: error))
                ]
            )
            throw error
        }
        
        Logger(label: source).debug(
            "Retrieved LLM provider",
            metadata: [
                "provider": .string(provider.name),
                "supportedModels": .string(provider.supportedModels.joined(separator: ", "))
            ]
        )
        
        return provider
    }
    
    /// 获取当前活跃的 LLM 提供者
    public func getActiveProvider() throws -> any LLMProvider {
        guard let provider = activeProvider else {
            let error = LLMError.providerNotFound
            Logger(label: source).error(
                "No active provider configured",
                metadata: ["error": .string(String(describing: error))]
            )
            throw error
        }
        return provider
    }
    
    /// 设置活跃的 LLM 提供者
    public func setActiveProvider(name: String, app: Application) throws {
        let provider = try getProvider(name: name)
        activeProvider = provider
        
        app.logger.info(
            "Changed active LLM provider",
            metadata: ["provider": .string(provider.name)],
            source: source
        )
    }
    
    /// 移除 LLM 提供者
    public func removeProvider(name: String, app: Application) {
        providers.removeValue(forKey: name)
        
        if activeProvider?.name == name {
            activeProvider = nil
            app.logger.warning(
                "Removed active provider",
                metadata: ["provider": .string(name)],
                source: source
            )
        }
        
        app.logger.info(
            "Removed LLM provider",
            metadata: ["provider": .string(name)],
            source: source
        )
    }
    
    /// 获取当前活跃的 LLM 提供者
    public func getProvider() throws -> any LLMProvider {
        guard let provider = activeProvider else {
            let error = LLMError.providerNotFound
            Logger(label: source).error(
                "No active provider configured",
                metadata: ["error": .string(String(describing: error))]
            )
            throw error
        }
        return provider
    }
} 