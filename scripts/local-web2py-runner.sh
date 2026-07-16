#!/bin/sh
set -eu

ROOT_DIR="/Volumes/project/开发中/web2py_docker"
PORT="${PORT:-8000}"
PASSWORD="${WEB2PY_ADMIN_PASSWORD:-localadmin}"
LOG_FILE="$ROOT_DIR/logs/local-web2py-$PORT.log"
PID_FILE="$ROOT_DIR/logs/local-web2py-$PORT.pid"

cd "$ROOT_DIR"
mkdir -p logs

exec ./.venv/bin/python web2py.py --no_gui -a "$PASSWORD" -i 127.0.0.1 -p "$PORT" \
    -d "$PID_FILE" -l "$LOG_FILE"
