#!/bin/bash

# Nandoroid Restart Script
# Restarts the quickshell instance safely

# Kill existing instances
killall qs quickshell 2>/dev/null
pkill -9 cava 2>/dev/null

# Start new instance
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
nohup qs -p "$PROJECT_ROOT" >/dev/null 2>&1 &

exit 0
