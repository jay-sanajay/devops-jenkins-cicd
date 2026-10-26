#!/usr/bin/env bash
# ==============================================================================
# Linux / Bash Stop Script: stop.sh
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PID_FILE="$ROOT_DIR/app.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE" 2>/dev/null || true)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "Stopping process $PID..."
        kill "$PID" || true
        sleep 1
        kill -9 "$PID" 2>/dev/null || true
        echo "Process stopped."
    else
        echo "No active process found for PID $PID."
    fi
    rm -f "$PID_FILE"
else
    echo "No app.pid file found."
fi
