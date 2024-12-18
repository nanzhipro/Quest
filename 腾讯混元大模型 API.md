# 腾讯混元大模型 API

## 调用示例

```python

import json
import types
from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.common.exception.tencent_cloud_sdk_exception import TencentCloudSDKException
from tencentcloud.hunyuan.v20230901 import hunyuan_client, models
try:
    # 实例化一个认证对象，入参需要传入腾讯云账户 SecretId 和 SecretKey，此处还需注意密钥对的保密
    # 代码泄露可能会导致 SecretId 和 SecretKey 泄露，并威胁账号下所有资源的安全性。以下代码示例仅供参考，建议采用更安全的方式来使用密钥，请参见：https://cloud.tencent.com/document/product/1278/85305
    # 密钥可前往官网控制台 https://console.cloud.tencent.com/cam/capi 进行获取
    cred = credential.Credential("SecretId", "SecretKey")
    # 实例化一个http选项，可选的，没有特殊需求可以跳过
    httpProfile = HttpProfile()
    httpProfile.endpoint = "hunyuan.tencentcloudapi.com"

    # 实例化一个client选项，可选的，没有特殊需求可以跳过
    clientProfile = ClientProfile()
    clientProfile.httpProfile = httpProfile
    # 实例化要请求产品的client对象,clientProfile是可选的
    client = hunyuan_client.HunyuanClient(cred, "ap-beijing", clientProfile)

    # 实例化一个请求对象,每个接口都会对应一个request对象
    req = models.ChatCompletionsRequest()
    params = {
        "Model": "hunyuan-lite",
        "Messages": [
            {
                "Role": "assistant",
                "Content": "hello"
            }
        ],
        "Stream": True,
        "Temperature": 0
    }
    req.from_json_string(json.dumps(params))

    # 返回的resp是一个ChatCompletionsResponse的实例，与请求对象对应
    resp = client.ChatCompletions(req)
    # 输出json格式的字符串回包
    if isinstance(resp, types.GeneratorType):  # 流式响应
        for event in resp:
            print(event)
    else:  # 非流式响应
        print(resp)


except TencentCloudSDKException as err:
    print(err)

```

## 参考文档

腾讯混元大模型 对话 API 接口 [对话 API 接口描述](https://cloud.tencent.com/document/api/1729/105701).

## 响应结果

```json
{
  "Response": {
    "RequestId": "80b9eed0-e14d-4d6a-ab6b-e0901addbb12",
    "Note": "以上内容为AI生成，不代表开发者立场，请勿删除或修改本标记",
    "Choices": [
      {
        "Index": 0,
        "Message": {
          "Role": "assistant",
          "Content": "Hello! How can I assist you today? If you have any questions, need information on a specific topic, or want to discuss something, feel free to ask!"
        },
        "FinishReason": "stop"
      }
    ],
    "Created": 1734480822,
    "Id": "80b9eed0-e14d-4d6a-ab6b-e0901addbb12",
    "Usage": {
      "PromptTokens": 3,
      "CompletionTokens": 34,
      "TotalTokens": 37
    }
  }
}
```

## Curl 发起真实请求

```bash
curl -X POST https://hunyuan.tencentcloudapi.com -H "Authorization: TC3-HMAC-SHA256 Credential=AKIDdsxnEBGzx-5Q7YUbEwZ36lZaX0eFigf3Jhf6lIMMbMgI2_lqBA6Y22hBTVn_g3NA/2024-12-18/hunyuan/tc3_request, SignedHeaders=content-type;host, Signature=3e4676977b9b752d498ce6c60584c5d8e83c211cbee336992b2314a097f3b162" -H "Content-Type: application/json" -H "Host: hunyuan.tencentcloudapi.com" -H "X-TC-Action: ChatCompletions" -H "X-TC-Timestamp: 1734480820" -H "X-TC-Version: 2023-09-01" -H "X-TC-Region: ap-beijing" -H "X-TC-Language: zh-CN" -H "X-TC-Token: mPw7OBg2jpQxtZAM306k6uceGsWyMYUa2d2c6d802ee47ac58c9b422e69c754357QOs83XZWAYZgI3Z5_09DmdlZAndhRQMtabLGPx7eLt-P0Ff95_YgN3liIuIyeNUsmMlejkqdWAilLB04rMfawkqiXuaAJVCBEkBLPeciE6JSPJaHmrdWnEtoQ2Bm-ybLd1z9RbR3EgXyvAJiGgPYmsvbKTnVC1sWnsH1q5F74urlFHR4cFhLWv36eChvado1TUCTyr0Ygl9UAi6ZS-yDw" -d '{"Model":"hunyuan-lite","Messages":[{"Role":"user","Content":"hello"}],"Stream":false,"Temperature":0}'
```

## 签名方法

调用方式> [签名方法 v3](https://cloud.tencent.com/document/api/213/30654)

签名示例代码如下：

```swift
import Foundation
import CryptoKit

func sha256(msg: String) -> String {
    let data = msg.data(using: .utf8)!
    let digest = SHA256.hash(data: data)
    return digest.compactMap{String(format: "%02x", $0)}.joined()
}

func main() {
    // 密钥参数
    // 需要设置环境变量 TENCENTCLOUD_SECRET_ID，值为示例的 AKIDz8krbsJ5yKBZQpn74WFkmLPx3*******
    //let secretId = ProcessInfo.processInfo.environment["TENCENTCLOUD_SECRET_ID"]
    let secretId = "AKIDz8krbsJ5yKBZQpn74WFkmLPx3*******"
    // 需要设置环境变量 TENCENTCLOUD_SECRET_KEY，值为示例的 Gu5t9xGARNpq86cd98joQYCN3*******
    //let secretKey = ProcessInfo.processInfo.environment["TENCENTCLOUD_SECRET_KEY"]
    let secretKey = "Gu5t9xGARNpq86cd98joQYCN3*******"

    let service = "cvm"
    let host = "cvm.tencentcloudapi.com"
    let endpoint = "https://\(host)"
    let region = "ap-guangzhou"
    let action = "DescribeInstances"
    let version = "2017-03-12"
    let algorithm = "TC3-HMAC-SHA256"
    let timestamp = 1551113065
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    let date = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))

    // ************* 步骤 1：拼接规范请求串 *************
    let httpRequestMethod = "POST"
    let canonicalUri = "/"
    let canonicalQuerystring = ""
    let ct = "application/json; charset=utf-8"
    //let payload = try! JSONSerialization.data(withJSONObject: params)
    //let payloadString = String(data: payload, encoding: .utf8)!
    let payload = "{\"Limit\": 1, \"Filters\": [{\"Values\": [\"\\u672a\\u547d\\u540d\"], \"Name\": \"instance-name\"}]}"
    let canonicalHeaders = "content-type:\(ct)\nhost:\(host)\nx-tc-action:\(action.lowercased())\n"
    let signedHeaders = "content-type;host;x-tc-action"
    let hashedRequestPayload = sha256(msg: payload)
    let canonicalRequest = """
    \(httpRequestMethod)
    \(canonicalUri)
    \(canonicalQuerystring)
    \(canonicalHeaders)
    \(signedHeaders)
    \(hashedRequestPayload)
    """
    print(canonicalRequest)

    // ************* 步骤 2：拼接待签名字符串 *************
    let credentialScope = "\(date)/\(service)/tc3_request"
    let hashedCanonicalRequest = sha256(msg: canonicalRequest)
    let stringToSign = """
    \(algorithm)
    \(timestamp)
    \(credentialScope)
    \(hashedCanonicalRequest)
    """
    print(stringToSign)

    // ************* 步骤 3：计算签名 *************
    let keyData = Data("TC3\(secretKey)".utf8)
    let dateData = Data(date.utf8)
    var symmetricKey = SymmetricKey(data: keyData)
    let secretDate = HMAC<SHA256>.authenticationCode(for: dateData, using: symmetricKey)
    let secretDateString = Data(secretDate).map{String(format: "%02hhx", $0)}.joined()
    print("\(secretDateString)")

    let serviceData = Data(service.utf8)
    symmetricKey = SymmetricKey(data: Data(secretDate))
    let secretService = HMAC<SHA256>.authenticationCode(for: serviceData, using: symmetricKey)
    let secretServiceString = Data(secretService).map{String(format: "%02hhx", $0)}.joined()
    print("\(secretServiceString)")

    let signingData = Data("tc3_request".utf8)
    symmetricKey = SymmetricKey(data: secretService)
    let secretSigning = HMAC<SHA256>.authenticationCode(for: signingData, using: symmetricKey)
    let secretSigningString = Data(secretSigning).map{String(format: "%02hhx", $0)}.joined()
    print("\(secretSigningString)")

    let stringToSignData = Data(stringToSign.utf8)
    symmetricKey = SymmetricKey(data: secretSigning)
    let signature = HMAC<SHA256>.authenticationCode(for: stringToSignData, using: symmetricKey).map{String(format: "%02hhx", $0)}.joined()
    print(signature)

    // ************* 步骤 4：拼接 Authorization *************
    let authorization = """
    \(algorithm) Credential=\(secretId)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)
    """
    print(authorization)

    print("curl -X POST \(endpoint)"
        + " -H \"Authorization: \(authorization)\""
        + " -H \"Content-Type: \(ct)\""
        + " -H \"Host: \(host)\""
        + " -H \"X-TC-Action: \(action)\""
        + " -H \"X-TC-Timestamp: \(timestamp)\""
        + " -H \"X-TC-Version: \(version)\""
        + " -H \"X-TC-Region: \(region)\""
        + " -d '\(payload)'")
}

main()
```

## 生成签名步骤

1. 请求数据
   这里显示您输入的业务数据

```json
{
  "Model": "hunyuan-lite",
  "Messages": [{ "Role": "user", "Content": "hello" }],
  "Stream": false,
  "Temperature": 0
}
```

2. 拼接规范请求串

```bash
POST
/

content-type:application/json
host:hunyuan.tencentcloudapi.com
x-tc-action:chatcompletions

content-type;host;x-tc-action
2e64c2638a1a6d2b5b03d8dd8f89412f087a3dd687cdb98feabe5a9ee05c4ae1
```

3. 拼接待签名字符串

```bash
  TC3-HMAC-SHA256
  1734481295
  2024-12-18/hunyuan/tc3_request
  d82bdc3f3f32ea30194431d2b31feef79b406cafb4aed61a4643ae951c75e814
```

4. 计算签名

```txt
7e4199edb2d9314aeae3d58a1701058ca892539000180d66af2e53207826ba65
```

5. 拼接 Authorization

```txt
TC3-HMAC-SHA256 Credential=AKIDc5IEuKTM6aomTu5zOXQ1MVO1NULvUzFJ/2024-12-18/hunyuan/tc3_request, SignedHeaders=content-type;host;x-tc-action, Signature=7e4199edb2d9314aeae3d58a1701058ca892539000180d66af2e53207826ba65
```

6. 最后
   以您选择的 ChatCompletions 接口为例，您可以通过上面生成的签名串，将请求协议，uri，路径和参数拼装成 curl 命令,由于本签名过程中，设定的请求方法是 POST，所以，拼装结果是：

```sh
curl -H "Host: hunyuan.tencentcloudapi.com" -H "X-TC-Action: ChatCompletions" -H "X-TC-Timestamp: 1734481295" -H "X-TC-Language: zh-CN" -H "X-TC-RequestClient: APIExplorer" -H "X-TC-Version: 2023-09-01" -H "X-TC-Region: ap-beijing" -H "Content-Type: application/json" -H "Authorization: TC3-HMAC-SHA256 Credential=AKIDc5IEuKTM6aomTu5zOXQ1MVO1NULvUzFJ/2024-12-18/hunyuan/tc3_request, SignedHeaders=content-type;host;x-tc-action, Signature=7e4199edb2d9314aeae3d58a1701058ca892539000180d66af2e53207826ba65"  -d '{"Model":"hunyuan-lite","Messages":[{"Role":"user","Content":"hello"}],"Stream":false,"Temperature":0}' 'https://hunyuan.tencentcloudapi.com/'
```
