import QtQuick
import Quickshell
import Quickshell.Io
import "functions" as Functions
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property QtObject m3colors
    property QtObject colors
    property QtObject rounding
    property QtObject font
    property QtObject sizes
    property QtObject animation
    property QtObject animationCurves

    // --- REACTIVE SCALING LOGIC ---
    property real effectiveScale: 1.0

    function updateScale() {
        if (!Config.ready) {
            // Try to guess scale from screen height even if config isn't ready
            const screenHeight = Quickshell.screens[0]?.height ?? 1080;
            effectiveScale = Math.max(0.5, Math.min(2.5, screenHeight / 1080.0));
            return;
        }
        const appearance = Config.options.appearance;
        if (!appearance) return;
        
        if (appearance.autoScale === true) {
            const screenHeight = Quickshell.screens[0]?.height ?? 1080;
            effectiveScale = Math.max(0.5, Math.min(2.5, screenHeight / 1080.0));
        } else {
            effectiveScale = appearance.globalScale ?? 1.0;
        }
    }

    Component.onCompleted: root.updateScale()

    Connections {
        target: Config
        function onReadyChanged() { root.updateScale(); }
    }
    
    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: root.updateScale()
    }

    // --- Material 3 Color Tokens (populated by MaterialThemeLoader) ---
    m3colors: QtObject {
        property bool darkmode: true
        property color m3background: "#1e1e2e"
        property color m3onBackground: "#cdd6f4"
        property color m3surface: "#181825"
        property color m3surfaceDim: "#11111b"
        property color m3surfaceBright: "#313244"
        property color m3surfaceContainerLowest: "#11111b"
        property color m3surfaceContainerLow: "#181825"
        property color m3surfaceContainer: "#313244"
        property color m3surfaceContainerHigh: "#45475a"
        property color m3surfaceContainerHighest: "#585b70"
        property color m3onSurface: "#cdd6f4"
        property color m3surfaceVariant: "#313244"
        property color m3onSurfaceVariant: "#a6adc8"
        property color m3inverseSurface: "#cdd6f4"
        property color m3inverseOnSurface: "#1e1e2e"
        property color m3outline: "#6c7086"
        property color m3outlineVariant: "#585b70"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#cdd6f4"
        property color m3primary: "#cdd6f4"
        property color m3onPrimary: "#1e1e2e"
        property color m3primaryContainer: "#313244"
        property color m3onPrimaryContainer: "#cdd6f4"
        property color m3inversePrimary: "#cdd6f4"
        property color m3secondary: "#89b4fa"
        property color m3onSecondary: "#1e1e2e"
        property color m3secondaryContainer: "#313244"
        property color m3onSecondaryContainer: "#89b4fa"
        property color m3tertiary: "#94e2d5"
        property color m3onTertiary: "#1e1e2e"
        property color m3tertiaryContainer: "#313244"
        property color m3onTertiaryContainer: "#94e2d5"
        property color m3error: "#f38ba8"
        property color m3onError: "#cdd6f4"
        property color m3errorContainer: "#7f849c"
        property color m3onErrorContainer: "#f38ba8"
        property color m3primaryFixed: "#cdd6f4"
        property color m3primaryFixedDim: "#cdd6f4"
        property color m3onPrimaryFixed: "#1e1e2e"
        property color m3onPrimaryFixedVariant: "#1e1e2e"
        property color m3secondaryFixed: "#89b4fa"
        property color m3secondaryFixedDim: "#89b4fa"
        property color m3onSecondaryFixed: "#1e1e2e"
        property color m3onSecondaryFixedVariant: "#1e1e2e"
        property color m3tertiaryFixed: "#94e2d5"
        property color m3tertiaryFixedDim: "#94e2d5"
        property color m3onTertiaryFixed: "#1e1e2e"
        property color m3onTertiaryFixedVariant: "#1e1e2e"
        property color m3success: "#a6e3a1"
        property color m3onSuccess: "#1e1e2e"
        property color m3successContainer: "#313244"
        property color m3onSuccessContainer: "#a6e3a1"

        // Base16 Catppuccin Mocha
        property color m3base00: "#1e1e2e"
        property color m3base01: "#181825"
        property color m3base02: "#313244"
        property color m3base03: "#45475a"
        property color m3base04: "#585b70"
        property color m3base05: "#cdd6f4"
        property color m3base06: "#f5e0dc"
        property color m3base07: "#b4befe"
        property color m3base08: "#f38ba8"
        property color m3base09: "#fab387"
        property color m3base0a: "#f9e2af"
        property color m3base0b: "#a6e3a1"
        property color m3base0c: "#94e2d5"
        property color m3base0d: "#89b4fa"
        property color m3base0e: "#cba6f7"
        property color m3base0f: "#f2cdcd"
    }

    // --- Derived Layer Colors ---
    colors: QtObject {
        property color colSubtext: m3colors.m3outline
        // Layer 0 (background)
        property color colLayer0: m3colors.m3background
        property color colOnLayer0: m3colors.m3onBackground
        property color colLayer0Hover: Functions.ColorUtils.mix(colLayer0, colOnLayer0, 0.92)
        property color colLayer0Active: Functions.ColorUtils.mix(colLayer0, colOnLayer0, 0.85)
        // Layer 1
        property color colLayer1: m3colors.m3surfaceContainerLow
        property color colOnLayer1: m3colors.m3onSurfaceVariant
        property color colLayer1Hover: Functions.ColorUtils.mix(colLayer1, colOnLayer1, 0.92)
        property color colLayer1Active: Functions.ColorUtils.mix(colLayer1, colOnLayer1, 0.85)
        // Layer 2
        property color colLayer2: m3colors.m3surfaceContainer
        property color colOnLayer2: m3colors.m3onSurface
        property color colLayer2Hover: Functions.ColorUtils.mix(colLayer2, colOnLayer2, 0.90)
        property color colLayer2Active: Functions.ColorUtils.mix(colLayer2, colOnLayer2, 0.80)
        // Layer 3
        property color colLayer3: m3colors.m3surfaceContainerHigh
        property color colOnLayer3: m3colors.m3onSurface
        property color colLayer3Hover: Functions.ColorUtils.mix(colLayer3, colOnLayer3, 0.90)
        property color colLayer3Active: Functions.ColorUtils.mix(colLayer3, colOnLayer3, 0.80)
        // Primary
        property color colPrimary: m3colors.m3primary
        property color colOnPrimary: m3colors.m3onPrimary
        property color colPrimaryHover: Functions.ColorUtils.mix(colPrimary, colOnPrimary, 0.92)
        property color colPrimaryActive: Functions.ColorUtils.mix(colPrimary, colOnPrimary, 0.85)
        property color colPrimaryContainer: m3colors.m3primaryContainer
        property color colOnPrimaryContainer: m3colors.m3onPrimaryContainer
        property color colPrimaryContainerActive: Functions.ColorUtils.mix(colPrimaryContainer, colOnPrimaryContainer, 0.85)
        // Secondary
        property color colSecondary: m3colors.m3secondary
        property color colOnSecondary: m3colors.m3onSecondary
        property color colSecondaryHover: Functions.ColorUtils.mix(colSecondary, colOnSecondary, 0.92)
        property color colSecondaryActive: Functions.ColorUtils.mix(colSecondary, colOnSecondary, 0.85)
        property color colSecondaryContainer: m3colors.m3secondaryContainer
        property color colOnSecondaryContainer: m3colors.m3onSecondaryContainer
        property color colSecondaryContainerHover: Functions.ColorUtils.mix(colSecondaryContainer, colOnSecondaryContainer, 0.90)
        property color colSecondaryContainerActive: Functions.ColorUtils.mix(colSecondaryContainer, colOnSecondaryContainer, 0.85)
        // Tertiary
        property color colTertiary: m3colors.m3tertiary
        property color colOnTertiary: m3colors.m3onTertiary
        property color colTertiaryActive: Functions.ColorUtils.mix(colTertiary, colOnTertiary, 0.85)
        property color colTertiaryContainer: m3colors.m3tertiaryContainer
        property color colOnTertiaryContainer: m3colors.m3onTertiaryContainer
        property color colTertiaryContainerHover: Functions.ColorUtils.mix(colTertiaryContainer, colOnTertiaryContainer, 0.90)
        property color colTertiaryContainerActive: Functions.ColorUtils.mix(colTertiaryContainer, colOnTertiaryContainer, 0.85)
        // Error
        property color colError: m3colors.m3error
        property color colOnError: m3colors.m3onError
        property color colErrorContainer: m3colors.m3errorContainer
        property color colOnErrorContainer: m3colors.m3onErrorContainer
        // Warning (Mapped to Tertiary in M3 if not specific)
        property color colWarning: m3colors.m3tertiary 

        // Battery Indicator (Enhanced visibility)
        property color colBatteryTrack: Functions.ColorUtils.applyAlpha(colStatusBarText, 0.35)
        property color colBatteryLow: m3colors.m3error
        property color colBatteryLowTrack: Functions.ColorUtils.applyAlpha(m3colors.m3error, 0.4)
        property color colBatteryCharging: m3colors.m3success

        // Background alias
        property color colBackground: colLayer0
        // Misc
        property color colOutline: m3colors.m3outline
        property color colOutlineVariant: m3colors.m3outlineVariant
        property color colScrim: Functions.ColorUtils.applyAlpha(m3colors.m3scrim, 0.5)
        property color colShadow: m3colors.m3shadow
        // Smart Status Bar (adaptive text color based on wallpaper lightness)
        property bool statusBarDarkText: false

        // When background is shown, gradient + adaptive text mode are ignored
        readonly property bool statusBarAlwaysSolid: Config.ready && Config.options.statusBar
            ? (Config.options.statusBar.backgroundStyle ?? 0) === 1
            : false

        // Gradient is only active when backgroundStyle != 1 AND useGradient = true
        readonly property bool statusBarGradientActive: !statusBarAlwaysSolid
            && (Config.ready && Config.options.statusBar ? (Config.options.statusBar.useGradient ?? true) : true)

        // Resolved dark text: respects user setting if not ALWAYS solid
        readonly property bool resolvedStatusBarDarkText: {
            if (statusBarAlwaysSolid) return false; // background mode: use theme text (always on surface)
            if (!Config.ready || !Config.options.statusBar) return statusBarDarkText;
            const mode = Config.options.statusBar.textColorMode ?? "adaptive";
            if (mode === "dark") return true;
            if (mode === "light") return false;
            return statusBarDarkText; // adaptive
        }

        property color colStatusBarText: m3colors.m3onSurface
        property color colStatusBarSubtext: Functions.ColorUtils.applyAlpha(colStatusBarText, 0.7)
        property color colStatusBarGradientStart: {
            if (!statusBarGradientActive) return "transparent";
            let baseColor = "#000000"; // Always use a dark shadow/scrim for the top
            let alpha = 0.35; // Fixed subtle alpha for light text
            return Functions.ColorUtils.applyAlpha(baseColor, alpha);
        }
        property color colStatusBarGradientEnd: "transparent"
        // Solid bar color (used when backgroundStyle > 0)
        property color colStatusBarSolid: m3colors.m3surfaceContainerLow

        // Smart Lockscreen Text
        property bool lockscreenDarkText: false
        property color colLockscreenClock: lockscreenDarkText ? "#1E1E1E" : "#F5F5F5"
        property color colLockscreenDate: Functions.ColorUtils.applyAlpha(colLockscreenClock, 0.8)

        // Lockscreen Weather Text (follows adaptive/light/dark config)
        readonly property bool resolvedLockscreenWeatherDarkText: {
            if (!Config.ready || !Config.options.lock?.weather) return lockscreenDarkText;
            const mode = Config.options.lock.weather.textColorMode ?? "adaptive";
            if (mode === "dark") return true;
            if (mode === "light") return false;
            return lockscreenDarkText; // adaptive
        }
        property color colLockscreenWeatherText: resolvedLockscreenWeatherDarkText ? "#1E1E1E" : "#F5F5F5"
        property color colLockscreenWeatherSubtext: Functions.ColorUtils.applyAlpha(colLockscreenWeatherText, 0.8)

        Behavior on colLockscreenWeatherText { ColorAnimation { duration: 300 } }
        Behavior on colLockscreenWeatherSubtext { ColorAnimation { duration: 300 } }

        // Notch specific (always dark context)
        property color colNotchText: "#E2E2E2" // Modern M3 off-white
        property color colNotchSubtext: Functions.ColorUtils.applyAlpha("#E2E2E2", 0.7)
        property color colNotchPrimary: m3colors.m3primary // Use dynamic primary from matugen
    }

    // Process to determine the top color of the wallpaper
    Process {
        id: wpLightnessProc
        property string wpPath: {
            if (!Config.ready || !Config.options.appearance || !Config.options.appearance.background) return "";
            return Config.options.appearance.background.wallpaperPath.toString().replace("file://", "");
        }
        
        command: wpPath ? [
            "magick", wpPath, 
            "-gravity", "North", 
            "-crop", "100%x40+0+0",
            "-colorspace", "Gray",
            "-scale", "1x1!", 
            "-format", "%[fx:mean]", 
            "info:"
        ] : []
        
        Component.onCompleted: {
            if (wpPath !== "") running = true;
        }
        
        onWpPathChanged: {
            if (wpPath !== "") {
                if (running) {
                    running = false;
                    Qt.callLater(() => { running = true; });
                } else {
                    running = true;
                }
            }
        }
        
        onExited: (exitCode) => {
            if (exitCode === 0) {
                let meanStr = wpLightnessStdout.text.trim();
                let mean = parseFloat(meanStr);
                if (!isNaN(mean)) {
                    // if mean lightness > 0.45, consider the wallpaper light and use dark text
                    root.colors.statusBarDarkText = mean > 0.45;
                }
            }
        }
        
        stdout: StdioCollector {
            id: wpLightnessStdout
        }
    }

    // Process to determine the overall lightness of the lockscreen wallpaper
    Process {
        id: lockLightnessProc
        property string wpPath: {
            if (!Config.ready) return "";
            if (Config.options.lock && Config.options.lock.useSeparateWallpaper && Config.options.lock.wallpaperPath !== "") {
                return Config.options.lock.wallpaperPath.toString().replace("file://", "");
            }
            if (!Config.options.appearance || !Config.options.appearance.background) return "";
            return Config.options.appearance.background.wallpaperPath.toString().replace("file://", "");
        }
        
        command: wpPath ? ["magick", wpPath, "-gravity", "North", "-crop", "50%x30%+0+30%", "-scale", "1x1!", "-format", "%[fx:mean]", "info:"] : []
        
        Component.onCompleted: {
            if (wpPath !== "") running = true;
        }
                
        onWpPathChanged: {
            if (wpPath !== "") {
                if (running) {
                    running = false;
                    Qt.callLater(() => { running = true; });
                } else {
                    running = true;
                }
            }
        }
        
        onExited: (exitCode) => {
            if (exitCode === 0) {
                let meanStr = lockLightnessStdout.text.trim();
                let mean = parseFloat(meanStr);
                if (!isNaN(mean)) {
                    // if mean lightness > 0.55 (slightly adjusted to account for scrim), use dark text
                    root.colors.lockscreenDarkText = mean > 0.55;
                }
            }
        }

        stdout: StdioCollector {
            id: lockLightnessStdout
        }
    }

    rounding: QtObject {
        readonly property real scale: root.effectiveScale
        property int unsharpen: Math.round(2 * scale)
        property int unsharpenmore: Math.round(6 * scale)
        property int verysmall: Math.round(8 * scale)
        property int small: Math.round(12 * scale)
        property int normal: Math.round(18 * scale)
        property int large: Math.round(24 * scale)
        property int extraLarge: Math.round(32 * scale)
        property int full: 9999
        property int statusBar: 0
        property int panel: Math.round(28 * scale)
        property int card: Math.round(24 * scale)
        property int button: Math.round(20 * scale)
    }

    FontLoader {
        id: sfProRounded
        source: "file:///usr/share/fonts/apple-fonts/SF-Pro-Rounded-Regular.otf"
    }

    // --- Typography ---
    font: QtObject {
        property QtObject family: QtObject {
            id: typoFamily
            property string main: Config.ready ? Config.options.appearance.fonts.main : (sfProRounded.name !== "" ? sfProRounded.name : "SF Pro Rounded")
            property string numbers: Config.ready ? Config.options.appearance.fonts.numbers : (sfProRounded.name !== "" ? sfProRounded.name : "SF Pro Rounded")
            property string title: Config.ready ? Config.options.appearance.fonts.title : (sfProRounded.name !== "" ? sfProRounded.name : "SF Pro Rounded")
            property string iconMaterial: "Material Symbols Rounded"
            property string expressive: typoFamily.title
            property string monospace: Config.ready ? Config.options.appearance.fonts.monospace : "JetBrains Mono NF"
        }
        property QtObject variableAxes: QtObject {
            id: typoAxes
            property var expressive: typoAxes.title
            property var main: ({
                "wght": 450,
                "wdth": 100,
            })
            property var numbers: ({
                "wght": 450,
            })
            property var title: ({
                "wght": 550,
            })
        }
        property QtObject pixelSize: QtObject {
            readonly property real scale: root.effectiveScale
            property int smallest: Math.round(10 * scale)
            property int smaller: Math.round(12 * scale)
            property int small: Math.round(14 * scale)
            property int normal: Math.round(16 * scale)
            property int large: Math.round(18 * scale)
            property int larger: Math.round(20 * scale)
            property int huge: Math.round(24 * scale)
            property int title: Math.round(22 * scale)
        }
    }

    // --- Sizes ---
    sizes: QtObject {
        readonly property var screen: Quickshell.screens[0]
        readonly property real scale: root.effectiveScale

        property real statusBarHeight: 40 * scale
        property real touchTarget: 48 * scale
        property real elevationMargin: 12 * scale
        
        // Dynamic Sidebar Panel sizing
        property real quickSettingsWidth: Math.min(420 * scale, screen.width * 0.35)
        property real quickSettingsMaxHeight: Math.min(800 * scale, screen.height * 0.85)
        
        property real notificationCenterWidth: Math.min(420 * scale, screen.width * 0.35)
        property real notificationCenterMaxHeight: Math.min(800 * scale, screen.height * 0.85)

        // New scaling tokens for internal components
        property real notificationIslandMaxHeight: Math.min(450 * scale, screen.height * 0.5)
        property real lockClockSize: Math.min(120 * scale, screen.width * 0.1)
        property real lockInputWidth: Math.min(300 * scale, screen.width * 0.25)
        
        property real toggleTileSize: 72 * scale
        property real sliderHeight: 48 * scale
        property real iconSize: 20 * scale

        // Calendar
        property real calendarWidth: Math.min(360 * scale, screen.width * 0.3)
        property real calendarSpacing: 4 * scale
        property real calendarCellSize: Math.floor((calendarWidth - (48 * scale) - (calendarSpacing * 6)) / 7)

        // Dashboard (Calendar panel redesign)
        property real dashboardWidth: Math.min(860 * scale, screen.width * 0.68)
        property real dashboardHeight: Math.min(450 * scale, screen.height * 0.75)

        // Context Menu
        property real contextMenuWidth: Math.min(220 * scale, screen.width * 0.15)
        property real contextMenuItemHeight: 40 * scale
    }

    // --- Animation Curves (M3 Expressive) ---
    animationCurves: QtObject {
        readonly property list<double> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<double> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<double> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<double> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<double> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property list<double> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1]
        readonly property list<double> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
    }

    animation: QtObject {
        property QtObject elementMove: QtObject {
            property int duration: 500
            property int type: Easing.BezierSpline
            property list<double> bezierCurve: animationCurves.expressiveDefaultSpatial
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
        }
        property QtObject elementMoveEnter: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<double> bezierCurve: animationCurves.emphasizedDecel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }
        property QtObject elementMoveExit: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<double> bezierCurve: animationCurves.emphasizedAccel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveExit.duration
                    easing.type: root.animation.elementMoveExit.type
                    easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
                }
            }
        }
        property QtObject elementMoveFast: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<double> bezierCurve: animationCurves.expressiveEffects
            property int velocity: 850
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
            property Component colorAnimation: Component {
                ColorAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
        }
        property QtObject elementResize: QtObject {
            property int duration: 300
            property int type: Easing.BezierSpline
            property list<double> bezierCurve: animationCurves.emphasized
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementResize.duration
                    easing.type: root.animation.elementResize.type
                    easing.bezierCurve: root.animation.elementResize.bezierCurve
                }
            }
        }
        property QtObject scroll: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<double> bezierCurve: animationCurves.emphasizedDecel
        }
    }
}
