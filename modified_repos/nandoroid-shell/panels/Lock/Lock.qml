pragma ComponentBehavior: Bound
import "../../core"
import "../../services"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Lock panel — Wayland session lock entry point.
 * Saves + restores Hyprland workspaces on lock/unlock.
 * Ported from the ii example's modules/ii/lock/Lock.qml.
 */
Scope {
    id: root

    // Monitor name → workspace id saved at lock time
    property var savedWorkspaces: ({})

    // Restore workspaces after a short delay (compositor needs to settle)
    Timer {
        id: restoreTimer
        interval: 150
        repeat: false
        onTriggered: {
            var batch = []
            for (var j = 0; j < Quickshell.screens.length; ++j) {
                var monName = Quickshell.screens[j].name
                var wsId = root.savedWorkspaces[monName]
                if (wsId !== undefined && wsId < 1000000) {
                    batch.push("dispatch " + HyprlandCompat.dspFocusMonitor(monName))
                    batch.push("dispatch " + HyprlandCompat.dspWorkspace(wsId))
                }
            }
            if (batch.length > 0) {
                Quickshell.execDetached(HyprlandCompat.batch(batch))
            }
        }
    }

    // WlSessionLock — actual Wayland lock protocol
    WlSessionLock {
        id: wlLock
        locked: GlobalStates.screenLocked
        surface: Component {
            WlSessionLockSurface {
                color: "transparent"
                Loader {
                    active: true
                    anchors.fill: parent
                    opacity: GlobalStates.screenLocked ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                        }
                    }
                    sourceComponent: Component {
                        LockSurface {
                            context: LockContext
                        }
                    }
                }
            }
        }
    }

    readonly property string idleHandlerScript: Directories.home.replace("file://", "") + "/.config/hypr/scripts/idle-handler.sh"

    // Lockscreen Inactivity Sleep State Machine
    readonly property int lockscreenDimTimeoutMs: 20000       // 20s
    readonly property int lockscreenDpmsTimeoutMs: 30000      // 30s (6 min total desde inicio de AFK)
    readonly property int lockscreenSuspendTimeoutMs: 270000  // 4.5 min (10 min total desde inicio de AFK)

    Timer {
        id: lockscreenDimTimer
        interval: root.lockscreenDimTimeoutMs
        repeat: false
        running: GlobalStates.screenLocked
        onTriggered: {
            Quickshell.execDetached([root.idleHandlerScript, "lockscreen-dim"])
        }
    }

    Timer {
        id: lockscreenDpmsTimer
        interval: root.lockscreenDpmsTimeoutMs
        repeat: false
        running: GlobalStates.screenLocked
        onTriggered: {
            Quickshell.execDetached([root.idleHandlerScript, "dpms-off"])
        }
    }

    Timer {
        id: lockscreenSuspendTimer
        interval: root.lockscreenSuspendTimeoutMs
        repeat: false
        running: GlobalStates.screenLocked
        onTriggered: {
            Quickshell.execDetached([root.idleHandlerScript, "suspend"])
        }
    }

    function handleLockscreenActivity() {
        if (!GlobalStates.screenLocked) return
        lockscreenDimTimer.restart()
        lockscreenDpmsTimer.restart()
        lockscreenSuspendTimer.restart()
        Quickshell.execDetached([root.idleHandlerScript, "dpms-on"])
    }

    Connections {
        target: LockContext
        function onActivityDetected() {
            root.handleLockscreenActivity()
        }
    }

    // Save workspaces on lock / restore on unlock / re-focus lock screen
    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                // Save workspaces and push to temp workspace
                var next = {}
                var batch = [HyprlandCompat.keywordStr("animation", "workspaces", '"1,7,default,slidevert"')]
                for (var i = 0; i < Quickshell.screens.length; ++i) {
                    var screen = Quickshell.screens[i]
                    var mon = screen.name
                    var hMon = Hyprland.monitorFor(screen)
                    var ws = (hMon?.activeWorkspace?.id ?? 1)
                    if (ws > 1000000) {
                        ws = root.savedWorkspaces[mon] ?? 1
                    }
                    next[mon] = ws
                    batch.push("dispatch " + HyprlandCompat.dspFocusMonitor(mon))
                    batch.push("dispatch " + HyprlandCompat.dspWorkspace(2147483647 - ws))
                }
                root.savedWorkspaces = next
                Quickshell.execDetached(HyprlandCompat.batch(batch))
                // Reset auth state and try fingerprint
                LockContext.reset()
                LockContext.tryFingerUnlock()
                lockscreenDimTimer.restart()
                lockscreenDpmsTimer.restart()
                lockscreenSuspendTimer.restart()
            } else {
                lockscreenDimTimer.stop()
                lockscreenDpmsTimer.stop()
                lockscreenSuspendTimer.stop()
                restoreTimer.start()
            }
        }
    }

    // Post-authentication actions
    Connections {
        target: LockContext
        function onUnlocked(targetAction) {
            if (targetAction === LockContext.ActionEnum.Poweroff) {
                Quickshell.execDetached(["systemctl", "poweroff"])
                return
            } else if (targetAction === LockContext.ActionEnum.Reboot) {
                Quickshell.execDetached(["systemctl", "reboot"])
                return
            } else if (targetAction === LockContext.ActionEnum.Suspend) {
                Quickshell.execDetached(["systemctl", "suspend"])
                return
            }
            // Plain unlock
            GlobalStates.screenLocked = false
            Quickshell.execDetached([root.idleHandlerScript, "resume-force"])
            LockContext.reset()
        }
    }

    // Lock function
    function lock() {
        if (Config.options.lock.useHyprlock) {
            Quickshell.execDetached(["bash", "-c", "pidof hyprlock || hyprlock"])
            return
        }
        GlobalStates.screenLocked = true
    }

    // Global shortcut: Super+L to lock
    GlobalShortcut {
        name: "lock"
        description: "Lock the screen"
        onPressed: root.lock()
    }

    // IPC handler: `qs ipc call lock activate`
    IpcHandler {
        target: "lock"

        function activate(): void {
            root.lock()
        }

        function isLocked(): bool {
            return GlobalStates.screenLocked
        }

        function focus(): void {
            LockContext.shouldReFocus()
        }

        function abortFingerPam(): void {
            LockContext.stopFingerPam()
        }
    }
}
