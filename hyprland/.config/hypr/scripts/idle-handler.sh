#!/usr/bin/env bash

# Helper script for Hyprland idle and lockscreen coordination

NANDOROID_DIR="/home/hypr/dotfiles/modified_repos/nandoroid-shell"
SAVED_BRIGHTNESS_FILE="/tmp/hypr_original_brightness"

is_screen_locked() {
    local locked
    locked=$(qs -p "$NANDOROID_DIR" ipc call lock isLocked 2>/dev/null | tr -d '[:space:]')
    if [ "$locked" = "true" ]; then
        return 0
    fi
    return 1
}

save_and_dim() {
    local cur
    cur=$(brightnessctl get 2>/dev/null)
    # Only save if current brightness is higher than 100 to avoid overwriting with dimmed state
    if [ -n "$cur" ] && [ "$cur" -gt 100 ]; then
        echo "$cur" > "$SAVED_BRIGHTNESS_FILE"
    fi
    brightnessctl set 10
}

restore_brightness() {
    if [ -f "$SAVED_BRIGHTNESS_FILE" ]; then
        local target
        target=$(cat "$SAVED_BRIGHTNESS_FILE" 2>/dev/null)
        if [ -n "$target" ] && [ "$target" -gt 100 ]; then
            brightnessctl set "$target"
        else
            brightnessctl set 100%
        fi
        rm -f "$SAVED_BRIGHTNESS_FILE"
    else
        local cur
        cur=$(brightnessctl get 2>/dev/null)
        if [ -n "$cur" ] && [ "$cur" -le 100 ]; then
            brightnessctl set 100%
        fi
    fi
}

case "$1" in
    dim)
        save_and_dim
        ;;
    lockscreen-dim)
        if is_screen_locked; then
            save_and_dim
        fi
        ;;
    resume)
        if is_screen_locked; then
            exit 0
        fi
        restore_brightness
        ;;
    resume-force)
        restore_brightness
        ;;
    dpms-off)
        hyprctl dispatch dpms off
        ;;
    dpms-on)
        hyprctl dispatch dpms on
        restore_brightness
        ;;
    suspend)
        systemctl suspend
        ;;
    *)
        echo "Usage: $0 {dim|lockscreen-dim|resume|resume-force|dpms-off|dpms-on|suspend}"
        exit 1
        ;;
esac
