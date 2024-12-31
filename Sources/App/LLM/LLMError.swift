import Foundation

/// LLM 错误类型
public enum LLMError: LocalizedError {
    case providerNotFound
    case invalidConfiguration(String)
    case invalidRequest
    case requestFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .providerNotFound:
            return "LLM provider not found"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .invalidRequest:
            return "Invalid request"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        }
    }
} 