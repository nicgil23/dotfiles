pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

/**
 * Handles VPN UCM (GlobalProtect) state and toggle.
 */
Singleton {
    id: root

    property bool active: false
    readonly property string scriptPath: "/home/hypr/dotfiles/hyprland/.config/hypr/scripts/vpn-ucm.sh"

    function toggle() {
        Quickshell.execDetached(["bash", root.scriptPath]);
        // State will be updated by the polling timer
    }

    // Active state check process
    Process {
        id: activeStateProc
        command: ["pgrep", "-x", "openconnect"]
        onExited: (exitCode) => {
            root.active = (exitCode === 0);
        }
    }

    // Polling timer to keep the toggle UI accurate
    Timer {
        id: pollTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            activeStateProc.running = false;
            activeStateProc.running = true;
        }
    }
}
