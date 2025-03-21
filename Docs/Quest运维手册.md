# Quest运维手册

## 服务器环境准备
1. 购置腾讯轻量服务器
2. 安装必备软件： zsh，myzsh，gh（github，并login配置可以访问）
3. git clone Quest

## Quest环境配置
1. gh repo clone nanzhipro/Quest
> 如果无法访问，使用： git clone git@github.com:nanzhipro/Quest.git

2. cp .env.example .env，并配置env各种参数和APIKey。
3. 从腾讯云申领免费证书（90天过期，需要重新签发一次），把证书放置在Docs/ssl目录
> 新建 ssl 目录
> 注意证书和密钥文件名，要保持和配置一致。
使用： schedulesage.cn_bundle.crt 和 schedulesage.cn.key
并更名：
/app/certs/cert.pem
/app/certs/key.pem

4. 尝试docker build，如果失败。无法连接github，需要修改dns
/etc/host 增加
140.82.114.3 github.com
185.199.108.133 raw.githubusercontent.com


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

5. **查看数据库**：

```bash
# 方法1：使用 psql 命令行
docker compose exec db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

# 常用 PostgreSQL 命令：
\dt  # 列出所有表
\d 表名  # 查看表结构
SELECT * FROM 表名;  # 查询表数据

# 方法2：使用图形化工具（如 pgAdmin）连接
# 获取数据库容器的IP和端口
docker compose ps

# 查看迁移表
SELECT * FROM _fluent_migrations;

```

6. 更新数据库，如prompts表。
> Docs/UpdatePrompts.sql
> 需要修改一下对应的id值。



