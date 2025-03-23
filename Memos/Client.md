# Client memo 是客户端需要关心的备忘，所有和客户端调用相关的所有细节，请记录在次

# 提示词 API 调用说明

## 获取最新提示词

### 接口说明

- 请求方法：GET
- 请求路径：/api/v1/prompts
- 响应格式：JSON

### 响应说明

- 每次调用都会返回最新的完整提示词内容
- 不需要传入版本参数
- 建议客户端实现本地缓存机制，避免频繁请求

### 示例

```bash
curl -X GET http://your-server/api/v1/prompts
```

### 响应示例

```json
{
  "prompt": {
    "id": "uuid",
    "version": 1,
    "content": "提示词内容",
    "createdAt": "2024-02-21T00:00:00Z"
  }
}
```

### 注意事项

1. 建议客户端实现合理的请求间隔
2. 可以根据业务需求在客户端实现缓存策略
3. 如遇到网络问题，建议实现适当的重试机制

# LLM 聊天 API 调用说明

## 发送聊天请求

### 接口说明

- 请求方法：POST
- 请求路径：/api/v1/llm/chat
- 请求格式：JSON
- 响应格式：JSON

### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
| --- | --- | --- | --- |
| CALENDAR_NAMES_LIST | String | 是 | 日历名称列表 |
| USER_CONTEXT | String | 是 | 用户上下文信息 |
| PLACEHOLDER_TEXT | String | 是 | 待处理的占位文本 |

### 请求示例

```json
{
  "CALENDAR_NAMES_LIST": "工作日历,个人日历,家庭日历",
  "USER_CONTEXT": "用户的相关背景上下文",
  "PLACEHOLDER_TEXT": "下周三上午我们开产品评审会，9 点到 10 点，老地方，产品组的都来。"
}
```

### 响应说明

返回 LLM 处理后的结果，包括：

- Content: 处理后的内容
- RequestId: 请求标识符

### 响应示例

```json
{
  "Content": "BEGIN:VCALENDAR\nVERSION:2.0\n...",
  "RequestId": "b07b8f57-9c4f-4a1c-8ade-b9456cb78b12"
}
```

### 处理流程

1. 客户端发送请求
2. 服务端获取最新提示词模板
3. 将请求参数替换模板中的占位符
4. 调用 LLM 处理内容
5. 返回处理结果

### 注意事项

1. 请求体大小限制为 1MB
2. 如需处理大型文本，建议分段处理
3. 请求受到 JWT 认证保护，确保包含有效的授权令牌
4. 服务端支持通过环境变量 `TENCENT_MODEL` 动态切换模型，可用模型包括：
   - `hunyuan-standard`
   - `hunyuan-standard-256K`（默认值）
   - `hunyuan-lite`
   - `hunyuan-large`
   - `hunyuan-t1-latest`
