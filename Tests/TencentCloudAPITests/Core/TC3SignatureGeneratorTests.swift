//
//  TC3SignatureGeneratorTests.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import XCTest
import Crypto
@testable import TencentCloudAPI

final class TC3SignatureGeneratorTests: XCTestCase {
    
    // 测试HMAC计算
    func testHMAC256Calculation() throws {
        let generator = TC3SignatureGenerator(
            secretId: "test-id",
            secretKey: "test-key"
        )
        
        let key = "TC3test-key".data(using: .utf8)!
        let message = "2019-02-25".data(using: .utf8)!
        
        let hmacResult = try generator.hmac256(key: key, message: message)
        
        XCTAssertFalse(hmacResult.isEmpty)
    }
    
    // 测试SHA256哈希计算
    func testSHA256Calculation() throws {
        let generator = TC3SignatureGenerator(
            secretId: "test-id",
            secretKey: "test-key"
        )
        
        let message = "This is a test message"
        let result = try generator.sha256Hex(message)
        
        // SHA256("This is a test message") = "6f3438001129a90c5b1637928bf38bf26e39e57c6e9511005682048bedbef906"
        XCTAssertEqual(result, "6f3438001129a90c5b1637928bf38bf26e39e57c6e9511005682048bedbef906")
    }
    
    // 测试规范请求串构建
    func testCanonicalRequestConstruction() throws {
        let generator = TC3SignatureGenerator(
            secretId: "test-id",
            secretKey: "test-key"
        )
        
        let requestInfo = TC3RequestInfo(
            httpMethod: "POST",
            canonicalURI: "/",
            canonicalQueryString: "",
            canonicalHeaders: "content-type:application/json; charset=utf-8\nhost:asr.tencentcloudapi.com\nx-tc-action:sentencerecognition\n",
            signedHeaders: "content-type;host;x-tc-action",
            requestPayload: "{\"Limit\": 1, \"Filters\": [{\"Values\": [\"\\u672a\\u547d\\u540d\"], \"Name\": \"instance-name\"}]}"
        )
        
        let canonicalRequest = try generator.constructCanonicalRequest(requestInfo: requestInfo)
        let expectedRequest = """
        POST
        /

        content-type:application/json; charset=utf-8
        host:asr.tencentcloudapi.com
        x-tc-action:sentencerecognition

        content-type;host;x-tc-action
        35e9c5b0e3ae67532d3c9f17ead6c90222632e5b1ff7f6e89887f1398934f064
        """
        
        // 规范请求串应匹配预期的请求
        XCTAssertEqual(canonicalRequest, expectedRequest)
    }
    
    // 测试待签名字符串构建
    func testStringToSignConstruction() throws {
        let generator = TC3SignatureGenerator(
            secretId: "test-id",
            secretKey: "test-key"
        )
        
        let timestamp = 1551113065
        let date = "2019-02-25"
        let service = "asr"
        let canonicalRequest = """
        POST
        /

        content-type:application/json; charset=utf8
        host:asr.tencentcloudapi.com
        x-tc-action:sentencerecognition

        content-type;host;x-tc-action
        35e9c5b0e3ae67532d3c9f17ead6c90222632e5b1ff7f6e89887f1398934f064
        """
        
        let stringToSign = try generator.constructStringToSign(timestamp: timestamp, date: date, service: service, canonicalRequest: canonicalRequest)
        
        let expectedStringToSign = """
        TC3-HMAC-SHA256
        1551113065
        2019-02-25/asr/tc3_request
        e0a42715a30904d6ccd495fb9310d8ea1547390c61a633d28bd011b99a73acfa
        """
        
        // 待签名字符串应匹配预期的字符串
        XCTAssertEqual(stringToSign, expectedStringToSign)
    }
    
    // 测试完整签名过程
    func testCompleteSignatureProcess() throws {
        let secretId = "AKID********************************"
        let secretKey = "********************************"
        
        let generator = TC3SignatureGenerator(
            secretId: secretId,
            secretKey: secretKey
        )
        
        let timestamp = 1551113065
        let date = "2019-02-25"
        let service = "asr"
        
        let requestInfo = TC3RequestInfo(
            httpMethod: "POST",
            canonicalURI: "/",
            canonicalQueryString: "",
            canonicalHeaders: "content-type:application/json; charset=utf-8\nhost:asr.tencentcloudapi.com\nx-tc-action:sentencerecognition\n",
            signedHeaders: "content-type;host;x-tc-action",
            requestPayload: "{\"Limit\": 1, \"Filters\": [{\"Values\": [\"\\u672a\\u547d\\u540d\"], \"Name\": \"instance-name\"}]}"
        )
        
        let signature = try generator.generateSignature(
            service: service,
            timestamp: timestamp,
            date: date,
            requestInfo: requestInfo
        )
        
        // 签名不应为空
        XCTAssertFalse(signature.isEmpty)
        
        // 创建验证工具检查签名的格式是否正确
        let regex = try NSRegularExpression(pattern: "^[0-9a-f]{64}$", options: [])
        let matches = regex.matches(in: signature, options: [], range: NSRange(location: 0, length: signature.utf8.count))
        
        // 签名应该是64个十六进制字符
        XCTAssertEqual(matches.count, 1)
    }
    
    // 测试授权头部构建
    func testAuthorizationHeaderConstruction() throws {
        let secretId = "AKID********************************"
        let secretKey = "********************************"
        
        let generator = TC3SignatureGenerator(
            secretId: secretId,
            secretKey: secretKey
        )
        
        let date = "2019-02-25"
        let service = "asr"
        let signedHeaders = "content-type;host;x-tc-action"
        let signature = "10b1a37a7301a02ca19a647ad722d5e43b4b3cff309d421d85b46093f6ab6c4f"
        
        let authorizationHeader = generator.constructAuthorizationHeader(
            date: date,
            service: service,
            signedHeaders: signedHeaders,
            signature: signature
        )
        
        let expectedHeader = "TC3-HMAC-SHA256 Credential=AKID********************************/2019-02-25/asr/tc3_request, SignedHeaders=content-type;host;x-tc-action, Signature=10b1a37a7301a02ca19a647ad722d5e43b4b3cff309d421d85b46093f6ab6c4f"
        
        // 授权头部应匹配预期的格式
        XCTAssertEqual(authorizationHeader, expectedHeader)
    }
} 