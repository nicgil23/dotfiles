#!/usr/bin/env sh

# Alternar ejecución de wvkbd (on-screen keyboard)
if pgrep -x "wvkbd-mobintl" > /dev/null || pgrep -x "wvkbd" > /dev/null; then
    pkill -9 wvkbd-mobintl || pkill -9 wvkbd
    exit 0
fi

THEME_FILE="$HOME/.config/wvkbd/wvkbd-theme.sh"

if [ -f "$THEME_FILE" ]; then
    . "$THEME_FILE"
    wvkbd-mobintl -L 300 \
        --bg "$WVKBD_BG" \
        --fg "$WVKBD_FG" \
        --fg-sp "$WVKBD_FG_SP" \
        --text "$WVKBD_TEXT" \
        --text-sp "$WVKBD_TEXT_SP" \
        --press "$WVKBD_PRESS" \
        --press-sp "$WVKBD_PRESS_SP" \
        --swipe "$WVKBD_SWIPE" \
        --swipe-sp "$WVKBD_SWIPE_SP" \
        --alpha 240 \
        --fn 'JetBrainsMono Nerd Font Propo' \
        -R 10 &
else
    wvkbd-mobintl -L 300 --alpha 240 -R 10 &
fi
