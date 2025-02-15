## API 服务部署和监控

1. 监控指标

   - 请求响应时间
   - 错误率
   - 并发请求数
   - 带宽使用情况

2. 日志记录

   - 请求/响应日志
   - 错误日志
   - 性能指标

3. 告警设置
   - 高错误率告警
   - 响应时间过长告警
   - 服务不可用告警

# Docker 部署最佳实践

## 构建优化

- 启用 BuildKit: `export DOCKER_BUILDKIT=1`
- 使用多阶段构建减小镜像体积
- 配置 .dockerignore 排除不必要文件

## 安全建议

- 容器以只读模式运行
- 使用 no-new-privileges 限制权限提升
- 敏感信息通过环境变量注入
- 证书文件使用只读挂载

## 资源管理

- 设置合理的内存限制
- 配置健康检查确保服务可用性
- 使用 tmpfs 处理临时文件

## 监控建议

- 监控容器健康状态
- 跟踪资源使用情况
- 设置告警阈值

## 维护操作

- 定期备份数据卷
- 检查日志输出
- 更新基础镜像

# TLS 证书管理

## 证书部署

- 确保证书文件正确挂载到容器
- 检查证书文件权限
- 监控证书过期时间
- 实施自动证书更新机制

## 故障排查

- 检查证书路径配置
- 验证证书格式正确性
- 确认私钥匹配证书
- 检查 TLS 握手日志

# 服务配置说明

## TLS/HTTP 配置

- 服务优先尝试以 HTTPS 模式启动（端口 443）
- 如果找不到证书文件，自动降级为 HTTP 模式（端口 8080）
- 证书路径可通过环境变量配置：
  - TLS_CERT_PATH
  - TLS_KEY_PATH

## 部署建议

- 生产环境应始终配置有效的 TLS 证书
- 仅在开发/测试环境使用 HTTP 模式
- 监控证书有效期，及时更新

## JWT 中间件日志记录最佳实践

- 使用适当的日志级别（info/warning/error）记录认证过程
- 记录关键操作点：
  - 认证开始
  - Token 验证结果
  - 错误情况
- 包含必要的上下文信息（如用户ID）
- 避免记录敏感信息
- 使用结构化日志便于后续分析

## PostgreSQL 客户端安装
- Ubuntu 系统使用 `postgresql-client` 包
- 建议安装与数据库版本匹配的客户端
- 容器内工具可作为替代方案

# 数据库调试技巧

## 方法 1: 直接进入数据库容器执行 psql
docker compose exec db sh   # 进入容器shell
psql -U postgres            # 连接默认数据库

## 在 psql 终端中执行:
\c your_database_name       # 切换数据库（默认可能为 postgres）
\d prompts                 # 查看表结构
SELECT * FROM prompts;      # 查看数据

## 方法 2: 从宿主机直接连接（需本地有 psql 客户端）
psql -h localhost -p 5432 -U postgres -d postgres
# 密码可能在 docker-compose.yml 中设置，检查 POSTGRES_PASSWORD 环境变量

## 快速验证表是否存在（不进入交互模式）:
docker compose exec db psql -U postgres -c '\d prompts'

# 文件管理技巧
- 使用`docker compose cp`在宿主机和容器间拷贝文件
- 重要文件建议使用volume持久化存储
- 定期清理容器内临时文件
- 使用`chmod`调整文件权限

# 拷贝文件到容器内
docker compose cp Resources/Prompts/default.md app:/app/Resources/Prompts/default.md

# 验证文件是否成功复制
docker compose exec app ls -l /app/Resources/Prompts/default.md

# 如果需要调整权限
docker compose exec app chmod 644 /app/Resources/Prompts/default.md
