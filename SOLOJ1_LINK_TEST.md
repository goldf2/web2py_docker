# soloj1 软链接测试说明

`soloj1` 是远程容器验证用的最小 web2py app，用来测试：

- 容器内部软链接是否可读写。
- Coolify Persistent Storage 挂载目录作为软链接目标时，容器内是否能正常访问。

## Docker 打包范围

当前 Docker 镜像只打包这些 web2py app：

```text
applications/admin    # 内置默认应用，不做运行目录软链接
applications/welcome  # 内置默认应用，不做运行目录软链接
applications/soloj1   # 业务/测试应用，运行目录软链接到 /app/runtime/soloj1
```

其它历史测试 app 不进入 Docker 构建上下文，避免镜像过大。

运行数据仍不打入镜像：

```text
applications/*/databases
applications/*/uploads
applications/*/sessions
applications/*/errors
applications/*/cache
applications/*/private
```

## 测试地址

部署后先访问：

```text
https://你的域名/soloj1/default/index
```

准备测试软链接：

```text
https://你的域名/soloj1/default/link_prepare
```

查看软链接状态：

```text
https://你的域名/soloj1/default/link_status
```

## 外部挂载测试

默认外部软链接目标：

```text
/app/runtime/soloj1-external-target
```

Coolify 可以把主机目录挂载到这个容器目录，用来验证“外部存储目录作为容器内软链接目标”的运行情况。

可选环境变量：

```text
SOLOJ1_EXTERNAL_LINK_TARGET=/app/runtime/soloj1-external-target
```

如果 `link_prepare` 成功，`link_status` 里应看到：

- `internal_link.is_link = true`
- `internal_link.exists = true`
- `external_link.is_link = true`
- `external_link.exists = true`
- `external_target.writable = true`
