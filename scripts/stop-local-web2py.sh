#!/bin/sh
set -eu

ROOT_DIR="/Volumes/project/开发中/web2py_docker"
PORT="${PORT:-8000}"
PID_FILE="$ROOT_DIR/logs/local-web2py-$PORT.pid"
LAUNCH_LABEL="com.local.web2py-docker"
PLIST_FILE="$HOME/Library/LaunchAgents/$LAUNCH_LABEL.plist"

launchctl bootout "gui/$(id -u)" "$PLIST_FILE" >/dev/null 2>&1 || true

if [ ! -f "$PID_FILE" ]; then
    echo "No local web2py pid file: $PID_FILE"
    exit 0
fi

pid="$(cat "$PID_FILE" 2>/dev/null || true)"
if [ -z "$pid" ]; then
    rm -f "$PID_FILE"
    echo "Empty pid file removed."
    exit 0
fi

if kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
    echo "Stopped local web2py pid $pid"
else
    echo "Process $pid is not running."
fi

rm -f "$PID_FILE"
