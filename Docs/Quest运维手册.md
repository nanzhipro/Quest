# Quest运维手册

## 服务器环境准备
1. 腾讯轻量服务器（东京）
2. 安装必备软件： zsh，myzsh，gh（github，并login配置可以访问）
3. git clone Quest

## Quest环境配置
1. gh repo clone nanzhipro/Quest
2. mv .env.example .env，并配置env各种参数和APIKey。
3. 从腾讯云申领免费证书（90天过期，需要重新签发一次），把证书放置在Docs/ssl目录
> 注意证书和密钥文件名，要保持和配置一致。

4. **构建和启动服务**：

```bash
# 构建 Docker 镜像
docker compose build

# 启动服务
docker compose up -d

# 检查服务状态
docker compose ps

# 查看容器.env
docker compose exec app cat /app/.env

# 进入app容器内部
docker compose exec app sh




```



