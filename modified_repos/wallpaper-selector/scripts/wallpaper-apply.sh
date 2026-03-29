#!/usr/bin/env bash
cd "$(dirname "$0")"

WAL_CMD=""
VENV_BIN=""  
[[ -n "$VENV_BIN" ]] && export PATH="$VENV_BIN:$PATH"

# The QML will pass the direct image file path as $1
WALLPAPER_IMAGE="$1"
if [[ -z "$WALLPAPER_IMAGE" || ! -f "$WALLPAPER_IMAGE" ]]; then
    echo "Usage: $0 <wallpaper_image>"
    echo "Error: File does not exist: $WALLPAPER_IMAGE" >&2
    exit 1
fi

echo "$WALLPAPER_IMAGE" > ~/.cache/quickshell-last-wallpaper

[[ -n "$WAL_CMD" ]] && "$WAL_CMD" -i "$WALLPAPER_IMAGE" -n -q 2>/dev/null || true

MONITORS=()
if command -v hyprctl >/dev/null 2>&1; then
    MONITORS=($(hyprctl monitors -j | jq -r '.[].name'))
elif command -v xrandr >/dev/null 2>&1; then
    MONITORS=($(xrandr --query | grep " connected" | awk '{print $1}'))
else
    MONITORS=("eDP-1")
fi

[[ ${#MONITORS[@]} -eq 0 ]] && MONITORS=("eDP-1")
OUTPUTS=$(IFS=, ; echo "${MONITORS[*]}")

# Random transition
transitions=("outer" "wipe" "wave" "outer" "left" "right" "top" "bottom" "any")
selected_transition=${transitions[$RANDOM % ${#transitions[@]}]}

swww img --outputs "$OUTPUTS" "$WALLPAPER_IMAGE" \
    --transition-fps 60 \
    --transition-type ${selected_transition} \
    --transition-duration 2 \
    --transition-pos center

# Current wallpaper to .cache
cacheDir="${HOME}/.cache/jp"
if [ ! -d "${cacheDir}" ] ; then
    mkdir -p "${cacheDir}"
fi
ln -sf "$(realpath "$WALLPAPER_IMAGE")" "${cacheDir}/current_wallpaper.png"