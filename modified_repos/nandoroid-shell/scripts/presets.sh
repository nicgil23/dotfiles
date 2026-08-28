#!/usr/bin/env bash
# presets.sh - manage shell config presets
# Usage:
#   presets.sh --save <name> [description]
#   presets.sh --remove <name>
#   presets.sh --apply <name>

CONFIG_DIR="$HOME/.config/nandoroid"
CONFIG_FILE="$CONFIG_DIR/config.json"
PRESETS_DIR="$CONFIG_DIR/presets"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Matugen-generated files watched by Quickshell (see core/Directories.qml)
COLOR_JSON="$HOME/.local/state/quickshell/user/generated/colors.json"
LOCK_COLOR_JSON="$HOME/.local/state/quickshell/user/generated/lockscreencolors.json"

mkdir -p "$PRESETS_DIR"

action="$1"
name="$2"

if [ -z "$name" ]; then
    echo "Error: missing preset name" >&2
    exit 1
fi

case "$action" in
    --save)
        description="$3"
        jq 'del(._presetMeta) | del(.github.githubToken)' "$CONFIG_FILE" > "$PRESETS_DIR/${name}.json"
        if [ -n "$description" ]; then
            jq --arg desc "$description" '._presetMeta = {"description": $desc}' \
                "$PRESETS_DIR/${name}.json" > "$PRESETS_DIR/${name}.json.tmp" \
                && mv "$PRESETS_DIR/${name}.json.tmp" "$PRESETS_DIR/${name}.json"
        fi
        ;;
    --remove)
        rm -f "$PRESETS_DIR/${name}.json"
        ;;
    --apply)
        preset_file="$PRESETS_DIR/${name}.json"
        if [ ! -f "$preset_file" ]; then
            echo "Error: preset not found: $name" >&2
            exit 1
        fi

        # Read settings from preset_file first to run matugen BEFORE updating config.json
        # This prevents Quickshell from reloading active.json with outdated/fallback colors first
        merged_json=$(jq -s '.[0] * .[1] | del(._presetMeta)' "$CONFIG_FILE" "$preset_file")

        matugen_enabled=$(echo "$merged_json" | jq -r '.appearance.background.matugen // false')
        custom_color=$(echo "$merged_json" | jq -r '.appearance.background.matugenCustomColor // .appearance.palette.accentColor // .palette.accentColor // ""')
        theme_file=$(echo "$merged_json" | jq -r '.appearance.background.matugenThemeFile // ""')

        scheme=$(echo "$merged_json" | jq -r '.appearance.background.matugenScheme // "scheme-tonal-spot"')
        darkmode=$(echo "$merged_json" | jq -r '.appearance.background.darkmode // true')
        [ "$darkmode" = "true" ] && mode="dark" || mode="light"

        # Regenerate lockscreen colors, mirroring the Wallpapers service behavior.
        # Only needed when a separate lockscreen wallpaper is used; otherwise the
        # shell mirrors desktop colors to the lockscreen automatically.
        refresh_lock_colors() {
            lock_sep=$(echo "$merged_json" | jq -r '.lock.useSeparateWallpaper // false')
            [ "$lock_sep" = "true" ] || return 0

            # Custom accent colors always derive tonal-spot schemes (matches the
            # desktop generation in the custom-color branch and the Wallpapers service)
            lock_scheme="$scheme"
            if [ "$matugen_enabled" = "false" ]; then
                lock_scheme="scheme-tonal-spot"
            fi

            matugen_source=$(echo "$merged_json" | jq -r '.appearance.background.matugenSource // "desktop"')
            if [ "$matugen_source" = "lockscreen" ]; then
                # Desktop colors already derive from the lockscreen wallpaper
                cp "$COLOR_JSON" "$LOCK_COLOR_JSON"
                return 0
            fi

            lock_wallpaper=$(echo "$merged_json" | jq -r '.lock.wallpaperPath // ""')
            lock_wallpaper="${lock_wallpaper#file://}"
            desktop_wallpaper=$(echo "$merged_json" | jq -r '.appearance.background.wallpaperPath // ""')
            desktop_wallpaper="${desktop_wallpaper#file://}"
            [ -n "$lock_wallpaper" ] && [ -f "$lock_wallpaper" ] || return 0

            if [ "$lock_wallpaper" = "$desktop_wallpaper" ]; then
                # Same wallpaper as desktop: reuse the just-generated desktop colors
                cp "$COLOR_JSON" "$LOCK_COLOR_JSON"
            else
                # Different wallpaper: derive lockscreen colors from the lockscreen wallpaper
                lock_json=$(matugen --dry-run -t "$lock_scheme" -m "$mode" image "$lock_wallpaper" --source-color-index 0 -j hex --old-json-output 2>/dev/null)
                if [ -n "$lock_json" ]; then
                    echo "$lock_json" | jq --arg mode "$mode" '.colors | with_entries(.value = (.value[$mode] // .value["default"]))' > "$LOCK_COLOR_JSON"
                fi
            fi
        }

        if [ "$matugen_enabled" = "false" ] && [ -n "$custom_color" ] && [ "$custom_color" != "null" ] && [ "$custom_color" != '""' ]; then
            custom_color_clean="${custom_color#\#}"
            # Ensure both matugenCustomColor and palette.accentColor in merged_json have the '#' prefix
            merged_json=$(echo "$merged_json" | jq --arg c "#$custom_color_clean" '.appearance.background.matugenCustomColor = $c | .appearance.palette.accentColor = $c')
            
            # Generate theme files via Matugen first
            matugen -c ~/.config/matugen/config.toml -t "scheme-tonal-spot" -m "$mode" color hex "$custom_color_clean"
            
            # Write config.json after matugen finishes
            echo "$merged_json" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            refresh_lock_colors
        elif [ "$matugen_enabled" = "false" ] && [ -n "$theme_file" ] && [ "$theme_file" != "null" ]; then
            # Cache the theme colors so lockscreen mirroring stays consistent
            theme_source="$SCRIPT_DIR/../assets/themes/$theme_file"
            [ -f "$theme_source" ] && cp "$theme_source" "$COLOR_JSON"
            echo "$merged_json" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            # Basic themes apply to both desktop and lockscreen
            if [ "$(echo "$merged_json" | jq -r '.lock.useSeparateWallpaper // false')" = "true" ]; then
                cp "$COLOR_JSON" "$LOCK_COLOR_JSON"
            fi
        else
            wallpaper=$(echo "$merged_json" | jq -r '.appearance.background.wallpaperPath // ""')
            wallpaper="${wallpaper#file://}"
            if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
                matugen -c ~/.config/matugen/config.toml -t "$scheme" -m "$mode" image "$wallpaper" --source-color-index 0
            fi
            echo "$merged_json" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            refresh_lock_colors
        fi
        ;;
    *)
        echo "Error: unknown action: $action" >&2
        exit 1
        ;;
esac
