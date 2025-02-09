#!/bin/bash

# 复制新证书
sudo cp /etc/letsencrypt/live/www.schedulesage.cn/fullchain.pem ./Docs/ssl/cert.pem
sudo cp /etc/letsencrypt/live/www.schedulesage.cn/privkey.pem ./Docs/ssl/key.pem

# 设置权限
sudo chown -R $USER:$USER ./Docs/ssl
chmod 600 ./Docs/ssl/*.pem

# 重启 Vapor 应用
docker compose restart app
