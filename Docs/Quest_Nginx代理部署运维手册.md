# Quest Nginx代理部署运维手册

## 系统架构

本部署方案使用Nginx作为前端代理，具有以下特点：

1. Nginx提供Next.js静态网站服务，用于产品落地页和等待名单注册
2. Nginx反向代理所有API请求到Vapor应用
3. Nginx处理HTTPS加密，使用相同的SSL证书
4. 架构隔离，Nginx和Vapor可以独立部署和维护

```
            外部请求
                |
                ↓
            [Nginx 443]
            /        \
           /          \
前端Next.js请求       API请求(/api/*)
      |                |
      ↓                ↓
  [Next.js]       [Vapor应用 内部网络]
                       |
                       ↓
                 [PostgreSQL数据库]
```

## 部署步骤

### 1. 准备工作

- 确保已有Quest应用部署成功并运行
- 确保SSL证书文件已放置在`Docs/ssl/`目录下
  - cert.pem: 证书文件
  - key.pem: 私钥文件

### 2. 配置组件

项目目录下已包含以下配置：

- **Nginx配置**:
  - `nginx/Dockerfile.nginx`: Nginx的Docker构建文件
  - `nginx/nginx.conf`: Nginx的配置文件，包含反向代理设置

- **Next.js前端**:
  - `frontend/`: Next.js应用目录
  - `frontend/Dockerfile`: Next.js的Docker构建文件

- **部署配置**:
  - `nginx-docker-compose.yml`: Nginx和Next.js的Docker Compose配置文件

### 3. 配置和启动服务

```bash
# 构建并启动Nginx和Next.js容器
docker-compose -f nginx-docker-compose.yml up -d

# 验证服务状态
docker-compose -f nginx-docker-compose.yml ps
```

### 4. 测试验证

1. 前端测试：
   - 浏览器访问: <https://你的域名/>
   - 应该显示Next.js构建的落地页和等待名单表单

2. API测试：
   - 通过前端表单提交邮箱地址
   - 或通过curl直接访问: <https://你的域名/api/v1/waitlist>

## 维护操作

### 前端内容更新

1. 编辑 frontend/ 目录下的文件
2. 重新构建并部署:

   ```bash
   docker-compose -f nginx-docker-compose.yml build frontend
   docker-compose -f nginx-docker-compose.yml up -d
   ```

### Nginx配置修改

1. 编辑 nginx/nginx.conf 文件
2. 重新构建并启动:

   ```bash
   docker-compose -f nginx-docker-compose.yml down
   docker-compose -f nginx-docker-compose.yml build --no-cache nginx
   docker-compose -f nginx-docker-compose.yml up -d
   ```

### SSL证书更新

1. 更新 Docs/ssl/ 目录中的证书文件
2. 重启Nginx容器:

   ```bash
   docker-compose -f nginx-docker-compose.yml restart nginx
   ```

### 查看日志

```bash
# Nginx日志
docker-compose -f nginx-docker-compose.yml logs -f nginx

# Next.js前端日志
docker-compose -f nginx-docker-compose.yml logs -f frontend
```

## 故障排除

### Nginx无法连接到服务

1. 检查网络配置:

   ```bash
   docker network ls
   ```

   确认app-network和nginx-network已存在

2. 检查服务状态:

   ```bash
   docker-compose -f nginx-docker-compose.yml ps
   docker-compose ps
   ```

3. 检查Nginx配置中的proxy_pass地址是否正确

### 前端构建问题

1. 手动进入前端容器检查:

   ```bash
   docker-compose -f nginx-docker-compose.yml exec frontend sh
   ```

2. 查看Next.js构建日志:

   ```bash
   docker-compose -f nginx-docker-compose.yml logs frontend
   ```

## 共存与独立性

该设置与现有Vapor应用共存但相互独立：

1. 通过独立的docker-compose文件管理，可以单独启动/停止
2. 通过Docker网络bridge连接，实现通信
3. 各自的配置文件分开管理，互不干扰

在停止一项服务而不影响另一项服务时：

```bash
# 只停止Nginx和前端
docker-compose -f nginx-docker-compose.yml down

# 只停止Vapor应用
docker-compose down
```

## 等待名单功能

系统整合了等待名单功能，用户提交的邮箱地址将存储在PostgreSQL数据库中。

1. 前端：Next.js应用提供表单界面
2. 后端：Vapor应用处理数据存储
3. 数据：邮箱存储在`waitlist_entries`表中

查看已注册的等待名单用户：

```bash
# 连接到数据库
docker-compose exec db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

# 查询等待名单
SELECT * FROM waitlist_entries ORDER BY created_at DESC;
```

## 注意事项

1. 第一次部署时，需要确保先启动Vapor应用，创建app-network网络，再启动Nginx和前端
2. 如果修改了服务名称或端口，需同步修改Nginx配置中的proxy_pass地址
3. 前端使用Next.js和TailwindCSS构建，可根据需要进行定制修改
