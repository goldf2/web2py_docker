# web2py Coolify 部署检查清单

## 部署前

- 确认真实应用目录名，不要只看示例 `welcome`。
- 确认数据库类型和位置。
- 确认是否使用 `uploads/`。
- 确认是否依赖 `private/appconfig.ini`。
- 确认是否有 scheduler、cron 或后台任务。

## Coolify 设置

```text
Build pack: Dockerfile
Dockerfile location: ./Dockerfile
Port: 8000
Healthcheck path: /
```

环境变量：

```text
PORT=8000
```

## Persistent Storage

按应用分别挂载：

```text
/app/applications/<app>/databases
/app/applications/<app>/uploads
/app/applications/<app>/sessions
/app/applications/<app>/errors
/app/applications/<app>/private
```

不要挂载整个 `/app/applications`。

## 首次验证

- 首页能打开。
- `/welcome/default/index` 返回 200。
- Coolify healthcheck 通过。
- 日志没有 import error、permission denied、config file not found。
- 数据库读取正常。
- 数据库写入正常。
- 上传文件正常。

## 回滚条件

出现以下情况先回滚，不要在生产流量上继续试错：

- 数据库无法写入。
- 上传文件丢失。
- 登录不可用。
- 大量 500。
- `private/appconfig.ini` 或密钥读取失败。
