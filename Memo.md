# SSL 证书管理最佳实践

## 目录结构

# Nginx 部署注意事项

## 目录结构

# 会员系统部署注意事项

## 安全配置

1. 确保所有密码都经过正确的哈希处理
2. 使用 HTTPS 加密所有通信
3. 实施速率限制以防止暴力攻击
4. 定期审计会员访问日志

## 数据库配置

1. 为会员表添加适当的索引（email, username）
2. 设置定期备份策略
3. 监控数据库性能
4. 实施数据库连接池

## 性能优化

1. 实施缓存策略（Redis 推荐）
2. 使用异步操作处理长时间运行的任务
3. 定期清理过期会员数据
4. 实施数据库查询优化

## 监控告警

1. 设置会员认证失败告警
2. 监控异常的会员行为
3. 设置系统性能监控
4. 实施日志聚合和分析

## 扩展性考虑

1. 使用微服务架构便于横向扩展
2. 实施消息队列处理异步任务
3. 使用 CDN 加速静态资源
4. 实施负载均衡策略

# 会员系统测试注意事项

## 测试环境配置

1. 使用独立的测试数据库
2. 每个测试前重置数据库状态
3. 确保测试环境的配置与生产环境一致

## 测试覆盖范围

1. API 端点功能测试
2. 数据验证测试
3. 认证和授权测试
4. 错误处理测试
5. 边缘情况测试

## 测试数据管理

1. 使用工厂方法创建测试数据
2. 确保测试数据的隔离性
3. 测试完成后清理数据
4. 避免测试间的数据依赖

## 性能测试考虑

1. 添加基准测试用例
2. 测试并发请求处理
3. 监控测试过程中的资源使用
4. 设置性能指标阈值

## CI/CD 集成

1. 在 CI 流程中运行所有测试
2. 设置测试覆盖率要求
3. 自动生成测试报告
4. 根据测试结果决定部署流程

# Swift 并发安全注意事项

## Model 类的并发安全

1. 使用 @unchecked Sendable 标注 Model 类
2. 确保所有属性的线程安全性
3. 依赖 Fluent 的并发安全保证
4. 注意自定义方法的并发安全

## 路由处理器的并发安全

1. 使用 @Sendable 标注异步路由处理器
2. 确保捕获的变量是并发安全的
3. 避免使用可变状态
4. 使用适当的同步机制

## 参数处理最佳实践

1. 始终验证和解包可选值
2. 使用 guard let 进行安全解包
3. 提供清晰的错误消息
4. 统一错误处理方式

# Fluent 查询最佳实践

## 过滤器语法

1. 使用标准三参数语法: .filter(\.$field, .operator, value)
2. �� 用比较运算符直接比较
3. 使用类型安全的字段路径
4. 正确处理可选值

## 查询优化

1. 使用适当的预加载关系
2. 添加必要的索引
3. 限制查询结果数量
4. 使用正确的查询条件

## 错误处理

1. 提供清晰的错误消息
2. 使用适当的 HTTP 状态码
3. 验证输入参数
4. 处理边缘情况

# Vapor 认证最佳实践

## 模型认证

1. 实现 Authenticatable 协议
2. 使用 ModelAuthenticatable 进行密码认证
3. 安全存储密码哈希
4. 实现安全的令牌生成

## 认证流程

1. 验证用户凭据
2. 检查账户状态
3. 生成安全令牌
4. 实现令牌刷新机制

## 安全考虑

1. 使用安全的密码哈希算法
2. 实现速率限制
3. 记录认证失败
4. 实现会话管理

# API 版本管理最佳实践

## 版本策略

1. 使用 URL 路径版本管理 (/api/v1/...)
2. 主版本号表示不兼容的 API 更改
3. 次版本号表示向后兼容的功能性新增
4. 修订号表示向后兼容的问题修复

## 版本管理原则

1. 保持旧版本 API 一段时间
2. 提供版本迁移指南
3. 在响应头中包含 API 版本信息
4. 记录 API 弃用时间表

## 路由组织

1. 按功能模块分组
2. 使用清晰的路由命名
3. 遵循 RESTful 设计原则
4. 保持路由结构一致性

## 向后兼容

1. 添加新字段而不是修改现有字段
2. 保持现有字段的数据类型
3. 不删除必填字段
4. 提供默认值处理

# 中间件最佳实践

## 设计原则

1. 单一职责原则
2. 清晰的错误处理
3. 完整的日志记录
4. 性能优化考虑

## 认证中间件

1. 验证令牌格式和有效性
2. 检查用户状态和权限
3. 记录认证尝试
4. 添加调试信息

## 错误处理

1. 提供明确的错误消息
2. 使用适当的状态码
3. 记录错误详情
4. 保护敏感信息

## 性能考虑

1. 避免不必要的数据库查询
2. 使用缓存减少延迟
3. 异步处理耗时操作
4. 监控中间件性能

# JWT 认证最佳实践

## 令牌设计

1. 包含必要的标准声明（sub, exp, iat）
2. 添加适当的自定义声明
3. 设置合理的过期时间
4. 实现令牌刷新机制

## 安全考虑

1. 使用强密钥并定期轮换
2. 实施令牌撤销机制
3. 验证所有必要的声明
4. 使用 HTTPS 传输令牌

## 性能优化

1. 合理设置令牌大小
2. 实现令牌缓存
3. 优化验证过程
4. 监控令牌使用情况

## 最佳实践

1. 使用环境变量存储密钥
2. 实现令牌刷新策略
3. 记录令牌操作日志
4. 提供令牌状态查询

# JWT 实现注意事项

## 依赖管理

1. 确 ��� 添加正确的 JWT 依赖
2. 使用兼容的版本号
3. 在目标中包含 JWT 产品
4. 检查依赖冲突

## API 使用

1. 使用正确的 JWT API（signers.sign/verify）
2. 处理所有可能的错误
3. 实现适当的错误恢复
4. 记录操作日志

## 类型安全

1. 将 DTO 定义移到适当的位置
2. 确保类型推断正确
3. 使用明确的类型注解
4. 避免隐式类型转换

# DTO 组织最佳实践

## 文件组织

1. 按功能模块分组 DTO
2. 避免类型重复定义
3. 使用清晰的命名约定
4. 添加适当的文档注释

## 类型设计

1. 使用专门的请求/响应类型
2. 实现必要的协议（如 Content）
3. 提供合适的初始化方法
4. 考虑类型的可扩展性

## 验证规则

1. 添加适当的验证规则
2. 实现自定义验证器
3. 提供清晰的错误消息
4. 处理所有边缘情况

# Docker 部署注意事项

## Nginx 服务启动检查清单

1. 确保以下目录和文件存在：

   - Docs/nginxconfig.io-tiwenlab.com/nginx.conf
   - Docs/nginxconfig.io-tiwenlab.com/conf.d/
   - Docs/ssl/ (或自定义 SSL 证书目录)
   - Public/

2. 启动命令顺序： `bash
docker compose build    # 构建镜像
docker compose up -d    # 启动所有服务   `

3. 故障排查命令： `bash
docker compose ps       # 查看服��状态
docker compose logs nginx  # 查看 nginx 日志
docker compose logs app    # 查看应用日志   `

4. 健康检查：
   - Nginx 服务每 30 秒进行一次配置测试
   - 应用服务每 30 秒检查一次健康状态

# Docker 部署故障排查

## 端口冲突解决方案

1. 检查端口占用： `bash
sudo lsof -i :<port>
sudo netstat -tulpn | grep <port>   `

2. 解决方案：

   - 停止冲突服务：`sudo systemctl stop <service>`
   - 修改端口映射：在 docker-compose.yml 中更改端口
   - 终止占用进程：`sudo kill <PID>`

3. PostgreSQL 特定问题：
   - 检查服务状态：`sudo systemctl status postgresql`
   - 停止服务：`sudo systemctl stop postgresql`
   - 禁用自启动：`sudo systemctl disable postgresql`

# 健康检查配置

## Docker 容器健康检查

- app 服务配置了基于 HTTP 的健康检查
- 健康检查端点：`/health`
- 检查间隔：30 秒
- 超时时间：10 秒
- 重试次数：3 次
- 启动宽限期：30 秒

## 注意事项

- 确保 Dockerfile 中安装了 curl 工具
- 健康检查失败可能导致容器重启
- 查看健康状态：`docker ps` 或 `docker inspect`

# AI 服务调用最佳实践

## API 端点

基础 URL: `/api/v1/ai/analyze`

### 请求示例

1. 基础调用示例：

```bash
curl -X POST http://localhost:8080/api/v1/ai/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "text": "需要分析的文本内���"
  }'
```

2. 带完整选项的调用示例：

```bash
curl -X POST http://localhost:8080/api/v1/ai/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "text": "需要分析的文本内容",
    "options": {
      "language": "zh",
      "maxTokens": 100,
      "temperature": 0.7
    }
  }' | json_pp
```

### 请求参数说明

| 参数                | 类型   | 必填 | 说明               |
| ------------------- | ------ | ---- | ------------------ |
| text                | String | 是   | 需要分析的文本内容 |
| options             | Object | 否   | 分析选项           |
| options.language    | String | 否   | 语言代码，如 "zh"  |
| options.maxTokens   | Int    | 否   | 最大标记数         |
| options.temperature | Double | 否   | 采样温度，范围 0-1 |

### 响应格式

```json
{
  "analysis": "分析结果文本",
  "keywords": ["关键词1", "关键词2"],
  "sentiment": "情感分析结果",
  "timestamp": "2024-03-20T10:00:00Z"
}
```

## 环境配置

1. 必要的环境变量：

```bash
export LLM_API_KEY="your-api-key"
export LLM_API_ENDPOINT="https://api.llm-service.com/v1/analyze"
```

2. Docker 环境变量配置：

```yaml
environment:
  - LLM_API_KEY=${LLM_API_KEY}
  - LLM_API_ENDPOINT=${LLM_API_ENDPOINT}
```

## 日志追踪

1. 查看请求日志：

```bash
docker compose logs app | grep "AI analysis"
```

2. 关键日志节点：

- 请求开始：`AI analysis request started`
- 参数解析：`Decoding request parameters`
- 服务调用：`Calling LLM service`
- 调用完成：`LLM service call completed`

## 性能监控

1. 关键指标：

- 请求响应时间
- LLM 服务调用时间
- 错误率
- 请求成功率

2. 监控命令：

```bash
# 查看平均响应时间
docker compose logs app | grep "Duration" | awk -F"Duration: " '{sum += $2; count++} END {print sum/count}'

# 查看错误率
docker compose logs app | grep -c "error"
```

## 错误处理

1. 常见错误码：

- 400: 请求参数错误
- 401: 未授权（API Key 无效）
- 429: 请求过于频繁
- 500: LLM 服务内部错误

2. 错误恢复策略：

- 实现请求重试机制
- 设置超时限制
- 实现熔断机制
- 监控错误模式

## 安全考虑

1. API 密钥保护：

- 使用环境变量管理密钥
- 定期轮换密钥
- 避免在日志中打印密钥

2. 请求限制：

- 实施速率限制
- 设置最大文本长度
- 验证请求来源

## 最佳实践

1. 调用建议：

- 合理设置 maxTokens 避免过度消耗
- 根据场景调整 temperature 参数
- 实现请求缓存减少重复调用

2. 性能优化：

- 使用异步处理长文本
- 实现结果缓存
- 批量处理请求
- 监控资源使用

# 腾讯混元大模型集成指南

## 环境配置

1. 必要的环境变量：

```bash
# 腾讯云密钥配置
export TENCENT_SECRET_ID="your-secret-id"
export TENCENT_SECRET_KEY="your-secret-key"
```

2. Docker 环境变量配置：

```yaml
environment:
  - TENCENT_SECRET_ID=${TENCENT_SECRET_ID}
  - TENCENT_SECRET_KEY=${TENCENT_SECRET_KEY}
```

## API 端点

### 1. 聊天补全接口

**请求地址**：`POST /api/v1/llm/chat`

**请求参数**：

```json
{
  "messages": [
    {
      "role": "user",
      "content": "你好"
    }
  ],
  "model": "hunyuan-lite",
  "temperature": 0.7,
  "stream": false
}
```

**响应格式**：

```json
{
  "content": "你好！很高兴见到你。",
  "usage": {
    "promptTokens": 3,
    "completionTokens": 34,
    "totalTokens": 37
  },
  "requestId": "80b9eed0-e14d-4d6a-ab6b-e0901addbb12"
}
```

### 2. 流式聊天补全接口

**请求地址**：`POST /api/v1/llm/chat/stream`

**请求参数**：与普通聊天接口相同

**响应格式**：Server-Sent Events (SSE)

```
data: {"content": "你好"}

data: {"content": "！"}

data: {"content": "很高兴"}

data: {"content": "见到你。"}

data: [DONE]
```

## 错误处理

1. 常见错误码：

   - 400: 请求参数错误
   - 401: 未授权（API Key 无效）
   - 429: 请求过于频繁
   - 500: 服务内部错误

2. 错误响应格式：

```json
{
  "error": {
    "code": "error_code",
    "message": "错误描述"
  }
}
```

## 最佳实践

1. 请求建议：

   - 合理设置 temperature 参数（0.7 为推荐值）
   - 控制单次请求的 token 数量
   - 使用流式接口获得更好的交互体验

2. 安全建议：

   - 使用环境变量管理密钥
   - 定期轮换密钥
   - 实施请求速率限制

3. 性能优化：

   - 使用流式接口处理长文本生成
   - 实现响应缓存
   - 合理设置超时时间

4. 监控建议：
   - 记录 API 调用日志
   - 监控响应时间
   - 跟踪 token 使用量
   - 设置错误告警

## 开发调试

1. 使用 curl 测试接口：

```bash
# 普通聊天接口
curl -X POST http://localhost:8080/api/v1/llm/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "你好"}],
    "model": "hunyuan-lite",
    "temperature": 0.7
  }'

# 流式聊天接口
curl -X POST http://localhost:8080/api/v1/llm/chat/stream \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "你好"}],
    "model": "hunyuan-lite",
    "temperature": 0.7
  }'
```

2. 查看日志：

```bash
# 查看应用日志
docker compose logs app | grep "LLM"

# 查看错误日志
docker compose logs app | grep "error"
```
