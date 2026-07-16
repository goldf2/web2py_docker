# Deploy to Coolify

This repository can be deployed by Coolify as a Dockerfile application.

Related migration documents:

- `SYSTEM_ARCHITECTURE.md`: architecture diagrams and Docker vs bare-server comparison.
- `DATA_CODE_SEPARATION.md`: code/data separation rules for existing bare-server deployments.
- `DEPLOYMENT_CHECKLIST.md`: step-by-step production migration checklist.
- `BACKUP_RESTORE.md`: backup and restore plan for persistent web2py data.

## Coolify settings

- Build pack: `Dockerfile`
- Dockerfile location: `./Dockerfile`
- Port: `8000`
- Healthcheck path: `/`
- Environment variables: copy the needed values from `.env.example`

Optional admin environment variable:

```text
WEB2PY_ADMIN_PASSWORD=your-strong-admin-password
```

Recommended runtime data environment variable:

```text
WEB2PY_RUNTIME_ROOT=/app/runtime
WEB2PY_RUNTIME_SKIP_APPS=admin welcome
```

Recommended persistent storage:

```text
Host path:      /opt/web2py
Container path: /app/runtime
```

At startup, `docker-entrypoint.sh` automatically creates runtime directories and symlinks for business apps. Built-in apps such as `admin` and `welcome` stay inside the container by default, using ordinary non-persistent runtime directories.

```text
/app/applications/<app>/databases -> /app/runtime/<app>/databases
/app/applications/<app>/uploads   -> /app/runtime/<app>/uploads
/app/applications/<app>/sessions  -> /app/runtime/<app>/sessions
/app/applications/<app>/errors    -> /app/runtime/<app>/errors
/app/applications/<app>/cache     -> /app/runtime/<app>/cache
/app/applications/<app>/private   -> /app/runtime/<app>/private
```

When adding a new app, no new Coolify storage entry is required as long as `/app/runtime` is already mounted. The entrypoint will create `/app/runtime/<new-app>/...` automatically on container start.

The admin app must be accessed over HTTPS when used remotely. Plain HTTP remote access to `/admin` is blocked by web2py as an insecure channel.

The container starts web2py with:

```sh
python anyserver.py -s gunicorn -i 0.0.0.0 -p ${PORT:-8000}
```

Coolify can inject `PORT`; otherwise the image listens on `8000`.

## Runtime dependencies

The original web2py repository expects these Git submodules:

- `pydal`
- `rocket3`
- `yatl`

For Docker builds, they are installed from `requirements.txt` so Coolify does not need to initialize Git submodules.

## Persistent data

web2py writes runtime data under each application directory, especially:

- `applications/<app>/databases`
- `applications/<app>/sessions`
- `applications/<app>/errors`
- `applications/<app>/uploads`
- `applications/<app>/private` when the app still reads `private/appconfig.ini`

For a production app, prefer one persistent storage root mounted at `/app/runtime`. Avoid mounting an empty volume over the whole `applications` directory unless you also initialize it with your app files, because that hides the applications copied into the image.

The Docker build excludes runtime data and private config from the image. For existing bare-server deployments, migrate those directories into Coolify persistent storage before switching traffic. See `DATA_CODE_SEPARATION.md` for the full migration checklist.

## Local test

```sh
docker compose up --build
```

Then open:

```text
http://localhost:8000/
```
