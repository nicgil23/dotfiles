pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: Config.ready ? Config.options.system.conservationMode : false
    onActiveChanged: if (Config.ready) Config.options.system.conservationMode = active
    property bool available: false
    readonly property string sysPath: "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

    Process {
        id: checkAvailabilityProc
        command: ["bash", "-c", "[ -f " + sysPath + " ] && echo 'yes' || echo 'no'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.available = data.trim() === "yes";
            }
        }
    }

    Process {
        id: refreshProc
        command: ["cat", sysPath]
        running: available
        stdout: SplitParser {
            onRead: data => {
                const val = data.trim();
                if (val === "1" || val === "0") {
                    root.active = val === "1";
                }
            }
        }
    }

    Process {
        id: toggleProc
        onExited: refreshProc.running = true
    }

    readonly property string batteryIcon: Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/assets/icons/NAnDoroid.svg"

    function toggle() {
        if (!available) return;
        const newState = active ? "0" : "1";
        const msg = active ? "Deactivating Conservation Mode..." : "Activating Conservation Mode...";
        
        Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", root.batteryIcon, "-t", "3000", "--", "Battery", msg]);
        
        // We use pkexec which might trigger a password dialog
        toggleProc.exec(["pkexec", "sh", "-c", 'echo "$1" > "$2"', "sh", newState, sysPath]);
    }

    Timer {
        interval: 10000
        running: available
        repeat: true
        onTriggered: refreshProc.running = true
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready && root.available) {
                const shouldBe = Config.options.system.conservationMode;
                // Only enforce if different from hardware to avoid redundant pkexec calls
                if (shouldBe !== root.active) {
                    root.toggle();
                }
            }
        }
    }
}
