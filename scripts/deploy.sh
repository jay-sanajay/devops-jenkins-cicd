#!/usr/bin/env bash
# ==============================================================================
# Linux / Bash Deployment Script: deploy.sh
# Deploys Flask application locally in the background and tracks PID
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

PORT="${PORT:-5000}"
HOST="${HOST:-127.0.0.1}"
PID_FILE="$ROOT_DIR/app.pid"
LOG_FILE="$ROOT_DIR/app.log"

echo "============================================="
echo " Starting Deployment for DevOps CI/CD App... "
echo "============================================="

# 1. Determine Python binary
if [ -f "$ROOT_DIR/venv/bin/python" ]; then
    PYTHON_BIN="$ROOT_DIR/venv/bin/python"
elif [ -f "$ROOT_DIR/venv/Scripts/python.exe" ]; then
    PYTHON_BIN="$ROOT_DIR/venv/Scripts/python.exe"
else
    PYTHON_BIN="python3"
fi
echo "[INFO] Using Python: $PYTHON_BIN"

# 2. Terminate existing process if PID file exists
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null || true)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        echo "[INFO] Terminating old process $OLD_PID..."
        kill "$OLD_PID" 2>/dev/null || true
        sleep 2
        if kill -0 "$OLD_PID" 2>/dev/null; then
            kill -9 "$OLD_PID" 2>/dev/null || true
        fi
        echo "[SUCCESS] Stopped previous process $OLD_PID."
    fi
    rm -f "$PID_FILE"
fi

# 3. Start Application in Background
echo "[INFO] Starting app on $HOST:$PORT..."
export PORT="$PORT"
export HOST="$HOST"

nohup "$PYTHON_BIN" app.py > "$LOG_FILE" 2>&1 &
NEW_PID=$!

echo "$NEW_PID" > "$PID_FILE"
echo "[SUCCESS] Application started with PID: $NEW_PID"

# 4. Readiness check
sleep 3
if ! kill -0 "$NEW_PID" 2>/dev/null; then
    echo "[FATAL] Process $NEW_PID died shortly after launch!"
    if [ -f "$LOG_FILE" ]; then
        cat "$LOG_FILE"
    fi
    exit 1
fi

echo "[SUCCESS] Deployment completed successfully! PID recorded in app.pid."
exit 0
