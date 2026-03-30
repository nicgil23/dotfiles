pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * PomodoroService – singleton timer state for the Pomodoro tab.
 * Modes: 0=Focus (25min), 1=Short Break (5min), 2=Long Break (15min)
 */
Singleton {
    id: root

    // Durations in seconds
    readonly property var durations: [25 * 60, 5 * 60, 15 * 60]

    property int mode: 0          // 0=Focus, 1=Short, 2=Long
    property int nextBreakMode: 1 // 1=Short, 2=Long
    property int rotations: 0
    property bool active: false
    // Alias so DynamicIsland can reference PomodoroService.isSessionRunning
    readonly property bool isSessionRunning: active
    property bool autoContinue: false
    property int remaining: durations[mode]

    // Derived
    readonly property real progress: 1.0 - remaining / durations[mode]
    readonly property string timeString: {
        const m = Math.floor(remaining / 60)
        const s = remaining % 60
        return Qt.formatTime(new Date(0, 0, 0, 0, m, s), "mm:ss")
    }
    readonly property string modeName: ["Focus", "Short Break", "Long Break"][mode]

    // Tick every second when active
    Timer {
        interval: 1000
        running: root.active
        repeat: true
        onTriggered: {
            if (root.remaining > 0) {
                root.remaining--;
            } else {
                root.active = false;
                if (root.mode === 0) root.rotations++;
                if (root.autoContinue) {
                    root.mode = (root.mode === 0) ? root.nextBreakMode : 0;
                    root.remaining = root.durations[root.mode];
                    root.active = true;
                }
            }
        }
    }

    function setMode(m) {
        mode = m
        remaining = durations[m]
        active = false
    }

    function start() { active = true }

    function pause() { active = false }

    function stop() {
        active = false
        remaining = durations[mode]
    }

    function reset() {
        active = false
        remaining = durations[mode]
        rotations = 0
    }
}
