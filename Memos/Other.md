# 除 DevOps，Security，Client 之外的重要备忘，记录于此


# RevenueCat Webhook 配置指南

## 配置步骤

1. 登录 RevenueCat Dashboard
2. 进入 Project Settings > Integrations
3. 找到 Webhooks 部分
4. 点击 "Add Webhook"
5. 配置 Webhook：
   - URL: https://your-domain.com/webhooks/revenuecat
   - 选择需要的事件类型
   - 保存生成的签名密钥

## 环境变量配置

```plaintext
REVENUECAT_WEBHOOK_SECRET=your_webhook_signing_secret_here
```

## 安全建议

- 使用环境变量存储密钥
- 开发和生产环境使用不同密钥
- 实现适当的日志记录
- 监控 Webhook 调用状态 

## RevenueCat Webhook 签名生成工具

用于生成 RevenueCat Webhook 签名的工具函数，可用于测试和调试。

### 使用方法

```swift
// 使用 JSON 字符串
let signature = try RevenueCatSignatureGenerator.generateSignature(
    jsonBody: jsonString,
    secret: "your_webhook_secret"
)

// 使用字典
let signature = try RevenueCatSignatureGenerator.generateSignature(
    jsonBody: eventDict,
    secret: "your_webhook_secret"
)
```

生成的签名可用于：
- 测试 Webhook 端点
- 验证签名计算逻辑
- 模拟 RevenueCat 请求 

## RevenueCat Webhook 签名生成工具 (CLI)

命令行工具用于生成 RevenueCat Webhook 签名。

### 安装

```bash
git clone <your-repo>
cd <your-repo>
swift build
```

### 使用方法

1. 使用 JSON 字符串：
```bash
swift run revenuecat-sign -j '{"event":{"type":"INITIAL_PURCHASE"}}' -s your_secret
```

2. 使用 JSON 文件：
```bash
swift run revenuecat-sign -f webhook.json -s your_secret
```

3. 查看帮助：
```bash
swift run revenuecat-sign --help
``` 