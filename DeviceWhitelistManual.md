# 设备白名单管理命令使用手册

## 概述

`device-whitelist` 命令提供了管理高级功能设备白名单的命令行工具，支持添加、删除和查看白名单中的设备。该工具遵循 Swift API 设计最佳实践，提供直观的命令界面和全面的错误处理。

## 前提条件

- 已安装 Swift 和 Vapor 框架
- 已配置正确的数据库连接
- 已完成 `PremiumDeviceWhitelist` 数据表迁移

## 命令概览

`device-whitelist` 命令支持以下三种主要操作：

1. **添加设备** (`add`): 将设备UUID添加到白名单
2. **删除设备** (`remove`): 从白名单中删除设备UUID
3. **列出设备** (`list`): 显示当前白名单中的所有设备

## 详细用法

### 1. 添加设备到白名单

```bash
# 添加设备，永不过期
swift run App device-whitelist add --uuid F8D75B3E-C25A-4FDA-B9D6-5D83748F1111

# 添加设备，指定过期日期（将在指定日期的23:59:59过期）
swift run App device-whitelist add --uuid F8D75B3E-C25A-4FDA-B9D6-5D83748F1111 --expires 2024-12-31

# 添加设备（使用短参数形式）
swift run App device-whitelist add -u F8D75B3E-C25A-4FDA-B9D6-5D83748F1111 -e 2024-12-31
```

**参数说明：**

- `--uuid` (`-u`): 设备的唯一标识符，必需参数
- `--expires` (`-e`): 设备白名单的过期日期，可选参数，格式为 `YYYY-MM-DD`

**注意事项：**

- 如果设备已在白名单中，此命令将更新其过期时间
- 如果不指定过期日期，设备将永久有效
- 过期日期自动设置为指定日期的最后一秒 (23:59:59)

### 2. 从白名单中删除设备

```bash
# 删除设备
swift run App device-whitelist remove --uuid F8D75B3E-C25A-4FDA-B9D6-5D83748F1111

# 删除设备（使用短参数形式）
swift run App device-whitelist remove -u F8D75B3E-C25A-4FDA-B9D6-5D83748F1111
```

**参数说明：**

- `--uuid` (`-u`): 要删除的设备唯一标识符，必需参数

**注意事项：**

- 如果指定的设备不在白名单中，命令将显示警告信息但不会产生错误
- 删除操作是永久的，无法撤销

### 3. 列出白名单设备

```bash
# 列出所有白名单设备（包括已过期的）
swift run App device-whitelist list

# 只列出有效的白名单设备（未过期的）
swift run App device-whitelist list --valid-only

# 只列出有效的白名单设备（使用短参数形式）
swift run App device-whitelist list -v
```

**参数说明：**

- `--valid-only` (`-v`): 是否只显示有效的（未过期）设备，可选标志

**输出说明：**
命令输出包含以下信息：

- 设备UUID
- 添加时间
- 过期时间（如果设置）
- 过期状态（如果已过期）

## 示例场景

### 场景1：添加测试设备进行功能验证

```bash
# 添加测试设备，有效期30天
swift run App device-whitelist add --uuid $(uuidgen) --expires $(date -v+30d +%Y-%m-%d)
```

### 场景2：清理过期设备

```bash
# 1. 先查看所有设备
swift run App device-whitelist list

# 2. 找出已过期的设备并删除
swift run App device-whitelist remove --uuid <已过期设备UUID>
```

### 场景3：批量导入设备列表

可以创建一个简单的脚本：

```bash
#!/bin/bash
# batch_import.sh

while IFS=, read -r uuid expires
do
  if [ -z "$expires" ]; then
    swift run App device-whitelist add --uuid "$uuid"
  else
    swift run App device-whitelist add --uuid "$uuid" --expires "$expires"
  fi
done < devices.csv
```

设备列表文件 `devices.csv` 格式：

```
F8D75B3E-C25A-4FDA-B9D6-5D83748F1111,2024-12-31
A7C64D2F-B14A-3ECA-A8C5-4C72637E2222,
```

## 错误处理

命令会处理常见错误并提供明确的错误消息：

- **无效的操作类型**：如果指定了除 add、remove、list 之外的操作
- **缺少设备UUID**：add 和 remove 操作必须提供 UUID
- **无效的日期格式**：过期日期必须使用 YYYY-MM-DD 格式
- **数据库错误**：与数据库交互时可能发生的错误

## 最佳实践

1. **UUID管理**：妥善保管设备UUID列表，可使用专用文档或密码管理工具
2. **设置合理过期时间**：根据业务需求为测试设备设置适当的过期时间
3. **定期审计**：定期检查白名单设备，清理不再需要的记录
4. **操作日志**：考虑记录重要的白名单管理操作，便于审计

## 故障排除

如果遇到以下问题，请尝试相应的解决方案：

1. **命令不可用**：
   - 检查是否已在 `configure.swift` 中注册命令
   - 确认项目编译无错误

2. **数据库错误**：
   - 验证数据库连接配置
   - 确认已执行 `CreatePremiumDeviceWhitelist` 迁移

3. **UUID相关错误**：
   - 确保UUID格式正确（标准UUID包含32个十六进制字符，以及4个连字符）
   - 避免使用特殊字符或空格

## 安全注意事项

- 白名单管理命令应仅允许授权人员使用
- 确保服务器环境安全，限制命令行访问权限
- 定期审查白名单设备，避免权限泄露
