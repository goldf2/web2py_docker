# 本地运行说明

## 启动目录

本项目本地运行启动目录固定为：

```sh
/Volumes/project/开发中/web2py_docker
```

## 启动命令

```sh
cd /Volumes/project/开发中/web2py_docker
./scripts/start-local-web2py.sh
```

启动后访问：

```text
http://127.0.0.1:8000/
http://127.0.0.1:8000/welcome/default/index
http://127.0.0.1:8000/admin/default/site
```

本地 admin 默认密码：

```text
localadmin
```

## 停止命令

```sh
cd /Volumes/project/开发中/web2py_docker
./scripts/stop-local-web2py.sh
```

## 说明

本地 macOS 运行使用 `web2py.py --no_gui`，用于页面和应用调试。Docker/Coolify 部署仍使用 Dockerfile 中的 Gunicorn 启动方式。

启动脚本会通过 macOS `launchctl` 创建本地用户服务：

```text
~/Library/LaunchAgents/com.local.web2py-docker.plist
```

部分历史 app 的运行目录使用 `/data/web2py-cxmj/...` 绝对软链接；macOS 本机 `/data` 为只读时，不应强行修改系统目录。本地基础验证优先使用 `welcome` 和 `admin`。
