## API 调用层安全建议

1. 使用 HTTPS 进行所有网络通信
2. 实现请求签名机制
3. 添加请求超时设置
4. 实现重试机制，但要避免重试敏感操作
5. 实现速率限制
6. 敏感数据的加密处理

# TLS 配置最佳实践

## 协议版本

- 最低要求 TLS 1.2
- 优先使用 TLS 1.3
- 禁用所有低版本 TLS 和 SSL

## HTTP 版本支持

- HTTPS 模式支持 HTTP/1.x 和 HTTP/2
- HTTP 降级模式仅支持 HTTP/1.x
- 建议在生产环境强制使用 HTTPS

## 证书管理

- 使用 PEM 格式的证书和私钥
- 定期检查证书有效期
- 实施自动证书更新机制
- 确保私钥安全存储

## 监控建议

- 监控 TLS 握手失败率
- 记录证书过期时间
- 追踪 HTTP/2 连接数

## 证书处理

- 使用 `NIOSSLCertificate(file:format:)` 加载证书文件，指定 `.pem` 格式
- 使用 `NIOSSLPrivateKey(file:format:)` 加载私钥文件，指定 `.pem` 格式
- 确保证书和私钥文件使用正确的 PEM 格式
- 证书文件权限设置为 600
- 使用环境变量配置证书路径

## 格式要求

- 证书必须是 PEM 格式（Base64 编码的 X.509）
- 私钥必须是 PEM 格式（Base64 编码的 PKCS#1 或 PKCS#8）
- 文件必须包含正确的 PEM 头部和尾部标记

## 安全建议

- 定期更新 TLS 证书
- 使用强加密套件
- 禁用不安全的 TLS 版本（低于 1.2）
- 配置适当的证书链

---

公网服务刚启动，就有大量的 GET 请求，获取关键数据：}] (App/TencentHunyuanOpenAIProvider.swift:96)
app-1 | [ INFO ] Chat request completed [request-id: 22F20EC9-F93C-4769-BDA7-2BD822AE33CD, requestId: 80C7FA3A-1990-46E5-BB85-211AB479E112] (App/LLMController.swift:32)
app-1 | [ INFO ] GET /\_vti_pvt/administrators.pwd [request-id: 419932BD-EF23-49B4-B35E-D927BF3C78F5] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 419932BD-EF23-49B4-B35E-D927BF3C78F5, url: /\_vti_pvt/administrators.pwd, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /backup.tar.gz [request-id: FEB26BDB-7076-421B-B568-E2AB53824CB8] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: FEB26BDB-7076-421B-B568-E2AB53824CB8, url: /backup.tar.gz, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /server-status [request-id: 3B7EB162-4E09-4204-9359-79FE7419E2E9] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 3B7EB162-4E09-4204-9359-79FE7419E2E9, url: /server-status, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /wp-admin/setup-config.php [request-id: 1E9666B5-6E80-41FB-8208-2C44B7223008] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 1E9666B5-6E80-41FB-8208-2C44B7223008, url: /wp-admin/setup-config.php, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /.ssh/id_rsa [request-id: 1B11417F-9C3B-436C-A046-CA5D227B7DA4] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 1B11417F-9C3B-436C-A046-CA5D227B7DA4, url: /.ssh/id_rsa, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /.env [request-id: D8890278-3D8B-41D3-AD23-2D182167A279] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: D8890278-3D8B-41D3-AD23-2D182167A279, url: /.env, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /.vscode/sftp.json [request-id: CE450250-FB0A-4A49-8751-D04EB067D38E] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: CE450250-FB0A-4A49-8751-D04EB067D38E, url: /.vscode/sftp.json, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /.kube/config [request-id: 6C090620-191E-4D1E-9AE3-90D6C79EE9A3] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 6C090620-191E-4D1E-9AE3-90D6C79EE9A3, url: /.kube/config, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /dump.sql [request-id: E67CAD52-112F-4FF0-81E6-FFC5E37C854A] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: E67CAD52-112F-4FF0-81E6-FFC5E37C854A, url: /dump.sql, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /config.json [request-id: C9E4D2EB-EB8E-45D1-9863-BACAA041DFEB] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ INFO ] GET /etc/shadow [request-id: CD3BC710-9D6A-4EF7-A6E2-CE943CFB408B] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: CD3BC710-9D6A-4EF7-A6E2-CE943CFB408B, url: /etc/shadow, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: C9E4D2EB-EB8E-45D1-9863-BACAA041DFEB, url: /config.json, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /.ssh/id_ed25519 [request-id: 97299BE6-AB26-4E66-9795-98B52443C4F6] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 97299BE6-AB26-4E66-9795-98B52443C4F6, url: /.ssh/id_ed25519, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /phpinfo.php [request-id: 4031133B-97F5-4C15-9C91-13EF994B5E7A] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ INFO ] GET /config/database.php [request-id: 7A6F5D4A-14E5-4263-B358-823896C509E2] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 7A6F5D4A-14E5-4263-B358-823896C509E2, url: /config/database.php, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 4031133B-97F5-4C15-9C91-13EF994B5E7A, url: /phpinfo.php, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /secrets.json [request-id: 37CFA9B5-CB38-499B-8011-BD472CC4B99F] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 37CFA9B5-CB38-499B-8011-BD472CC4B99F, url: /secrets.json, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /config.php [request-id: 9E244337-902C-45C1-BAE4-32EE85AC0FD6] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 9E244337-902C-45C1-BAE4-32EE85AC0FD6, url: /config.php, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /.env.production [request-id: 5D81DD0C-9D57-4975-BFEF-36300F1DF094] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 5D81DD0C-9D57-4975-BFEF-36300F1DF094, url: /.env.production, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /.aws/credentials [request-id: 945B7E58-0D3E-4326-97CD-408235321291] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 945B7E58-0D3E-4326-97CD-408235321291, url: /.aws/credentials, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /server.key [request-id: D337A69F-FF3F-48C2-8778-F8237B386CF6] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ INFO ] GET /api/.env [request-id: 768AD58E-41E6-41D8-B2D4-20A706FEEF4C] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 768AD58E-41E6-41D8-B2D4-20A706FEEF4C, url: /api/.env, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: D337A69F-FF3F-48C2-8778-F8237B386CF6, url: /server.key, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /.ssh/id_ecdsa [request-id: D9624A3A-AFBE-45DD-9799-96B7AC2D371B] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: D9624A3A-AFBE-45DD-9799-96B7AC2D371B, url: /.ssh/id_ecdsa, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /user_secrets.yml [request-id: 89C0CE0C-FE2D-4AAF-84F8-5EF2C4284BB7] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 89C0CE0C-FE2D-4AAF-84F8-5EF2C4284BB7, url: /user_secrets.yml, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /config.xml [request-id: 4C76FCD7-0A4A-4B93-BD84-230E2981BAEA] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 4C76FCD7-0A4A-4B93-BD84-230E2981BAEA, url: /config.xml, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /database.sql [request-id: 780BF68A-8F43-41FC-BF72-51E38676C61C] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 780BF68A-8F43-41FC-BF72-51E38676C61C, url: /database.sql, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /config.yml [request-id: DE70AFE2-3A01-4978-BD48-C3F995ABA3B3] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ INFO ] GET /backup.sql [request-id: C97AA5C0-29A4-435D-9DCD-7D405A070CEE] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: C97AA5C0-29A4-435D-9DCD-7D405A070CEE, url: /backup.sql, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: DE70AFE2-3A01-4978-BD48-C3F995ABA3B3, url: /config.yml, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /docker-compose.yml [request-id: 1738A529-CDF5-4584-B738-722A9C13502E] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 1738A529-CDF5-4584-B738-722A9C13502E, url: /docker-compose.yml, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /config.yaml [request-id: DFC40A6A-8D79-4723-AA70-967657A6D80F] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: DFC40A6A-8D79-4723-AA70-967657A6D80F, url: /config.yaml, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /config/production.json [request-id: EBDF5306-10D7-401B-919C-73E84A2549C9] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: EBDF5306-10D7-401B-919C-73E84A2549C9, url: /config/production.json, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET / [request-id: A71FA296-F9FA-4C71-8B16-AA89D9895287] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ INFO ] GET /\_vti_pvt/service.pwd [request-id: 3341D73D-CE94-4486-8B5D-507E007E6361] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 3341D73D-CE94-4486-8B5D-507E007E6361, url: /\_vti_pvt/service.pwd, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /backup.zip [request-id: BC31FC6C-4313-4545-A02A-80A25056E9FD] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: BC31FC6C-4313-4545-A02A-80A25056E9FD, url: /backup.zip, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /etc/ssl/private/server.key [request-id: 05BFDFCF-C8F7-459C-9E00-18760D974328] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 05BFDFCF-C8F7-459C-9E00-18760D974328, url: /etc/ssl/private/server.key, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /.git/HEAD [request-id: C741059A-91C8-4885-9BA5-C26FB69E08E5] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: C741059A-91C8-4885-9BA5-C26FB69E08E5, url: /.git/HEAD, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /feed [request-id: D442602A-8343-4E28-A90B-D4B0462487DE] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: D442602A-8343-4E28-A90B-D4B0462487DE, url: /feed, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /web.config [request-id: CF8D0915-4B22-433A-BA1E-0137F0D29847] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ INFO ] GET /\_vti_pvt/authors.pwd [request-id: C121F9BB-3AC3-47D7-B37C-8BAB4D8FA0C4] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: CF8D0915-4B22-433A-BA1E-0137F0D29847, url: /web.config, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: C121F9BB-3AC3-47D7-B37C-8BAB4D8FA0C4, url: /\_vti_pvt/authors.pwd, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /wp-config.php [request-id: D1378531-93D1-462C-B658-6A824B550E77] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: D1378531-93D1-462C-B658-6A824B550E77, url: /wp-config.php, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /cloud-config.yml [request-id: 34A02005-CC2F-42F3-8872-737938B064CA] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 34A02005-CC2F-42F3-8872-737938B064CA, url: /cloud-config.yml, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)
app-1 | [ INFO ] GET /.svn/wc.db [request-id: 903F8E43-2C25-46D0-BD69-A240A6ED009C] (Vapor/RouteLoggingMiddleware.swift:14)
app-1 | [ DEBUG ] RouteNotFound.404: Not Found [method: GET, request-id: 903F8E43-2C25-46D0-BD69-A240A6ED009C, url: /.svn/wc.db, userAgent: [Go-http-client/1.1]] (Vapor/ErrorMiddleware.swift:29)

# JWT 认证最佳实践

- 通过自定义中间件与 Vapor 内置的 JWT 机制，实现 API 认证拦截。
- 使用 HS256 等可靠的签名算法验证 JWT，有效防止伪造。
- 密钥应安全存储，生产环境中建议通过环境变量或安全的密钥管理服务配置，避免硬编码。
- JWT 中需包含过期时间 (exp) 以限制 token 的有效期，校验时务必调用 verifyNotExpired() 方法。
- 考虑生产环境下的密钥轮换策略及失败日志记录，提升系统的安全性和可观测性。

## JWT 认证安全日志注意事项

- 切勿在日志中记录完整的 JWT token
- 避免记录用户敏感信息
- 记录认证失败的具体原因，但不暴露系统实现细节
- 考虑记录可疑的认证模式用于安全分析

## JWT 中间件排除路径
- `/api/get_jwt_token` 路径被排除在 JWT 验证之外
- 请确保被排除的路径有其他适当的安全措施（如 API 限流、IP 白名单等）
- 定期审查排除路径列表，确保安全性

## 容器安全实践
- 使用`read_only: true`增强容器安全性
- 通过volume挂载实现必要的文件操作
- 敏感文件挂载为只读
- 使用tmpfs处理临时文件
