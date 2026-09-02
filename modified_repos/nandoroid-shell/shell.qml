//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "core"
import "services"
import "widgets"
import "panels/StatusBar"
import "panels/Dashboard"
import "panels/NotificationCenter"
import "panels/QuickSettings"
import "panels/QuickActions"
import "panels/WallpaperSelector"
import "panels/WallpaperPicker"
import "panels/Background"
import "panels/NotificationPopup"
import "panels/OSD"
import "panels/Lock"
import "panels/Session"
import "panels/Launcher"
import "panels/SystemMonitor"
import "panels/Polkit"
import "panels/RegionSelector"
import "panels/ScreenCorners"
import "panels/Overview"
import "panels/Dock"
import "panels/Onboarding"
import "panels/FloatingLyrics"
import "panels/DatePicker"
import "panels/TimePicker"

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Reference singletons to ensure they are instantiated at startup
    readonly property var _caffeine: Caffeine
    readonly property var _versionService: VersionService
    readonly property var _idle: Idle

    Process {
        id: killSwayncProc
        command: ["killall", "swaync"]
    }

    Process {
        id: unblockBluetoothProc
        command: ["rfkill", "unblock", "bluetooth"]
    }

    Component.onCompleted: {
        killSwayncProc.running = true
        unblockBluetoothProc.running = true
        MaterialThemeLoader.reapplyTheme()
        Wallpapers.syncSettings() // Ensure Wallpapers service is active and synced
        SmartAutomation.runAutomationCycle() // Kickstart smart automation
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                if (!Config.options.system.onboardingCompleted) {
                    GlobalStates.onboardingOpen = true;
                }
                if (Config.options.workspaces && Config.options.workspaces.transitionStyle) {
                    HyprlandData.setWorkspaceTransition(Config.options.workspaces.transitionStyle);
                }
            }
        }
    }

    // ── Phase 0: Lock Screen ──
    Lock {}

    // ── Phase 1: Background ──
    Background {}
    DesktopWidgets {}
    FloatingLyrics {}

    // ── Phase 2: Status Bar ──
    StatusBar {}
    StatusBarTrayOverflow { id: trayOverflow }
    MediaNotchPopup {}
    DropzoneFloatingPopup {}

    // ── Phase 3: Popups ──
    NotificationPopup {}

    // ── Phase 4: Floating Panels (Dashboard, NotificationCenter, QuickSettings, QuickActions) ──
    NotificationCenterPanel {}
    QuickSettingsPanel {}
    DashboardPanel {}
    QuickActionsPanel {}

    // ── Phase 5: Popup closer (bridges closePopups signal to panel states) ──
    Connections {
        target: GlobalStates
        function onClosePopups() {
            GlobalStates.notificationCenterOpen = false;
            GlobalStates.quickSettingsOpen = false;
            GlobalStates.quickSettingsEditMode = false;
            GlobalStates.dashboardOpen = false;
            GlobalStates.quickActionsOpen = false;
        }
    }

    // ── Phase 6: Wallpaper Selector & Screen Decor ──
    WallpaperSelector {}
    WallpaperPicker {}
    ScreenCorners {}

    IpcHandler {
        target: "wallpaper"
        function openDesktop() {

            GlobalStates.wallpaperSelectorTarget = "desktop";
            GlobalStates.wallpaperSelectorOpen = true;
        }

        function openLock() {

            GlobalStates.wallpaperSelectorTarget = "lock";
            GlobalStates.wallpaperSelectorOpen = true;
        }
    }

    IpcHandler {
        target: "wallpaper_picker"
        function open() { GlobalStates.carouselWallpaperPickerOpen = true }
        function close() { GlobalStates.carouselWallpaperPickerOpen = false }
        function toggle() { GlobalStates.carouselWallpaperPickerOpen = !GlobalStates.carouselWallpaperPickerOpen }
    }

    // ── Phase 7: OSD ──
    OSD {}

    // ── Phase 8: Session Menu ──
    SessionPanel {}

    // ── Phase 8.5: Dock ──
    Dock {}

    // ── Phase 9: Launcher & Overview ──
    Launcher {}
    OverviewPopup {}

    SpotlightLauncher {}

    // ── Phase 10: Settings ──
    Settings {}


    // ── Phase 12: System Monitor & Onboarding ──
    SystemMonitorPanel {}
    OnboardingPanel {}

    // ── Phase 13: Polkit Agent & Date / Time Pickers ──
    PolkitPanel {}
    DatePickerPanel {}
    TimePickerPanel {}

    IpcHandler {
        target: "launcher"
        function open() { GlobalStates.launcherOpen = true }
        function close() { GlobalStates.launcherOpen = false }
        function toggle() { GlobalStates.launcherOpen = !GlobalStates.launcherOpen }
    }

    IpcHandler {
        target: "spotlight"
        function open() { 
            GlobalStates.initialSpotlightQuery = ""; 
            GlobalStates.spotlightOpen = true 
        }
        function close() { GlobalStates.spotlightOpen = false }
        function toggle() { 
            GlobalStates.initialSpotlightQuery = ""; 
            GlobalStates.spotlightOpen = !GlobalStates.spotlightOpen 
        }

        function browse_avatar() {
            avatarPickerProc.running = true;
        }
    }

    Process {
        id: avatarPickerProc
        command: ["zenity", "--file-selection", "--title=Select Avatar", "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.svg", "--modal"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path !== "") {
                    Config.options.bar.avatar_path = path;
                    Config.options.profile.avatarPicture = path;
                }
            }
        }
    }

    Connections {
        target: Wallpapers
        function onPickerFinished() {
            GlobalStates.wallpaperSelectorOpen = true;
        }
    }

    IpcHandler {
        target: "settings"
        function open() { GlobalStates.activateSettings() }
        function open_direct() { GlobalStates.settingsOpen = true }
        function close() { GlobalStates.settingsOpen = false }
        function toggle() { GlobalStates.activateSettings() }
    }

    IpcHandler {
        target: "notifications"
        function open() { GlobalStates.notificationCenterOpen = true }
        function close() { GlobalStates.notificationCenterOpen = false }
        function toggle() { GlobalStates.notificationCenterOpen = !GlobalStates.notificationCenterOpen }
    }

    IpcHandler {
        target: "quicksettings"
        function open() { GlobalStates.quickSettingsOpen = true }
        function close() { GlobalStates.quickSettingsOpen = false }
        function toggle() { GlobalStates.quickSettingsOpen = !GlobalStates.quickSettingsOpen }
    }

    IpcHandler {
        target: "quickactions"
        function open() { GlobalStates.quickActionsOpen = true }
        function close() { GlobalStates.quickActionsOpen = false }
        function toggle() { GlobalStates.quickActionsOpen = !GlobalStates.quickActionsOpen }
    }

    GlobalShortcut {
        name: "quickActions"
        description: "Toggles the quick actions panel"
        onPressed: GlobalStates.quickActionsOpen = !GlobalStates.quickActionsOpen
    }

    IpcHandler {
        target: "overview"
        function open() { GlobalStates.overviewOpen = true }
        function close() { GlobalStates.overviewOpen = false }
        function toggle() { GlobalStates.overviewOpen = !GlobalStates.overviewOpen }
    }

    IpcHandler {
        target: "dashboard"
        function open() { GlobalStates.dashboardOpen = true }
        function close() { GlobalStates.dashboardOpen = false }
        function toggle() { GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen }
    }

    // ==========================================
    // Native Wayland Global Shortcuts
    // ==========================================
    GlobalShortcut {
        name: "wallpaperSelector"
        description: "Toggle Wallpaper Selector"
        onPressed: {
            GlobalStates.wallpaperSelectorTarget = "desktop"
            GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen
        }
    }

    GlobalShortcut {
        name: "carouselWallpaperPicker"
        description: "Toggle Carousel Wallpaper Picker"
        onPressed: {
            GlobalStates.carouselWallpaperPickerOpen = !GlobalStates.carouselWallpaperPickerOpen
        }
    }

    GlobalShortcut {
        name: "wallpaperRandomFavorite"
        description: "Set a random favorite wallpaper"
        onPressed: Wallpapers.selectRandomFavorite()
    }

    GlobalShortcut {
        name: "settings"
        description: "Toggle Settings Panel"
        onPressed: GlobalStates.activateSettings()
    }

    GlobalShortcut {
        name: "spotlightEmoji"
        description: "Open Spotlight in Emoji mode"
        onPressed: {
            GlobalStates.initialSpotlightQuery = ":"
            GlobalStates.spotlightOpen = true
        }
    }

    GlobalShortcut {
        name: "spotlightFiles"
        description: "Open Spotlight in File search mode"
        onPressed: {
            GlobalStates.initialSpotlightQuery = "/"
            GlobalStates.spotlightOpen = true
        }
    }

    GlobalShortcut {
        name: "spotlightCommand"
        description: "Open Spotlight in Command mode"
        onPressed: {
            GlobalStates.initialSpotlightQuery = ">"
            GlobalStates.spotlightOpen = true
        }
    }

    GlobalShortcut {
        name: "spotlightTools"
        description: "Open Spotlight in Tools mode"
        onPressed: {
            GlobalStates.initialSpotlightQuery = "."
            GlobalStates.spotlightOpen = true
        }
    }

    GlobalShortcut {
        name: "spotlightClipboard"
        description: "Open Spotlight in Clipboard mode"
        onPressed: {
            GlobalStates.initialSpotlightQuery = ";"
            GlobalStates.spotlightOpen = true
        }
    }

    GlobalShortcut {
        name: "dropzoneToggle"
        description: "Toggle Dropzone Floating Island"
        onPressed: {
            GlobalStates.dropzoneNotchOpen = !GlobalStates.dropzoneNotchOpen
        }
    }

    IpcHandler {
        target: "session"
        function open() { GlobalStates.sessionOpen = true }
        function close() { GlobalStates.sessionOpen = false }
        function toggle() { GlobalStates.sessionOpen = !GlobalStates.sessionOpen }
    }

    IpcHandler {
        target: "pomodoro"
        function start() { PomodoroService.start() }
        function pause() { PomodoroService.pause() }
        function stop() { PomodoroService.stop() }
        function reset() { 
            PomodoroService.reset();
            PomodoroService.rotations = 0;
        }
    }

    IpcHandler {
        target: "systemmonitor"
        function open() { GlobalStates.activateSystemMonitor() }
        function open_direct() { GlobalStates.systemMonitorOpen = true }
        function close() { GlobalStates.systemMonitorOpen = false }
        function toggle() { GlobalStates.activateSystemMonitor() }
    }

    IpcHandler {
        target: "dropzone"
        function add(pathsStr: string) {
            if (!pathsStr) return
            let list = pathsStr.split(/[\r\n]+/).filter(p => p.trim().length > 0)
            DropzoneService.addFiles(list)
        }
        function open() { GlobalStates.dropzoneNotchOpen = true }
        function close() { GlobalStates.dropzoneNotchOpen = false }
        function toggle() { GlobalStates.dropzoneNotchOpen = !GlobalStates.dropzoneNotchOpen }
        function clear() { DropzoneService.clearAll() }
    }

    // ── Phase 14: Region Selector ──
    RegionSelector { id: regionSelector }
    RecordingMarker {}

    GlobalShortcut {
        name: "regionScreenshot"
        description: "Takes a screenshot of the selected region"
        onPressed: regionSelector.screenshot()
    }
    GlobalShortcut {
        name: "regionSearch"
        description: "Searches the selected region"
        onPressed: regionSelector.search()
    }
    GlobalShortcut {
        name: "regionOcr"
        description: "Recognizes text in the selected region"
        onPressed: regionSelector.ocr()
    }
    GlobalShortcut {
        name: "regionRecord"
        description: "Records the selected region"
        onPressed: regionSelector.record()
    }
    GlobalShortcut {
        name: "regionRecordWithSound"
        description: "Records the selected region with sound"
        onPressed: regionSelector.recordWithSound()
    }
    GlobalShortcut {
        name: "regionQRCode"
        description: "Scans a QR code in the selected region"
        onPressed: regionSelector.qrcode()
    }

    // ── Phase 15: Screenshot Overlay ──
    AccentPicker {}

    Variants {
        model: Quickshell.screens
        
        Loader {
            id: screenshotOverlayLoader
            required property var modelData
            active: true
            sourceComponent: ScreenshotOverlay {
                targetScreen: screenshotOverlayLoader.modelData
            }

            Connections {
                target: GlobalStates
                function onScreenshotTaken(path) {
                    if (Config.options.screenshot.showPreview) {
                        screenshotOverlayLoader.item.imagePath = path;
                    }
                }
            }
        }
    }
}
