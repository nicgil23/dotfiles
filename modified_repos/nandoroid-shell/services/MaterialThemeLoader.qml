pragma Singleton
pragma ComponentBehavior: Bound

import "../core"
import "../core/functions" as Functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Applies M3 color tokens to Appearance.m3colors.
 *
 * Dual-path architecture (mirroring Caelestia shell's Colours.qml):
 *
 *  PATH 1 — Immediate (from matugen stdout via -j hex):
 *    Wallpapers.qml calls load(stdoutText) directly from StdioCollector.
 *    This fires ~1-2s after wallpaper change, before any file is written.
 *
 *  PATH 2 — Persistence (from colors.json on disk):
 *    FileView watches colors.json. On shell restart the stored file is read
 *    so the last theme is preserved without re-running matugen.
 *
 * All color properties are assigned EXPLICITLY — dynamic JS loops don't
 * emit QML NOTIFY signals, so bindings wouldn't update.
 */
Singleton {
    id: root

    readonly property string generatedPath: Directories.generatedMaterialThemePath
    readonly property string themesDir: "file://" + Directories.assetsPath + "/themes/"

    // Path switches between generated file and static theme file
    property string filePath: {
        if (!Config.ready) return generatedPath;
        const bg = Config.options.appearance.background;
        if (bg.matugen || bg.matugenThemeFile === "") return generatedPath;
        return themesDir + bg.matugenThemeFile;
    }

    // Called by Wallpapers.qml after writing a static theme file.
    function reapplyTheme() {
        themeFileView.reload();
    }

    /**
     * Parse matugen's -j hex JSON output and apply to Appearance.m3colors.
     *
     * The JSON structure from `matugen -j hex` is:
     * {
     *   "colors": {
     *     "primary":    { "default": { "color": "#9bcbfb" }, ... },
     *     "on_primary": { "default": { "color": "#003353" }, ... },
     *     ...
     *   },
     *   "base16": {
     *     "base00": { "default": { "color": "#1373d1" }, ... },
     *     ...
     *   },
     *   "is_dark_mode": true
     * }
     *
     * Called from:
     *   - Wallpapers.matugenColorsProc stdout (PATH 1 — immediate)
     *   - themeFileView.onLoaded with flat JSON from colors.json (PATH 2 — persistence)
     */
    function load(data: string): void {
        if (!data || data.trim() === "") {
            console.warn("[MaterialThemeLoader] Empty data, skipping.");
            return;
        }

        let json;
        try {
            json = JSON.parse(data);
        } catch (e) {
            console.error("[MaterialThemeLoader] JSON parse error:", e, "| Data start:", data.substring(0, 80));
            return;
        }

        const m3 = Appearance.m3colors;

        // Detect which format we received:
        // FORMAT A — matugen -j hex stdout:  json.colors.primary.default.color = "#rrggbb"
        // FORMAT B — colors.json from disk:  json.primary = "#rrggbb"
        const isStdoutFormat = json.colors && typeof json.colors === "object";

        if (isStdoutFormat) {
            _loadFromStdout(json, m3);
        } else {
            _loadFromFile(json, m3);
        }

        console.log("[MaterialThemeLoader] Theme applied. Dark mode:", m3.darkmode);
    }

    // Helper: get color from stdout JSON entry
    function _colorOf(entry: var, mode: string): string {
        if (!entry) return "";
        const modeEntry = entry[mode] || entry["default"];
        return modeEntry ? modeEntry.color : "";
    }

    // PATH 1 parser — matugen stdout -j hex format
    function _loadFromStdout(json: var, m3: var): void {
        const c = json.colors;
        const b = json.base16 || {};
        // use the mode reported by matugen itself
        const mode = json.is_dark_mode ? "dark" : "light";

        if (!c.background || !c.primary) {
            console.warn("[MaterialThemeLoader] stdout JSON incomplete, skipping.");
            return;
        }

        const g = (key) => _colorOf(c[key], mode);
        const gb = (key) => _colorOf(b[key], mode);

        // Surface / Background
        if (c.background)                   m3.m3background                  = g("background");
        if (c.on_background)                m3.m3onBackground                = g("on_background");
        if (c.surface)                      m3.m3surface                     = g("surface");
        if (c.surface_dim)                  m3.m3surfaceDim                  = g("surface_dim");
        if (c.surface_bright)               m3.m3surfaceBright               = g("surface_bright");
        if (c.surface_container_lowest)     m3.m3surfaceContainerLowest      = g("surface_container_lowest");
        if (c.surface_container_low)        m3.m3surfaceContainerLow         = g("surface_container_low");
        if (c.surface_container)            m3.m3surfaceContainer            = g("surface_container");
        if (c.surface_container_high)       m3.m3surfaceContainerHigh        = g("surface_container_high");
        if (c.surface_container_highest)    m3.m3surfaceContainerHighest     = g("surface_container_highest");
        if (c.on_surface)                   m3.m3onSurface                   = g("on_surface");
        if (c.surface_variant)              m3.m3surfaceVariant              = g("surface_variant");
        if (c.on_surface_variant)           m3.m3onSurfaceVariant            = g("on_surface_variant");
        if (c.inverse_surface)              m3.m3inverseSurface              = g("inverse_surface");
        if (c.inverse_on_surface)           m3.m3inverseOnSurface            = g("inverse_on_surface");
        if (c.outline)                      m3.m3outline                     = g("outline");
        if (c.outline_variant)              m3.m3outlineVariant              = g("outline_variant");
        if (c.shadow)                       m3.m3shadow                      = g("shadow");
        if (c.scrim)                        m3.m3scrim                       = g("scrim");
        if (c.surface_tint)                 m3.m3surfaceTint                 = g("surface_tint");
        // Primary
        if (c.primary)                      m3.m3primary                     = g("primary");
        if (c.on_primary)                   m3.m3onPrimary                   = g("on_primary");
        if (c.primary_container)            m3.m3primaryContainer            = g("primary_container");
        if (c.on_primary_container)         m3.m3onPrimaryContainer          = g("on_primary_container");
        if (c.inverse_primary)              m3.m3inversePrimary              = g("inverse_primary");
        // Secondary
        if (c.secondary)                    m3.m3secondary                   = g("secondary");
        if (c.on_secondary)                 m3.m3onSecondary                 = g("on_secondary");
        if (c.secondary_container)          m3.m3secondaryContainer          = g("secondary_container");
        if (c.on_secondary_container)       m3.m3onSecondaryContainer        = g("on_secondary_container");
        // Tertiary
        if (c.tertiary)                     m3.m3tertiary                    = g("tertiary");
        if (c.on_tertiary)                  m3.m3onTertiary                  = g("on_tertiary");
        if (c.tertiary_container)           m3.m3tertiaryContainer           = g("tertiary_container");
        if (c.on_tertiary_container)        m3.m3onTertiaryContainer         = g("on_tertiary_container");
        // Error
        if (c.error)                        m3.m3error                       = g("error");
        if (c.on_error)                     m3.m3onError                     = g("on_error");
        if (c.error_container)              m3.m3errorContainer              = g("error_container");
        if (c.on_error_container)           m3.m3onErrorContainer            = g("on_error_container");
        // Fixed
        if (c.primary_fixed)                m3.m3primaryFixed                = g("primary_fixed");
        if (c.primary_fixed_dim)            m3.m3primaryFixedDim             = g("primary_fixed_dim");
        if (c.on_primary_fixed)             m3.m3onPrimaryFixed              = g("on_primary_fixed");
        if (c.on_primary_fixed_variant)     m3.m3onPrimaryFixedVariant       = g("on_primary_fixed_variant");
        if (c.secondary_fixed)              m3.m3secondaryFixed              = g("secondary_fixed");
        if (c.secondary_fixed_dim)          m3.m3secondaryFixedDim           = g("secondary_fixed_dim");
        if (c.on_secondary_fixed)           m3.m3onSecondaryFixed            = g("on_secondary_fixed");
        if (c.on_secondary_fixed_variant)   m3.m3onSecondaryFixedVariant     = g("on_secondary_fixed_variant");
        if (c.tertiary_fixed)               m3.m3tertiaryFixed               = g("tertiary_fixed");
        if (c.tertiary_fixed_dim)           m3.m3tertiaryFixedDim            = g("tertiary_fixed_dim");
        if (c.on_tertiary_fixed)            m3.m3onTertiaryFixed             = g("on_tertiary_fixed");
        if (c.on_tertiary_fixed_variant)    m3.m3onTertiaryFixedVariant      = g("on_tertiary_fixed_variant");
        // Base16
        if (b.base00) m3.m3base00 = gb("base00");
        if (b.base01) m3.m3base01 = gb("base01");
        if (b.base02) m3.m3base02 = gb("base02");
        if (b.base03) m3.m3base03 = gb("base03");
        if (b.base04) m3.m3base04 = gb("base04");
        if (b.base05) m3.m3base05 = gb("base05");
        if (b.base06) m3.m3base06 = gb("base06");
        if (b.base07) m3.m3base07 = gb("base07");
        if (b.base08) m3.m3base08 = gb("base08");
        if (b.base09) m3.m3base09 = gb("base09");
        if (b.base0a) m3.m3base0a = gb("base0a");
        if (b.base0b) m3.m3base0b = gb("base0b");
        if (b.base0c) m3.m3base0c = gb("base0c");
        if (b.base0d) m3.m3base0d = gb("base0d");
        if (b.base0e) m3.m3base0e = gb("base0e");
        if (b.base0f) m3.m3base0f = gb("base0f");

        m3.darkmode = json.is_dark_mode === true;
    }

    // PATH 2 parser — flat colors.json from disk (written by matugen templates)
    function _loadFromFile(json: var, m3: var): void {
        if (!json.background || !json.primary) {
            console.warn("[MaterialThemeLoader] File JSON incomplete, skipping.");
            return;
        }

        if (json.background)                   m3.m3background                  = json.background;
        if (json.on_background)                m3.m3onBackground                = json.on_background;
        if (json.surface)                      m3.m3surface                     = json.surface;
        if (json.surface_dim)                  m3.m3surfaceDim                  = json.surface_dim;
        if (json.surface_bright)               m3.m3surfaceBright               = json.surface_bright;
        if (json.surface_container_lowest)     m3.m3surfaceContainerLowest      = json.surface_container_lowest;
        if (json.surface_container_low)        m3.m3surfaceContainerLow         = json.surface_container_low;
        if (json.surface_container)            m3.m3surfaceContainer            = json.surface_container;
        if (json.surface_container_high)       m3.m3surfaceContainerHigh        = json.surface_container_high;
        if (json.surface_container_highest)    m3.m3surfaceContainerHighest     = json.surface_container_highest;
        if (json.on_surface)                   m3.m3onSurface                   = json.on_surface;
        if (json.surface_variant)              m3.m3surfaceVariant              = json.surface_variant;
        if (json.on_surface_variant)           m3.m3onSurfaceVariant            = json.on_surface_variant;
        if (json.inverse_surface)              m3.m3inverseSurface              = json.inverse_surface;
        if (json.inverse_on_surface)           m3.m3inverseOnSurface            = json.inverse_on_surface;
        if (json.outline)                      m3.m3outline                     = json.outline;
        if (json.outline_variant)              m3.m3outlineVariant              = json.outline_variant;
        if (json.shadow)                       m3.m3shadow                      = json.shadow;
        if (json.scrim)                        m3.m3scrim                       = json.scrim;
        if (json.surface_tint)                 m3.m3surfaceTint                 = json.surface_tint;
        if (json.primary)                      m3.m3primary                     = json.primary;
        if (json.on_primary)                   m3.m3onPrimary                   = json.on_primary;
        if (json.primary_container)            m3.m3primaryContainer            = json.primary_container;
        if (json.on_primary_container)         m3.m3onPrimaryContainer          = json.on_primary_container;
        if (json.inverse_primary)              m3.m3inversePrimary              = json.inverse_primary;
        if (json.secondary)                    m3.m3secondary                   = json.secondary;
        if (json.on_secondary)                 m3.m3onSecondary                 = json.on_secondary;
        if (json.secondary_container)          m3.m3secondaryContainer          = json.secondary_container;
        if (json.on_secondary_container)       m3.m3onSecondaryContainer        = json.on_secondary_container;
        if (json.tertiary)                     m3.m3tertiary                    = json.tertiary;
        if (json.on_tertiary)                  m3.m3onTertiary                  = json.on_tertiary;
        if (json.tertiary_container)           m3.m3tertiaryContainer           = json.tertiary_container;
        if (json.on_tertiary_container)        m3.m3onTertiaryContainer         = json.on_tertiary_container;
        if (json.error)                        m3.m3error                       = json.error;
        if (json.on_error)                     m3.m3onError                     = json.on_error;
        if (json.error_container)              m3.m3errorContainer              = json.error_container;
        if (json.on_error_container)           m3.m3onErrorContainer            = json.on_error_container;
        if (json.primary_fixed)                m3.m3primaryFixed                = json.primary_fixed;
        if (json.primary_fixed_dim)            m3.m3primaryFixedDim             = json.primary_fixed_dim;
        if (json.on_primary_fixed)             m3.m3onPrimaryFixed              = json.on_primary_fixed;
        if (json.on_primary_fixed_variant)     m3.m3onPrimaryFixedVariant       = json.on_primary_fixed_variant;
        if (json.secondary_fixed)              m3.m3secondaryFixed              = json.secondary_fixed;
        if (json.secondary_fixed_dim)          m3.m3secondaryFixedDim           = json.secondary_fixed_dim;
        if (json.on_secondary_fixed)           m3.m3onSecondaryFixed            = json.on_secondary_fixed;
        if (json.on_secondary_fixed_variant)   m3.m3onSecondaryFixedVariant     = json.on_secondary_fixed_variant;
        if (json.tertiary_fixed)               m3.m3tertiaryFixed               = json.tertiary_fixed;
        if (json.tertiary_fixed_dim)           m3.m3tertiaryFixedDim            = json.tertiary_fixed_dim;
        if (json.on_tertiary_fixed)            m3.m3onTertiaryFixed             = json.on_tertiary_fixed;
        if (json.on_tertiary_fixed_variant)    m3.m3onTertiaryFixedVariant      = json.on_tertiary_fixed_variant;
        if (json.base00) m3.m3base00 = json.base00;
        if (json.base01) m3.m3base01 = json.base01;
        if (json.base02) m3.m3base02 = json.base02;
        if (json.base03) m3.m3base03 = json.base03;
        if (json.base04) m3.m3base04 = json.base04;
        if (json.base05) m3.m3base05 = json.base05;
        if (json.base06) m3.m3base06 = json.base06;
        if (json.base07) m3.m3base07 = json.base07;
        if (json.base08) m3.m3base08 = json.base08;
        if (json.base09) m3.m3base09 = json.base09;
        if (json.base0a) m3.m3base0a = json.base0a;
        if (json.base0b) m3.m3base0b = json.base0b;
        if (json.base0c) m3.m3base0c = json.base0c;
        if (json.base0d) m3.m3base0d = json.base0d;
        if (json.base0e) m3.m3base0e = json.base0e;
        if (json.base0f) m3.m3base0f = json.base0f;

        m3.darkmode = Functions.ColorUtils.isDark(m3.m3background);
    }

    // PATH 2 — file watcher for persistence across restarts
    FileView {
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.load(themeFileView.text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                console.warn("[MaterialThemeLoader] colors.json not found — initializing Matugen.");
                Wallpapers.initializeMatugen();
            }
        }
    }
}
