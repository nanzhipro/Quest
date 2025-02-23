//
//  main.swift
//  RevenueCatSignatureCLI
//
//  Created by CursorAI on 2024-03-21.
//

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

// MARK: - 签名生成器
enum RevenueCatSignatureGenerator {
    static func generateSignature(jsonString: String, secret: String) throws -> String {
        let secretData = Data(secret.utf8)
        let messageData = Data(jsonString.utf8)
        
        #if canImport(CryptoKit)
        let hmac = HMAC<SHA256>.authenticationCode(for: messageData, using: SymmetricKey(data: secretData))
        return Data(hmac).map { String(format: "%02x", $0) }.joined()
        #else
        let hmac = HMAC<SHA256>.authenticationCode(for: messageData, using: SymmetricKey(data: secretData))
        return Data(hmac).map { String(format: "%02x", $0) }.joined()
        #endif
    }
    
    enum SignatureError: Error {
        case missingArguments
        case fileError
    }
}

// MARK: - 命令行参数处理
struct CommandLineArgs {
    let jsonPath: String
    let secret: String
    let isJsonString: Bool
    
    static func parse() throws -> CommandLineArgs {
        let args = Array(CommandLine.arguments.dropFirst())
        
        // 显示帮助信息
        if args.isEmpty || args.contains("-h") || args.contains("--help") {
            printHelp()
            exit(0)
        }
        
        var jsonPath = ""
        var secret = ""
        var isJsonString = false
        
        var i = 0
        while i < args.count {
            switch args[i] {
            case "-j", "--json":
                i += 1
                guard i < args.count else { throw RevenueCatSignatureGenerator.SignatureError.missingArguments }
                jsonPath = args[i]
                isJsonString = true
            case "-f", "--file":
                i += 1
                guard i < args.count else { throw RevenueCatSignatureGenerator.SignatureError.missingArguments }
                jsonPath = args[i]
            case "-s", "--secret":
                i += 1
                guard i < args.count else { throw RevenueCatSignatureGenerator.SignatureError.missingArguments }
                secret = args[i]
            default:
                printHelp()
                exit(1)
            }
            i += 1
        }
        
        guard !jsonPath.isEmpty && !secret.isEmpty else {
            throw RevenueCatSignatureGenerator.SignatureError.missingArguments
        }
        
        return CommandLineArgs(jsonPath: jsonPath, secret: secret, isJsonString: isJsonString)
    }
    
    static func printHelp() {
        print("""
        RevenueCat Webhook 签名生成工具

        用法:
            revenuecat-sign (-j|--json) '<JSON字符串>' (-s|--secret) <密钥>
            revenuecat-sign (-f|--file) <JSON文件路径> (-s|--secret) <密钥>

        选项:
            -j, --json    直接输入JSON字符串（保持原始格式，包括空格和换行）
            -f, --file    指定包含原始JSON的文件路径
            -s, --secret  RevenueCat Webhook密钥
            -h, --help    显示帮助信息

        注意:
            - JSON字符串必须与RevenueCat发送的原始格式完全一致
            - 使用单引号包裹JSON字符串以保留格式
            - 文件内容应该是原始JSON，不会进行重新格式化

        示例:
            revenuecat-sign -j '{"event":{"type":"INITIAL_PURCHASE"}}' -s your_secret
            revenuecat-sign -f webhook.json -s your_secret
        """)
    }
}

// MARK: - 主程序
do {
    let args = try CommandLineArgs.parse()
    
    let jsonString: String
    if args.isJsonString {
        // 直接使用JSON字符串
        jsonString = args.jsonPath
    } else {
        // 从文件读取JSON字符串
        guard let fileContents = try? String(contentsOfFile: args.jsonPath, encoding: .utf8) else {
            throw RevenueCatSignatureGenerator.SignatureError.fileError
        }
        jsonString = fileContents
    }
    
    let signature = try RevenueCatSignatureGenerator.generateSignature(
        jsonString: jsonString,
        secret: args.secret
    )
    
    print("X-RevenueCat-Signature: \(signature)")
    
} catch RevenueCatSignatureGenerator.SignatureError.missingArguments {
    print("错误: 缺少必要的参数")
    CommandLineArgs.printHelp()
    exit(1)
} catch RevenueCatSignatureGenerator.SignatureError.fileError {
    print("错误: 无法读取JSON文件")
    exit(1)
} catch {
    print("错误: \(error.localizedDescription)")
    exit(1)
} 