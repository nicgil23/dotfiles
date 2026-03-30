pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "." 

Singleton {
    id: root

    property bool active: Config.ready ? Config.options.system.gameModeActive : false
    onActiveChanged: if (Config.ready) Config.options.system.gameModeActive = active
    readonly property string persistencePath: "~/.config/hypr/nandoroid/user_persistence.conf"

    function toggle() {
        root.active = !root.active
        // Synchronize with Do Not Disturb
        Notifications.silent = root.active
        
        if (root.active) {
            const batchCmd = [
                "animations:enabled 0",
                "decoration:shadow:enabled 0",
                "decoration:blur:enabled 0",
                "general:gaps_in 0",
                "general:gaps_out 0",
                "general:border_size 1",
                "decoration:rounding 0",
                "general:allow_tearing 1"
            ];
            
            // Apply via hyprctl immediately
            Quickshell.execDetached(["bash", "-c", `hyprctl --batch "keyword ${batchCmd.join('; keyword ')}"`])
            
            // Persist to file
            const persistCmd = `sed -i '/animations:enabled/d; /decoration:shadow:enabled/d; /decoration:blur:enabled/d; /general:gaps_in/d; /general:gaps_out/d; /general:border_size/d; /decoration:rounding/d; /general:allow_tearing/d' ${root.persistencePath} 2>/dev/null || true; ` +
                batchCmd.map(c => `echo "${c.replace(' ', ' = ')}" >> ${root.persistencePath}`).join('; ');
            
            Quickshell.execDetached(["bash", "-c", persistCmd]);

        } else {
            // Revert via reload
            Quickshell.execDetached(["hyprctl", "reload"])

            // Cleanup from persistence file
            const cleanupCmd = `sed -i '/animations:enabled/d; /decoration:shadow:enabled/d; /decoration:blur:enabled/d; /general:gaps_in/d; /general:gaps_out/d; /general:border_size/d; /decoration:rounding/d; /general:allow_tearing/d' ${root.persistencePath} 2>/dev/null || true`;
            Quickshell.execDetached(["bash", "-c", cleanupCmd]);

            // Re-enforce other persistence (like layout) because reload wiped them
            const timer = Qt.createQmlObject('import QtQuick; Timer { interval: 1000; repeat: false; }', root);
            timer.triggered.connect(() => {
                if (typeof HyprlandData !== 'undefined') {
                    // This will re-apply general:layout from the file if it exists
                    const reapplyCmd = `cat ${root.persistencePath} 2>/dev/null | xargs -I {} hyprctl keyword {} || true`;
                    Quickshell.execDetached(["bash", "-c", reapplyCmd]);
                    HyprlandData.fetchInitialLayout();
                }
                timer.destroy();
            });
            timer.start();
        }
    }

    function fetchActiveState() {
        fetchActiveStateProc.running = true
    }

    Process {
        id: fetchActiveStateProc
        running: true
        command: ["bash", "-c", `test "$(hyprctl getoption animations:enabled -j | jq ".int")" -eq 0`]
        onExited: (exitCode, exitStatus) => {
            root.active = (exitCode === 0)
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready && Config.options.system.gameModeActive) {
                // Re-apply gamemode settings on startup if it was active in config
                // but not currently applied in the system.
                if (!root.active) root.toggle();
            }
        }
    }
}
