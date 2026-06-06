pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool active: false
    property double elapsedMs: 0
    property double startTimestamp: Date.now()

    readonly property double elapsedTime: elapsedMs / 1000

    readonly property string timeString: {
        const totalSecs = Math.floor(elapsedTime);
        const hrs = Math.floor(totalSecs / 3600);
        const mins = Math.floor((totalSecs % 3600) / 60);
        const secs = totalSecs % 60;
        
        if (hrs > 0) {
            return `${hrs}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        }
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    }

    readonly property string timeStringDetailed: {
        const totalMs = Math.floor(elapsedMs);
        const totalSecs = Math.floor(totalMs / 1000);
        const hrs = Math.floor(totalSecs / 3600);
        const mins = Math.floor((totalSecs % 3600) / 60);
        const secs = totalSecs % 60;
        const tenths = Math.floor((totalMs % 1000) / 100);
        
        if (hrs > 0) {
            return `${hrs}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}.${tenths}`;
        }
        return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}.${tenths}`;
    }

    function start() {
        if (elapsedMs === 0) {
            startTimestamp = Date.now();
        } else {
            startTimestamp = Date.now() - elapsedMs;
        }
        active = true;
    }

    function pause() {
        active = false;
    }

    function reset() {
        active = false;
        elapsedMs = 0;
        startTimestamp = Date.now();
    }

    Timer {
        id: timer
        interval: 50 // Update frequently for smooth sub-second rendering
        repeat: true
        running: root.active
        onTriggered: {
            root.elapsedMs = Date.now() - root.startTimestamp;
        }
    }
}
