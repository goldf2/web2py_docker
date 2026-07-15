# Coolify 部署说明

本仓库可以作为 Coolify 的 Dockerfile 应用部署。

## Coolify 配置

```text
Build pack: Dockerfile
Dockerfile location: ./Dockerfile
Port: 8000
Healthcheck path: /
```

环境变量至少配置：

```text
PORT=8000
```

容器启动命令：

```sh
python anyserver.py -s gunicorn -i 0.0.0.0 -p ${PORT:-8000}
```

## 依赖策略

Docker 构建通过 `requirements.txt` 安装：

- `pydal`
- `rocket3`
- `yatl`

所以 Coolify 不需要执行 `git submodule update --init --recursive`。

本地源码开发如果不想拉子模块，也可以使用 venv：

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
python web2py.py --no_gui -a '<recycle>' -i 127.0.0.1 -p 8000 -e
```

macOS 下不要直接运行 `python3 web2py.py`，它会启动 GUI，可能因为系统 Python 和图形组件版本不匹配而崩溃。

## 持久化存储

不要挂载整个 `/app` 或 `/app/applications`，否则会覆盖镜像中的代码。

按实际应用名分别挂载运行数据目录：

```text
/app/applications/<app>/databases
/app/applications/<app>/uploads
/app/applications/<app>/sessions
/app/applications/<app>/errors
/app/applications/<app>/private
```

如果只是冒烟测试 `welcome` 应用，可以先不挂载。`docker-entrypoint.sh` 会为 `welcome` 生成一个默认 `private/appconfig.ini`，确保 `/welcome/default/index` 可以打开。

正式业务应用必须通过 Persistent Storage 或 Secret 提供自己的 `private/appconfig.ini`、数据库和上传文件。
