# 部署检查清单

本文档用于把现有裸服务器 web2py 项目迁移到 `Coolify / Docker`。目标是先保证可回滚、数据不丢，再切换正式流量。

## 1. 迁移前确认

- 确认当前裸服务器 web2py 能正常访问。
- 确认当前项目的真实应用名，不要只看示例 `welcome`。
- 确认数据库类型：SQLite、MySQL、PostgreSQL、Firestore 或其他。
- 确认是否使用上传文件目录：`applications/<app>/uploads/`。
- 确认是否依赖 `applications/<app>/private/appconfig.ini`。
- 确认是否有计划任务、scheduler、cron 或后台任务。
- 确认当前域名、HTTPS、反向代理配置和端口。

## 2. 冻结旧服务

迁移最终同步前，先暂停会写数据的服务，避免数据库和上传文件在复制过程中变化。

```sh
systemctl stop web2py
```

如果旧服务不是 systemd 管理，按实际方式停止 web2py、Gunicorn、uWSGI 或 Python 进程。

## 3. 完整备份

先备份整个旧目录，再做拆分。不要直接在唯一副本上整理。

```sh
tar -czf web2py-full-backup-$(date +%F-%H%M%S).tar.gz /path/to/web2py
```

如果数据量很大，优先使用 `rsync` 到独立备份目录：

```sh
rsync -a /path/to/web2py/ /backup/web2py-full/
```

## 4. 盘点运行数据

在旧 web2py 根目录执行：

```sh
find applications -maxdepth 3 -type d \
  \( -name databases -o -name uploads -o -name sessions -o -name errors -o -name cache -o -name private \) \
  | sort
```

重点确认这些目录：

- `applications/<app>/databases/`
- `applications/<app>/uploads/`
- `applications/<app>/sessions/`
- `applications/<app>/errors/`
- `applications/<app>/private/`

## 5. 分离代码和数据

代码进入 Git 仓库和 Docker 镜像，运行数据进入持久化目录。

推荐迁移到这种结构：

```text
/opt/web2py/app/                  # 代码目录
/srv/web2py-data/<app>/            # 数据目录
```

复制数据目录：

```sh
mkdir -p /srv/web2py-data/<app>
rsync -a applications/<app>/databases /srv/web2py-data/<app>/
rsync -a applications/<app>/uploads /srv/web2py-data/<app>/
rsync -a applications/<app>/sessions /srv/web2py-data/<app>/
rsync -a applications/<app>/errors /srv/web2py-data/<app>/
rsync -a applications/<app>/private /srv/web2py-data/<app>/
```

如果某个目录不存在，可以跳过对应命令。

## 6. 检查 Git 内容

确认 Git 只保留代码和必要静态资源，不提交运行数据或密钥。

```sh
git status --short
```

不应该进入 Git 的内容：

- `applications/*/databases/`
- `applications/*/uploads/`
- `applications/*/sessions/`
- `applications/*/errors/`
- `applications/*/cache/`
- `applications/*/private/` 中的密钥和生产配置

## 7. Coolify 配置

在 Coolify 中创建应用时使用：

```text
Build pack: Dockerfile
Dockerfile location: ./Dockerfile
Port: 8000
Healthcheck path: /
```

环境变量至少确认：

```text
PORT=8000
```

如果使用 Firestore 或 Google Cloud 凭据，使用 Coolify Secret 或文件挂载，不要把凭据提交到 Git。

## 8. Coolify 持久化挂载

不要挂载整个 `applications/`，否则会覆盖镜像里的应用代码。

按应用目录分别挂载：

```text
/app/applications/<app>/databases
/app/applications/<app>/uploads
/app/applications/<app>/sessions
/app/applications/<app>/errors
```

如果应用仍读取 `private/appconfig.ini`，还需要挂载：

```text
/app/applications/<app>/private
```

## 9. 首次部署验证

部署后先不要切正式流量，使用 Coolify 生成的临时域名或预览地址验证。

基础验证：

- 首页能打开。
- web2py 没有 500 错误。
- 容器健康检查通过。
- Coolify 日志没有明显 import error、permission denied、config file not found。

功能验证：

- 登录流程正常。
- 数据库读取正常。
- 数据库写入正常。
- 上传文件正常。
- 已上传文件可访问。
- `private/appconfig.ini` 或环境变量被正确读取。
- 如果使用定时任务，确认任务能运行。

## 10. 切换正式流量

确认新部署可用后再切换域名或反向代理。

切换前：

- 再做一次最终数据同步。
- 保留旧服务器，不要立即删除。
- 记录旧服务器回滚入口。

切换后观察：

- 访问日志。
- 500 错误。
- 登录和写入功能。
- 上传目录权限。
- 数据库锁或 SQLite 写入异常。

## 11. 回滚条件

出现以下情况时应优先回滚，不要在生产流量上继续试错：

- 数据库无法写入。
- 上传文件丢失或权限错误。
- 登录不可用。
- 大量 500 错误。
- 配置文件或密钥读取失败。
- 业务核心页面不可用。

回滚方式：

1. 把域名或反向代理切回旧裸服务器。
2. 停止新容器写入，避免产生分叉数据。
3. 保留 Coolify 日志和容器状态用于排查。
4. 修复后重新同步数据，再进行下一次切换。

## 12. 上线后收尾

- 确认 Coolify 持久化目录有备份策略。
- 确认 `private/appconfig.ini` 中没有长期保留明文密钥，逐步迁移到 Secret。
- 确认旧服务器保留一段观察期后再下线。
- 记录最终挂载路径、环境变量、域名和回滚方式。
