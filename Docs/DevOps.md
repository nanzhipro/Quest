# 高级功能设备白名单管理

## 概述

本文档描述了如何管理允许访问高级功能的设备白名单。系统支持两种方式启用高级功能:

1. **全局启用**: 通过环境变量 `ENABLE_PREMIUM_FEATURES_WHEN_UNSUBSCRIBED` 设置为 `true`，所有用户都能访问高级功能
2. **设备白名单**: 当全局设置关闭时，只有在白名单中的设备才能访问高级功能

## 环境变量配置

在 `.env` 文件中设置:

```
# 当未订阅时是否全局启用高级功能 (true/false)
ENABLE_PREMIUM_FEATURES_WHEN_UNSUBSCRIBED=false
```

## 白名单设备管理

### 添加设备到白名单

**请求**:

```bash
curl -X POST "https://your-api-server.com/api/v1/premium-features/admin/add-device" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  -d '{
    "deviceUUID": "F8D75B3E-C25A-4FDA-B9D6-5D83748F1111",
    "expiresAt": "2024-12-31T23:59:59Z"
  }'
```

> 注意: `expiresAt` 字段是可选的。不设置表示永不过期。

### 从白名单中移除设备

**请求**:

```bash
curl -X DELETE "https://your-api-server.com/api/v1/premium-features/admin/remove-device/F8D75B3E-C25A-4FDA-B9D6-5D83748F1111" \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN"
```

## 数据库管理

### 白名单表结构

表名: `premium_device_whitelist`

| 字段名 | 类型 | 描述 |
|--------|------|------|
| id | UUID | 主键 |
| device_uuid | String | 设备唯一标识符 |
| created_at | Timestamp | 记录创建时间 |
| expires_at | Timestamp | 访问权限过期时间 (可为空) |

### 手动查询白名单

```sql
-- 查看所有白名单设备
SELECT * FROM premium_device_whitelist;

-- 查看已过期的设备
SELECT * FROM premium_device_whitelist WHERE expires_at < NOW();

-- 查看特定设备的状态
SELECT * FROM premium_device_whitelist WHERE device_uuid = 'F8D75B3E-C25A-4FDA-B9D6-5D83748F1111';
```

### 手动管理白名单

```sql
-- 添加设备到白名单 (永久有效)
INSERT INTO premium_device_whitelist (id, device_uuid, created_at) 
VALUES (gen_random_uuid(), 'F8D75B3E-C25A-4FDA-B9D6-5D83748F1111', NOW());

-- 添加设备到白名单 (有过期时间)
INSERT INTO premium_device_whitelist (id, device_uuid, created_at, expires_at) 
VALUES (gen_random_uuid(), 'F8D75B3E-C25A-4FDA-B9D6-5D83748F1111', NOW(), '2024-12-31 23:59:59');

-- 更新现有设备的过期时间
UPDATE premium_device_whitelist 
SET expires_at = '2025-01-31 23:59:59' 
WHERE device_uuid = 'F8D75B3E-C25A-4FDA-B9D6-5D83748F1111';

-- 从白名单中删除设备
DELETE FROM premium_device_whitelist 
WHERE device_uuid = 'F8D75B3E-C25A-4FDA-B9D6-5D83748F1111';

-- 清理已过期的设备记录
DELETE FROM premium_device_whitelist WHERE expires_at < NOW();
```

## 监控与维护建议

1. **定期清理过期记录**: 创建定时任务自动清理已过期的白名单记录
2. **监控白名单规模**: 当白名单设备数量过大时考虑优化数据库查询
3. **日志记录**: 启用白名单设备的访问日志，便于故障排查
4. **备份**: 定期备份白名单数据，防止意外丢失

## 安全提示

1. 确保 Admin API 端点受到严格的认证和授权保护
2. 考虑为 Admin API 操作增加审计日志
3. 定期轮换管理员 JWT Token
4. 对外部请求实施速率限制，防止枚举攻击
