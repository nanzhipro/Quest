# 高级功能访问控制安全指南

## 安全模型

高级功能访问控制系统基于以下安全模型：

1. **系统级控制**: 通过环境变量控制全局高级功能可用性
2. **设备级控制**: 通过设备UUID白名单实现细粒度访问控制
3. **时效性控制**: 通过过期机制限制临时访问权限
4. **多层验证**: 结合JWT认证确保API访问安全

## 潜在威胁与防护措施

### 1. 设备UUID伪造

**威胁**：
客户端应用伪造其他设备的UUID来获取未授权访问。

**防护措施**：

- 在客户端存储和使用设备UUID时采用钥匙串或其他安全存储方式
- 考虑结合其他设备标识符（如设备型号、iOS版本等）进行组合验证
- 对可疑的UUID请求模式实施监控和检测

### 2. API请求拦截与重放

**威胁**：
攻击者拦截有效的API请求并重放来获取访问权限。

**防护措施**：

- 使用HTTPS (TLS 1.2+)加密所有API通信
- 在JWT中包含有效期限（exp声明）并设置较短的令牌生命周期
- 实现请求重放保护（如使用nonce或时间戳）

### 3. 白名单数据泄露

**威胁**：
白名单数据库被未授权访问，导致设备信息泄露。

**防护措施**：

- 限制数据库访问权限，仅授权特定应用服务账户
- 对存储的UUID考虑进行哈希处理
- 实施数据库审计和异常活动监控

### 4. 管理API滥用

**威胁**：
管理API被攻击者利用添加未授权设备到白名单。

**防护措施**：

- 对管理API实施严格的认证和授权控制
- 要求管理操作使用特殊的管理员JWT令牌
- 为所有管理操作建立详细的审计日志
- 对管理操作实施IP地址限制或VPN访问要求

## JWT安全配置建议

为确保用于API认证的JWT令牌安全：

```swift
// 配置推荐
// 1. 使用强密钥 (至少256位)
app.jwt.signers.use(.hs256(key: AppEnvironment.jwtSecret))

// 2. 设置适当的Claims
struct SessionToken: JWTPayload {
    // 发行者
    var iss: IssuerClaim
    // 主题 (用户ID)
    var sub: SubjectClaim
    // 发行时间
    var iat: IssuedAtClaim
    // 过期时间 (建议1小时或更短)
    var exp: ExpirationClaim
    // 唯一标识符
    var jti: JWTIDClaim
    
    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}
```

## 客户端安全最佳实践

1. **设备标识符安全存储**:

   ```swift
   // 使用钥匙串安全存储UUID
   func secureStoreDeviceUUID(_ uuid: String) {
       let query: [String: Any] = [
           kSecClass as String: kSecClassGenericPassword,
           kSecAttrAccount as String: "DeviceUUID",
           kSecValueData as String: uuid.data(using: .utf8)!,
           kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
       ]
       SecItemDelete(query as CFDictionary)
       SecItemAdd(query as CFDictionary, nil)
   }
   ```

2. **安全的API调用**:
   - 使用App Transport Security (ATS)确保HTTPS安全
   - 实现证书锁定防止中间人攻击
   - 禁用不安全的HTTP缓存

3. **JWT令牌处理**:
   - 在客户端使用安全存储保存JWT
   - 检测令牌过期并及时刷新
   - 在应用退出或用户登出时清除令牌

## 应急响应策略

1. **怀疑设备白名单被滥用**:
   - 立即切换到全局设置模式 (`ENABLE_PREMIUM_FEATURES_WHEN_UNSUBSCRIBED=true`)
   - 重置整个白名单数据
   - 刷新所有管理JWT令牌

2. **发现API漏洞**:
   - 临时禁用相关端点
   - 实施必要的修复
   - 审核访问日志确定潜在影响

## 定期安全审查建议

1. 每季度审查白名单条目，移除不必要的设备访问权限
2. 每半年对API端点进行安全性审查和渗透测试
3. 定期轮换JWT签名密钥
4. 监控和分析API访问模式，检测异常行为
