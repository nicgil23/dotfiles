#!/bin/bash

# Remove wallpaper-engine pkill and logic
read -r LAST_WALLPAPER < "$HOME/.cache/quickshell-last-wallpaper"

if [[ -z "$LAST_WALLPAPER" || ! -f "$LAST_WALLPAPER" ]]; then
    exit 0
fi

if command -v hyprctl >/dev/null 2>&1; then
  MONITORS=($(hyprctl monitors -j | jq -r '.[].name'))
elif command -v xrandr >/dev/null 2>&1; then
  MONITORS=($(xrandr --query | grep " connected" | awk '{print $1}'))
else
  MONITORS=("eDP-1")
fi

[[ ${#MONITORS[@]} -eq 0 ]] && MONITORS=("eDP-1")
OUTPUTS=$(IFS=, ; echo "${MONITORS[*]}")

swww img --outputs "$OUTPUTS" -- "$LAST_WALLPAPER"
