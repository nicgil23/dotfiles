pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../core"

Singleton {
    id: root

    property int mode: Config.ready ? (Config.options.quickSettings.caffeineMode || (Config.options.quickSettings.caffeineActive ? 1 : 0)) : 0
    property bool hypridleRunning: false
    property bool active: mode !== 0

    function ensureHypridle() {
        Quickshell.execDetached(["bash", "-c", "pgrep -x hypridle >/dev/null || hypridle"]);
        root.hypridleRunning = true;
    }

    // Process to check if hypridle is running and restart it if stopped
    Process {
        id: checkProc
        command: ["pgrep", "-x", "hypridle"]
        running: false
        onExited: exitCode => {
            root.hypridleRunning = (exitCode === 0);
            if (exitCode !== 0) {
                root.ensureHypridle();
            }
        }
    }

    // Timer to periodically poll process status
    Timer {
        id: pollTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }

    // Ignore initial dpms event when switching to AFK mode
    property bool isSwitchingToAfk: false
    Timer {
        id: afkGuardTimer
        interval: 1000
        onTriggered: root.isSwitchingToAfk = false
    }

    function applyMode(targetMode) {
        root.mode = targetMode;
        root.ensureHypridle();

        if (targetMode === 0) {
            // Normal Mode: turn screen on
            Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "on"]);
        } else if (targetMode === 1) {
            // Awake Mode: ensure screen is on (idle inhibited via Caffeine service)
            Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "on"]);
        } else if (targetMode === 2) {
            // AFK Mode: turn screen off (idle inhibited via Caffeine service)
            root.isSwitchingToAfk = true;
            afkGuardTimer.restart();
            Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "off"]);
        }

        Config.options.quickSettings.caffeineActive = (targetMode !== 0);
        Config.options.quickSettings.caffeineMode = targetMode;
    }

    function toggle() {
        applyMode(root.mode === 1 ? 0 : 1);
    }

    // Listen to Hyprland raw events to detect when screen wakes up from AFK mode
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "dpms") {
                const dataStr = String(event.data).trim();
                if ((dataStr === "1" || dataStr === "true") && root.mode === 2 && !root.isSwitchingToAfk) {
                    // Screen woke up via key press or mouse move while in AFK mode -> Revert to Normal mode
                    root.applyMode(0);
                }
            }
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                let cfgMode = Config.options.quickSettings.caffeineMode || (Config.options.quickSettings.caffeineActive ? 1 : 0);
                if (cfgMode !== root.mode) {
                    root.applyMode(cfgMode);
                }
            }
        }
    }

    Connections {
        target: Config.options.quickSettings
        function onCaffeineModeChanged() {
            let cfgMode = Config.options.quickSettings.caffeineMode;
            if (Config.ready && cfgMode !== root.mode) {
                root.applyMode(cfgMode);
            }
        }
    }
}
