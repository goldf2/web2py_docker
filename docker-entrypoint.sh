#!/bin/sh
set -eu

APP_ROOT="${APP_ROOT:-/app}"
WEB2PY_RUNTIME_ROOT="${WEB2PY_RUNTIME_ROOT:-$APP_ROOT/runtime}"
WEB2PY_RUNTIME_DIRS="${WEB2PY_RUNTIME_DIRS:-databases uploads sessions errors cache private}"
WEB2PY_RUNTIME_SKIP_APPS="${WEB2PY_RUNTIME_SKIP_APPS:-admin welcome}"

mkdir -p "$WEB2PY_RUNTIME_ROOT"

for app_dir in "$APP_ROOT"/applications/*; do
    [ -d "$app_dir" ] || continue
    app_name="$(basename "$app_dir")"
    case " $WEB2PY_RUNTIME_SKIP_APPS " in
        *" $app_name "*)
            for runtime_dir in $WEB2PY_RUNTIME_DIRS; do
                mkdir -p "$app_dir/$runtime_dir"
            done
            continue
            ;;
    esac
    for runtime_dir in $WEB2PY_RUNTIME_DIRS; do
        target_dir="$WEB2PY_RUNTIME_ROOT/$app_name/$runtime_dir"
        link_path="$app_dir/$runtime_dir"

        mkdir -p "$target_dir"

        if [ -L "$link_path" ]; then
            current_target="$(readlink "$link_path" || true)"
            [ "$current_target" = "$target_dir" ] || {
                rm -f "$link_path"
                ln -s "$target_dir" "$link_path"
            }
        elif [ -e "$link_path" ]; then
            if [ -d "$link_path" ] && [ -z "$(find "$link_path" -mindepth 1 -maxdepth 1 2>/dev/null)" ]; then
                rmdir "$link_path"
                ln -s "$target_dir" "$link_path"
            fi
        else
            ln -s "$target_dir" "$link_path"
        fi
    done
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
