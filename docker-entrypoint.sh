#!/bin/sh
set -eu

APP_ROOT="${APP_ROOT:-/app}"

for app_dir in "$APP_ROOT"/applications/*; do
    [ -d "$app_dir" ] || continue
    mkdir -p \
        "$app_dir/databases" \
        "$app_dir/uploads" \
        "$app_dir/sessions" \
        "$app_dir/errors" \
        "$app_dir/private"
done

welcome_config="$APP_ROOT/applications/welcome/private/appconfig.ini"
if [ ! -f "$welcome_config" ] && [ -d "$APP_ROOT/applications/welcome" ]; then
    cat > "$welcome_config" <<'EOF'
; Runtime default for the scaffold welcome app.
; Production apps should provide their own private/appconfig.ini via persistent storage or secrets.

[app]
name        = Welcome
author      = Your Name <you@example.com>
description = a cool new app
keywords    = web2py, python, framework
generator   = Web2py Web Framework
production  = false
toolbar     = false

[host]
names = localhost:*, 127.0.0.1:*, *:*, *

[db]
uri       = sqlite://storage.sqlite
migrate   = true
pool_size = 10

[smtp]
server = logging
sender = you@example.com
login  =
tls    = false
ssl    = false

[scheduler]
enabled   = false
heartbeat = 1

[google]
analytics_id =
EOF
fi

if [ -n "${WEB2PY_ADMIN_PASSWORD:-}" ]; then
    python - <<'PY'
import os
from gluon.validators import CRYPT

port = int(os.environ.get("PORT", "8000"))
password = os.environ["WEB2PY_ADMIN_PASSWORD"]
path = os.path.join(os.environ.get("APP_ROOT", "/app"), f"parameters_{port}.py")

with open(path, "w", encoding="utf-8") as fp:
    fp.write('password="%s"\n' % CRYPT()(password)[0])
PY
fi

exec "$@"
