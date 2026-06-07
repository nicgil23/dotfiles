#!/usr/bin/env bash
SRCIMG=$1
CACHEDIR=$(realpath "$2")

if [ -z "$SRCIMG" ] || [ ! -f "$SRCIMG" ]; then
  echo "[ERROR] Source image not specified or does not exist: $SRCIMG"
  exit 1
fi

SRCHASH=$(sha256sum "$SRCIMG" | awk '{print substr($1, 0, 10)}')

DSTDIR=${CACHEDIR}/foregrounds
DSTIMG=${DSTDIR}/${SRCHASH}.png
mkdir -p "$DSTDIR"

# Only process wallpaper if not found in cache
if ! [ -f "${DSTIMG}" ]; then
  echo "[INFO] Extracting wallpaper foreground"
  
  # Resolve rembg command (fallback to ~/.local/bin/rembg if not in PATH)
  REMBG_CMD="rembg"
  if ! command -v rembg &> /dev/null; then
    if [ -f "$HOME/.local/bin/rembg" ]; then
      REMBG_CMD="$HOME/.local/bin/rembg"
    else
      echo "[ERROR] rembg command not found in PATH or in $HOME/.local/bin/rembg"
      exit 1
    fi
  fi

  if $REMBG_CMD i -m birefnet-general "$SRCIMG" "$DSTIMG" &> "$CACHEDIR/rembg.log"; then
    echo "[INFO] Successfully extracted foreground"
  else
    echo "[ERROR] Failed to extract foreground"
    echo "[INFO] Find log in ${CACHEDIR}/rembg.log"
    exit 1
  fi
else
  echo "[INFO] Foreground file in cache"
fi

echo "FOREGROUND $DSTIMG"
