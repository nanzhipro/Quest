# 语音识别客户端调用指南

## 语音识别API

### 接口说明

该接口用于识别客户端上传的语音数据，并返回识别后的文本内容。

**接口路径:** `/api/v1/voice/recognize`  
**请求方法:** POST  
**Content-Type:** `application/json`

### 认证方式

使用JWT令牌进行认证，在HTTP请求头中添加：

```
Authorization: Bearer <token>
```

可以通过 `/api/get_jwt_token` 接口获取token。

### 请求参数

| 参数名 | 类型 | 必选 | 描述 |
| --- | --- | --- | --- |
| audioData | String | 是 | Base64编码的音频数据 |
| audioFormat | String | 否 | 音频格式，默认为"wav" |
| engineType | String | 否 | 引擎模型类型，默认为"16k_zh" |
| wordInfo | Int | 否 | 是否显示词级别时间戳 (0:不显示, 1:显示不含标点, 2:显示含标点) |
| filterDirty | Int | 否 | 是否过滤脏词 (0:不过滤, 1:过滤, 2:用*替代) |
| filterModal | Int | 否 | 是否过滤语气词 (0:不过滤, 1:部分过滤, 2:严格过滤) |
| filterPunc | Int | 否 | 是否过滤标点符号 (0:不过滤, 1:过滤句末标点, 2:过滤所有标点) |
| convertNumMode | Int | 否 | 是否进行阿拉伯数字智能转换 (0:不转换, 1:根据场景智能转换) |

### 响应参数

| 参数名 | 类型 | 描述 |
| --- | --- | --- |
| text | String | 识别结果文本 |
| audioDuration | Int | 音频时长（毫秒） |
| words | Array | 词时间戳列表（仅当请求中wordInfo>0时返回） |
| requestId | String | 请求ID |

`words` 数组中的每个元素包含：

| 参数名 | 类型 | 描述 |
| --- | --- | --- |
| text | String | 词文本 |
| startTime | Int | 开始时间（毫秒） |
| endTime | Int | 结束时间（毫秒） |

### 错误码

| 状态码 | 错误描述 |
| --- | --- |
| 400 | 请求参数错误 |
| 401 | 认证失败 |
| 403 | 权限不足 |
| 500 | 服务器内部错误 |
| 503 | 语音识别服务不可用 |

### 请求示例

#### Swift (URLSession)

```swift
import Foundation

func recognizeVoice(audioData: Data, completion: @escaping (Result<String, Error>) -> Void) {
    // 准备URL
    let url = URL(string: "https://your-api-domain.com/api/v1/voice/recognize")!
    
    // 准备请求
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer YOUR_JWT_TOKEN", forHTTPHeaderField: "Authorization")
    
    // 准备请求体
    let requestBody: [String: Any] = [
        "audioData": audioData.base64EncodedString(),
        "audioFormat": "wav",
        "engineType": "16k_zh",
        "wordInfo": 1
    ]
    
    // 序列化请求体
    request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
    
    // 发送请求
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        // 错误处理
        if let error = error {
            completion(.failure(error))
            return
        }
        
        // 检查HTTP状态码
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            completion(.failure(NSError(domain: "HTTP Error", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: nil)))
            return
        }
        
        // 解析响应
        guard let data = data else {
            completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["text"] as? String {
                completion(.success(text))
            } else {
                completion(.failure(NSError(domain: "JSON Parsing Error", code: 0, userInfo: nil)))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    task.resume()
}
```

#### JavaScript (Fetch API)

```javascript
async function recognizeVoice(audioArrayBuffer) {
  // 将ArrayBuffer转换为Base64
  const base64Audio = arrayBufferToBase64(audioArrayBuffer);
  
  try {
    const response = await fetch('https://your-api-domain.com/api/v1/voice/recognize', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_JWT_TOKEN'
      },
      body: JSON.stringify({
        audioData: base64Audio,
        audioFormat: 'wav',
        engineType: '16k_zh',
        wordInfo: 1
      })
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const data = await response.json();
    return data.text;
  } catch (error) {
    console.error('Error during voice recognition:', error);
    throw error;
  }
}

// 辅助函数：ArrayBuffer转Base64
function arrayBufferToBase64(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return window.btoa(binary);
}
```

### 注意事项

1. 音频数据大小限制为3MB
2. 支持的音频格式：wav, pcm, ogg-opus, speex, silk, mp3, m4a, aac, amr
3. 音频时长限制为60秒
4. 默认使用16K采样率普通话引擎 (16k_zh)
5. 请确保音频质量较好，背景噪音较小，以提高识别准确率 