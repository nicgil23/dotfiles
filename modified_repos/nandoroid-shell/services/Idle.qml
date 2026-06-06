pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property bool hypridleRunning: false
    // Caffeine is active if hypridle is NOT running
    property bool active: !hypridleRunning

    // Process to check if hypridle is running
    Process {
        id: checkProc
        command: ["pgrep", "-x", "hypridle"]
        running: false
        onExited: exitCode => {
            root.hypridleRunning = (exitCode === 0);
            // Sync config if needed, though usually config drives this
            if (Config.options.quickSettings.caffeineActive !== root.active) {
                Config.options.quickSettings.caffeineActive = root.active;
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

    function toggle() {
        if (root.hypridleRunning) {
            // Stop hypridle
            Quickshell.execDetached(["pkill", "-x", "hypridle"]);
            root.hypridleRunning = false;
        } else {
            // Start hypridle
            Quickshell.execDetached(["hypridle"]);
            root.hypridleRunning = true;
        }
        Config.options.quickSettings.caffeineActive = root.active;
    }

    // Handle external config changes (e.g. from settings panel)
    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready && Config.options.quickSettings.caffeineActive !== root.active) {
                root.toggle();
            }
        }
    }

    Connections {
        target: Config.options.quickSettings
        function onCaffeineActiveChanged() {
            if (Config.ready && Config.options.quickSettings.caffeineActive !== root.active) {
                root.toggle();
            }
        }
    }
}
