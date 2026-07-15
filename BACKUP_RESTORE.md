# 备份与恢复方案

本文档用于 web2py 从裸服务器迁移到 `Coolify / Docker` 后的备份和恢复。原则是：**代码靠 Git，镜像靠 Dockerfile，数据靠独立备份。**

## 1. 必须备份的内容

每个业务应用至少备份这些目录：

```text
applications/<app>/databases/
applications/<app>/uploads/
applications/<app>/private/
```

按需要备份：

```text
applications/<app>/sessions/
applications/<app>/errors/
```

通常不需要长期备份：

```text
applications/<app>/cache/
```

## 2. 代码备份

代码以 Git 为准。

上线前确认：

```sh
git status --short
git log --oneline -5
```

不要把数据库、上传文件、会话、错误票据、生产密钥提交到 Git。

## 3. SQLite 备份

如果使用 web2py 默认 SQLite，常见文件位置是：

```text
applications/<app>/databases/storage.sqlite
```

服务停止时可以直接复制：

```sh
systemctl stop web2py
cp applications/<app>/databases/storage.sqlite /backup/storage.sqlite.$(date +%F-%H%M%S)
systemctl start web2py
```

服务运行时建议使用 SQLite 在线备份命令：

```sh
sqlite3 applications/<app>/databases/storage.sqlite ".backup '/backup/storage.sqlite.$(date +%F-%H%M%S)'"
```

如果容器内没有 `sqlite3`，可以在宿主机或备份机上对持久化目录执行。

## 4. 上传文件备份

上传文件通常在：

```text
applications/<app>/uploads/
```

推荐用 `rsync` 做增量备份：

```sh
rsync -a --delete applications/<app>/uploads/ /backup/web2py/<app>/uploads/
```

如果上传文件非常重要，至少保留多天快照，避免一次误删同步到备份目录。

## 5. private 配置备份

`private/` 里可能有 `appconfig.ini`、认证 key、第三方服务配置。

```text
applications/<app>/private/
```

备份要求：

- 不提交到 Git。
- 不放进公开镜像。
- 使用加密备份或受限权限目录。
- Coolify 中优先使用 Secret；必须用文件时，再使用持久化挂载或文件挂载。

## 6. Coolify 持久化目录备份

在 Coolify 中，需要确认每个挂载目录对应的宿主机路径或卷。

建议至少备份：

```text
/app/applications/<app>/databases
/app/applications/<app>/uploads
/app/applications/<app>/private
```

可选备份：

```text
/app/applications/<app>/sessions
/app/applications/<app>/errors
```

不要只备份 Docker 镜像。镜像里应该只有代码，真实业务数据在持久化存储里。

## 7. 恢复到 Coolify

恢复顺序：

1. 从 Git 部署对应版本代码。
2. 确认 Docker 镜像可以正常构建。
3. 停止应用容器。
4. 恢复持久化目录。
5. 确认目录权限允许容器内 `web2py` 用户读写。
6. 启动容器。
7. 验证首页、登录、数据库写入和上传文件。

示例：

```sh
rsync -a /backup/web2py/<app>/databases/ /path/to/coolify-volume/databases/
rsync -a /backup/web2py/<app>/uploads/ /path/to/coolify-volume/uploads/
rsync -a /backup/web2py/<app>/private/ /path/to/coolify-volume/private/
```

如果恢复后出现权限问题，检查容器内运行用户和挂载目录所有者。

## 8. 恢复到裸服务器

如果需要回滚到旧裸服务器：

1. 停止 Coolify 容器，避免继续写入新数据。
2. 把最新持久化数据同步回裸服务器应用目录。
3. 恢复 `private/appconfig.ini` 和必要密钥。
4. 启动裸服务器 web2py 服务。
5. 把域名或反向代理切回裸服务器。

示例：

```sh
rsync -a /backup/web2py/<app>/databases/ /path/to/web2py/applications/<app>/databases/
rsync -a /backup/web2py/<app>/uploads/ /path/to/web2py/applications/<app>/uploads/
rsync -a /backup/web2py/<app>/private/ /path/to/web2py/applications/<app>/private/
```

## 9. 备份验证

备份没有验证就不算可靠。

至少定期检查：

- 备份文件是否存在。
- SQLite 文件能否打开。
- 上传文件数量是否明显异常。
- `private/appconfig.ini` 是否存在且权限受限。
- 从备份恢复到测试环境后，页面能否打开。

SQLite 快速检查：

```sh
sqlite3 /backup/storage.sqlite "PRAGMA integrity_check;"
```

期望输出：

```text
ok
```

## 10. 建议备份频率

| 数据类型 | 建议频率 | 说明 |
| --- | --- | --- |
| SQLite 数据库 | 每天，重要业务可每小时 | 写入频繁时提高频率 |
| 上传文件 | 每天增量 | 保留历史快照，防误删 |
| private 配置 | 每次变更后 | 必须限制访问权限 |
| 代码 | 每次变更提交 Git | 不依赖服务器本地副本 |
| sessions | 可选 | 通常可丢失，影响在线登录状态 |
| errors | 可选 | 适合问题排查，不是核心业务数据 |

## 11. 最小备份策略

如果先做一个低成本版本，至少保证：

1. Git 仓库保存所有代码。
2. 每天备份 `databases/`。
3. 每天备份 `uploads/`。
4. 每次配置变更后备份 `private/`。
5. 每次上线前手动做一次完整备份。
