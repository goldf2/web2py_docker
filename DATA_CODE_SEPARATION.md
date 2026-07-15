# web2py 代码与数据分离

Docker 部署时必须把代码、运行数据、密钥分开。

## 分离原则

| 类型 | 示例路径 | 放置位置 |
| --- | --- | --- |
| 框架代码 | `gluon/`、`web2py.py`、`anyserver.py` | Git 仓库和 Docker 镜像 |
| 应用代码 | `applications/<app>/models`、`controllers`、`views`、`modules`、`static` | Git 仓库和 Docker 镜像 |
| 数据库 | `applications/<app>/databases/` | Persistent Storage |
| 上传文件 | `applications/<app>/uploads/` | Persistent Storage |
| 会话 | `applications/<app>/sessions/` | Persistent Storage，可按需清理 |
| 错误票据 | `applications/<app>/errors/` | Persistent Storage 或日志归档 |
| 私有配置 | `applications/<app>/private/` | Secret、文件挂载或 Persistent Storage |

一句话：代码进镜像，运行数据进挂载，密钥进 Secret。

## 推荐挂载

```text
主机目录                                  容器目录
/opt/web2py-data/<app>/databases   ->    /app/applications/<app>/databases
/opt/web2py-data/<app>/uploads     ->    /app/applications/<app>/uploads
/opt/web2py-data/<app>/sessions    ->    /app/applications/<app>/sessions
/opt/web2py-data/<app>/errors      ->    /app/applications/<app>/errors
/opt/web2py-data/<app>/private     ->    /app/applications/<app>/private
```

不要挂载：

```text
/app
/app/applications
/app/applications/<app>
```

这些路径会覆盖镜像中的代码。

## 默认启动行为

`docker-entrypoint.sh` 会在容器启动时：

- 为每个 `applications/<app>/` 创建缺失的 `databases/`、`uploads/`、`sessions/`、`errors/`、`private/`。
- 如果示例 `welcome` 缺少 `private/appconfig.ini`，生成一个仅用于冒烟测试的默认配置。

正式业务应用仍然需要挂载真实 `private/appconfig.ini`。
