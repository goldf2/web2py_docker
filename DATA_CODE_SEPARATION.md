# 代码与数据分离方案

当前主要问题不是 web2py 能不能跑在 Docker 里，而是裸服务器上已经把代码、数据库、上传文件、会话、错误日志和私有配置混在同一个 `applications/<app>/` 目录里。迁移到 Coolify / Docker 前，必须先定义清楚边界。

## 分离原则

| 类型 | 示例路径 | 应该放哪里 |
| --- | --- | --- |
| 框架代码 | `gluon/`、`web2py.py`、`anyserver.py` | Git 仓库和 Docker 镜像 |
| 应用代码 | `applications/<app>/models`、`controllers`、`views`、`modules`、`static`、`cron`、`languages` | Git 仓库和 Docker 镜像 |
| 数据库文件 | `applications/<app>/databases/` | 持久化数据目录 |
| 上传文件 | `applications/<app>/uploads/` | 持久化数据目录 |
| 会话文件 | `applications/<app>/sessions/` | 持久化数据目录，可按需清理 |
| 错误票据 | `applications/<app>/errors/` | 持久化数据目录或日志归档 |
| 缓存 | `applications/<app>/cache/` | 运行时目录，可重建 |
| 私有配置和密钥 | `applications/<app>/private/` | 优先环境变量或 Coolify Secret；必要时挂载文件 |

一句话规则：**代码进 Git 和镜像，运行数据进持久化存储，密钥进环境变量或 Secret。**

## 当前仓库里的混合数据

当前已经能看到这些运行数据或私有配置：

```text
applications/welcome/databases/storage.sqlite
applications/welcome/databases/*.table
applications/welcome/databases/sql.log
applications/welcome/private/appconfig.ini
applications/welcome/sessions/
applications/welcome/errors/
applications/welcome/uploads/
```

这些内容不应该被打进 Docker 镜像。`.dockerignore` 已经排除了：

```text
applications/*/databases/
applications/*/uploads/
applications/*/sessions/
applications/*/errors/
applications/*/cache/
applications/*/private/
```

## 推荐目录结构

裸服务器迁移前，可以先整理成这种逻辑结构：

```text
/opt/web2py/app/                  # 代码目录，可由 Git 管理
  gluon/
  web2py.py
  anyserver.py
  applications/<app>/models/
  applications/<app>/controllers/
  applications/<app>/views/
  applications/<app>/modules/
  applications/<app>/static/

/srv/web2py-data/<app>/            # 数据目录，不进 Git
  databases/
  uploads/
  sessions/
  errors/
  private/
```

迁移到 Coolify 后，`/srv/web2py-data/<app>/` 对应 Coolify 的 persistent storage。

## Docker 部署时的挂载思路

不要把空卷直接挂到整个 `applications/`，否则会把镜像里的应用代码盖掉。

推荐只挂载一个运行数据根目录：

```text
主机目录: /opt/web2py
容器目录: /app/runtime
```

容器启动时，`docker-entrypoint.sh` 会自动为业务应用创建运行数据目录，并把应用内部目录软链接过去。默认跳过 `admin` 和 `welcome`，因为它们是 web2py 内置默认应用，只在容器内使用普通非持久化运行目录：

```text
/app/applications/<app>/databases -> /app/runtime/<app>/databases
/app/applications/<app>/uploads   -> /app/runtime/<app>/uploads
/app/applications/<app>/sessions  -> /app/runtime/<app>/sessions
/app/applications/<app>/errors    -> /app/runtime/<app>/errors
/app/applications/<app>/cache     -> /app/runtime/<app>/cache
```

这样新建 app 后不需要在 Coolify 里逐个增加挂载，只要重新部署或重启容器，入口脚本会自动创建 `/app/runtime/<new-app>/...` 并建立软链接。

`private/` 默认不外置为可写目录。它通常存放配置和密钥，应优先使用 Coolify 环境变量或 Secret。短期必须保留 `private/appconfig.ini` 时，建议单独挂载该文件或目录，并尽量只读。

## 迁移步骤

1. 停止裸服务器上的 web2py 服务，避免迁移时数据库和上传文件继续变化。
2. 备份整个现有 web2py 目录。
3. 列出每个应用目录下的运行数据：

```sh
find applications -maxdepth 3 -type d \
  \( -name databases -o -name uploads -o -name sessions -o -name errors -o -name cache \) \
  | sort
```

4. 把运行数据复制到独立数据目录：

```sh
mkdir -p /srv/web2py-data/<app>
rsync -a applications/<app>/databases /srv/web2py-data/<app>/
rsync -a applications/<app>/uploads /srv/web2py-data/<app>/
rsync -a applications/<app>/sessions /srv/web2py-data/<app>/
rsync -a applications/<app>/errors /srv/web2py-data/<app>/
```

5. 确认 Git 只管理代码目录，不管理运行数据目录。
6. 在 Coolify 中创建 persistent storage，把主机数据根目录挂载到容器 `/app/runtime`。
7. 把 `appconfig.ini` 里的数据库、SMTP、第三方服务密钥迁移到 Coolify 环境变量或 Secret。
8. 部署 Docker 版本，确认页面、登录、上传、数据库读写都正常。
9. 确认新部署正常后，再下线旧裸服务器服务。

## appconfig.ini 的处理

web2py 默认会读取 `applications/<app>/private/appconfig.ini`。这个文件通常包含：

```ini
[db]
uri = sqlite://storage.sqlite

[smtp]
server = smtp.gmail.com:587
sender = you@gmail.com
login = username:password
```

迁移建议：

- 数据库 URI、SMTP 密码、第三方 API Key 不要提交到 Git。
- 如果短期内不改代码，可以把 `private/appconfig.ini` 作为 Coolify 挂载文件处理。
- 如果愿意做进一步改造，建议让应用代码从环境变量读取敏感配置，再逐步减少对 `private/appconfig.ini` 的依赖。

## 最小可执行方案

如果只想先完成从裸服务器到 Coolify 的稳定迁移，按这个顺序做：

1. 镜像里只放代码。
2. 主机 `/opt/web2py` 挂载到容器 `/app/runtime`。
3. `docker-entrypoint.sh` 自动创建每个 app 的运行目录软链接。
4. `private/appconfig.ini` 暂时通过 Coolify 文件挂载或环境变量处理，不放入默认可写 runtime。
5. 部署成功后，再把敏感配置逐步改成环境变量。
