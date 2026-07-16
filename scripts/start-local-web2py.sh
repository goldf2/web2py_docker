#!/bin/sh
set -eu

ROOT_DIR="/Volumes/project/开发中/web2py_docker"
PORT="${PORT:-8000}"
PASSWORD="${WEB2PY_ADMIN_PASSWORD:-localadmin}"
PID_FILE="$ROOT_DIR/logs/local-web2py-$PORT.pid"
LOG_FILE="$ROOT_DIR/logs/local-web2py-$PORT.log"
LAUNCH_LABEL="com.local.web2py-docker"
PLIST_FILE="$HOME/Library/LaunchAgents/$LAUNCH_LABEL.plist"

cd "$ROOT_DIR"
mkdir -p logs

if [ -f "$PID_FILE" ]; then
    old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
        echo "web2py is already running: http://127.0.0.1:$PORT/ (pid $old_pid)"
        exit 0
    fi
    rm -f "$PID_FILE"
fi

if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Port $PORT is already in use. Existing local service:"
    lsof -nP -iTCP:"$PORT" -sTCP:LISTEN
    echo "Open: http://127.0.0.1:$PORT/"
    exit 0
fi

./.venv/bin/python - <<PY
from gluon.main import save_password
save_password("$PASSWORD", int("$PORT"))
PY

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LAUNCH_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$ROOT_DIR/scripts/local-web2py-runner.sh</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$ROOT_DIR</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PORT</key>
        <string>$PORT</string>
        <key>WEB2PY_ADMIN_PASSWORD</key>
        <string>$PASSWORD</string>
    </dict>
    <key>StandardOutPath</key>
    <string>$LOG_FILE</string>
    <key>StandardErrorPath</key>
    <string>$LOG_FILE</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)" "$PLIST_FILE" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_FILE"
launchctl kickstart -k "gui/$(id -u)/$LAUNCH_LABEL"

sleep 3
pid="$(cat "$PID_FILE" 2>/dev/null || true)"
if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
    echo "web2py failed to start. Log:"
    tail -80 "$LOG_FILE" 2>/dev/null || true
    rm -f "$PID_FILE"
    exit 1
fi

echo "web2py started: http://127.0.0.1:$PORT/ (pid $pid)"
echo "admin: http://127.0.0.1:$PORT/admin/default/site"
echo "log: $LOG_FILE"
