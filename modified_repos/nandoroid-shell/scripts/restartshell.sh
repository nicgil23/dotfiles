#!/bin/bash

# Nandoroid Restart Script
# Restarts the quickshell instance safely

# 1. Kill existing instances
killall qs quickshell 2>/dev/null
pkill -9 cava 2>/dev/null

# 2. Wait a moment to ensure they are truly dead
sleep 1

# 3. Start new instance
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
nohup quickshell -p "$PROJECT_ROOT" > /dev/null 2>&1 &

exit 0
