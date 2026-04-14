//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import qs.core
import qs.services
import qs.widgets
import qs.panels.StatusBar
import qs.panels.NotificationCenter
import qs.panels.NotificationPopup
import qs.panels.QuickSettings
import qs.panels.Dashboard
import qs.panels.SystemMonitor
import qs.panels.Launcher
import qs.panels.Overview
import qs.panels.QuickActions
import qs.panels.Dock
import qs.panels.ScreenCorners
import qs.panels.RegionSelector

import "./panels/OSD"
// import "./panels/Polkit" // Disabled due to issues
import "./panels/Session"

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Wallpapers.syncSettings()
        
        // Touch singletons to ensure their IPC handlers/shortcuts are active
        let _rs = RegionSelector
        let _rm = RegionManager
    }

    StatusBar {}
    StatusBarTrayOverflow { id: trayOverflow }
    MediaNotchPopup {}

    NotificationPopup {}
    NotificationCenter {}
    QuickSettings {}
    Dashboard {}
    SystemMonitorPanel {}
    Launcher {}
    OverviewPopup {}
    RecordingMarker {}
    SpotlightLauncher {}
    QuickActions {}
    OSD {}
    // PolkitPanel {} // Disabled due to issues
    SessionPanel {}
    
    Dock {}
    ScreenCorners {}


    GlobalShortcut { name: "regionScreenshot"; onPressed: RegionManager.screenshot() }
    GlobalShortcut { name: "regionOcr"; onPressed: RegionManager.ocr() }
    GlobalShortcut { name: "regionSearch"; onPressed: RegionManager.search() }
    GlobalShortcut { name: "regionQRCode"; onPressed: RegionManager.qrcode() }
    GlobalShortcut { name: "regionRecord"; onPressed: RegionManager.record() }
    GlobalShortcut { name: "regionRecordWithSound"; onPressed: RegionManager.recordWithSound() }

    GlobalShortcut { name: "spotlightFiles"; onPressed: { GlobalStates.initialSpotlightQuery = Config.options.search.filePrefix; GlobalStates.spotlightOpen = true; } }
    GlobalShortcut { name: "spotlightCommand"; onPressed: { GlobalStates.initialSpotlightQuery = Config.options.search.commandPrefix; GlobalStates.spotlightOpen = true; } }
    GlobalShortcut { name: "spotlightClipboard"; onPressed: { GlobalStates.initialSpotlightQuery = Config.options.search.clipboardPrefix; GlobalStates.spotlightOpen = true; } }
    GlobalShortcut { name: "spotlightEmoji"; onPressed: { GlobalStates.initialSpotlightQuery = Config.options.search.emojiPrefix; GlobalStates.spotlightOpen = true; } }
    
    GlobalShortcut { name: "quickActions"; onPressed: GlobalStates.quickActionsOpen = !GlobalStates.quickActionsOpen }

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
        target: "overview"
        function open() { GlobalStates.overviewOpen = true }
        function close() { GlobalStates.overviewOpen = false }
        function toggle() { GlobalStates.overviewOpen = !GlobalStates.overviewOpen }
    }

    IpcHandler {
        target: "launcher"
        function open() { GlobalStates.launcherOpen = true }
        function close() { GlobalStates.launcherOpen = false }
        function toggle() { GlobalStates.launcherOpen = !GlobalStates.launcherOpen }
    }

    IpcHandler {
        target: "spotlight"
        function open() { GlobalStates.initialSpotlightQuery = ""; GlobalStates.spotlightOpen = true }
        function close() { GlobalStates.spotlightOpen = false }
        function toggle() { 
            if (!GlobalStates.spotlightOpen) GlobalStates.initialSpotlightQuery = "";
            GlobalStates.spotlightOpen = !GlobalStates.spotlightOpen 
        }
    }

    IpcHandler {
        target: "session"
        function open() { GlobalStates.sessionOpen = true }
        function close() { GlobalStates.sessionOpen = false }
        function toggle() { GlobalStates.sessionOpen = !GlobalStates.sessionOpen }
    }

    IpcHandler {
        target: "systemmonitor"
        function open() { GlobalStates.systemMonitorOpen = true }
        function close() { GlobalStates.systemMonitorOpen = false }
        function toggle() { GlobalStates.systemMonitorOpen = !GlobalStates.systemMonitorOpen }
    }

    IpcHandler {
        target: "dashboard"
        function open() { GlobalStates.dashboardOpen = true }
        function close() { GlobalStates.dashboardOpen = false }
        function toggle() { GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen }
    }

    IpcHandler {
        target: "quickactions"
        function open() { GlobalStates.quickActionsOpen = true }
        function close() { GlobalStates.quickActionsOpen = false }
        function toggle() { GlobalStates.quickActionsOpen = !GlobalStates.quickActionsOpen }
    }

    IpcHandler {
        target: "settings"
        function open() { GlobalStates.settingsOpen = true }
        function close() { GlobalStates.settingsOpen = false }
        function toggle() { GlobalStates.settingsOpen = !GlobalStates.settingsOpen }
        function open_direct() { GlobalStates.settingsOpen = true }
    }

}
