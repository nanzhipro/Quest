# 高级功能访问API调用示例

## 检查设备高级功能访问权限

### 请求

```swift
import Foundation

// 设备UUID，应保持持久化存储
let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

// 构建请求数据
let requestData: [String: String] = ["deviceUUID": deviceUUID]

// 创建URL请求
var request = URLRequest(url: URL(string: "https://your-api-server.com/api/v1/premium-features/check-access")!)
request.httpMethod = "POST"
request.addValue("application/json", forHTTPHeaderField: "Content-Type")
request.addValue("Bearer YOUR_JWT_TOKEN", forHTTPHeaderField: "Authorization")

// 序列化请求体
request.httpBody = try? JSONSerialization.data(withJSONObject: requestData)

// 发送请求
let task = URLSession.shared.dataTask(with: request) { data, response, error in
    guard let data = data, error == nil else {
        print("网络请求错误: \(error?.localizedDescription ?? "未知错误")")
        return
    }
    
    do {
        // 解析响应数据
        if let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let hasAccess = responseJSON["hasAccess"] as? Bool {
            
            if hasAccess {
                print("设备已获授权使用高级功能")
                // 在应用中启用高级功能
                enablePremiumFeatures()
            } else {
                let reason = responseJSON["reason"] as? String ?? "未知原因"
                print("设备未获授权使用高级功能: \(reason)")
                // 在应用中禁用高级功能
                disablePremiumFeatures()
            }
        }
    } catch {
        print("响应解析错误: \(error.localizedDescription)")
    }
}

task.resume()
```

### 响应

```json
{
    "hasAccess": true,
    "reason": null
}
```

或者，如果未授权：

```json
{
    "hasAccess": false, 
    "reason": "设备未被授权访问高级功能"
}
```

## 最佳实践

1. **首次启动检查**: 应用首次启动时检查高级功能访问权限。
2. **周期性检查**: 定期（如每天一次）重新检查访问权限，以适应服务端配置变更。
3. **离线处理**: 实现本地缓存机制，在网络不可用时回退到上次检查结果。
4. **设备标识符持久化**: 确保设备UUID在应用重装后保持不变（可使用钥匙串存储）。
5. **错误处理**: 在网络请求失败时采取保守策略，不立即禁用高级功能。

## 示例Swift函数

```swift
import Foundation

class PremiumFeaturesService {
    static let shared = PremiumFeaturesService()
    
    private let userDefaults = UserDefaults.standard
    private let accessStatusKey = "premium_access_status"
    private let lastCheckTimeKey = "premium_last_check_time"
    private let checkInterval: TimeInterval = 86400 // 24小时
    
    private init() {}
    
    /// 检查设备是否有高级功能访问权限
    /// - Parameter completion: 结果回调
    func checkPremiumAccess(force: Bool = false, completion: @escaping (Bool) -> Void) {
        // 如果强制检查或者上次检查时间超过间隔，则进行网络请求
        let lastCheckTime = userDefaults.double(forKey: lastCheckTimeKey)
        if force || Date().timeIntervalSince1970 - lastCheckTime > checkInterval {
            requestPremiumAccess { [weak self] hasAccess in
                self?.userDefaults.set(hasAccess, forKey: self?.accessStatusKey ?? "")
                self?.userDefaults.set(Date().timeIntervalSince1970, forKey: self?.lastCheckTimeKey ?? "")
                completion(hasAccess)
            }
        } else {
            // 否则使用缓存的结果
            let hasAccess = userDefaults.bool(forKey: accessStatusKey)
            completion(hasAccess)
        }
    }
    
    /// 发送网络请求检查访问权限
    private func requestPremiumAccess(completion: @escaping (Bool) -> Void) {
        guard let deviceUUID = UIDevice.current.identifierForVendor?.uuidString else {
            completion(false)
            return
        }
        
        // API请求实现...（同上面的示例代码）
    }
    
    /// 重置缓存状态，强制下次检查进行网络请求
    func resetCachedStatus() {
        userDefaults.removeObject(forKey: lastCheckTimeKey)
    }
}
```

## 使用方式

```swift
// 在应用启动时检查
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // 检查高级功能访问权限
    PremiumFeaturesService.shared.checkPremiumAccess { hasAccess in
        if hasAccess {
            // 启用高级功能
        } else {
            // 禁用高级功能
        }
    }
    
    return true
}
```
