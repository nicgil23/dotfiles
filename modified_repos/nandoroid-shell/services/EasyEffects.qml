pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

/**
 * Handles EasyEffects active state and presets.
 */
Singleton {
    id: root

    property bool available: false
    property bool active: false

    readonly property string eeIcon: Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/assets/icons/NAnDoroid.svg"

    function disable() {
        if (Config.ready && Config.options.system) {
            Config.options.system.easyeffectsEnabled = false;
        }
        Quickshell.execDetached(["bash", "-c", "pkill -x easyeffects || flatpak pkill com.github.wwmm.easyeffects"]);
        Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", root.eeIcon, "-t", "2000", "--", "EasyEffects", "Deactivating effects..."]);
        root.active = false;
    }

    function enable() {
        if (Config.ready && Config.options.system) {
            Config.options.system.easyeffectsEnabled = true;
        }
        // Try multiple flags for different versions (v7 uses --gapplication-service, v6 uses --service-mode)
        Quickshell.execDetached(["bash", "-c", "easyeffects --gapplication-service || easyeffects --hide-window --service-mode || easyeffects || flatpak run com.github.wwmm.easyeffects --gapplication-service"]);
        Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", root.eeIcon, "-t", "2000", "--", "EasyEffects", "Activating effects..."]);
        root.active = true;
    }

    function toggle() {
        if (!root.available) {
            Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", root.eeIcon, "--", "EasyEffects", "Not installed. Check your packages."]);
            return;
        }
        if (root.active) {
            root.disable();
        } else {
            root.enable();
        }
    }

    // Availability check process
    Process {
        id: availabilityProc
        running: true
        command: ["bash", "-c", "command -v easyeffects || flatpak info com.github.wwmm.easyeffects > /dev/null 2>&1"]
        onExited: (exitCode) => {
            root.available = (exitCode === 0);
        }
    }

    // Active state check process
    Process {
        id: activeStateProc
        running: true
        command: ["bash", "-c", "pgrep -x easyeffects || pidof easyeffects || (flatpak ps | grep -q com.github.wwmm.easyeffects)"]
        onExited: (exitCode) => {
            root.active = (exitCode === 0);
        }
    }

    // Polling timer to keep the toggle UI accurate to the system state
    Timer {
        id: pollTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            activeStateProc.running = false;
            activeStateProc.running = true;
        }
    }

    // ENFORCEMENT: On startup, make reality match the user's last preference
    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready && Config.options.system) {
                const shouldBeEnabled = Config.options.system.easyeffectsEnabled;
                if (!shouldBeEnabled && root.active) {
                    root.disable();
                } else if (shouldBeEnabled && !root.active) {
                    root.enable();
                }
            }
        }
    }
}
