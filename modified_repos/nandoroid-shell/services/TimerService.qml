pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int duration: 60
    property int remainingTime: 60
    property bool active: false

    property double startTimestamp: Date.now()
    property double elapsedMs: 0
    
    readonly property real progress: (duration > 0) ? Math.min(1.0, elapsedMs / (duration * 1000)) : 0

    readonly property string timeString: {
        const hrs = Math.floor(remainingTime / 3600);
        const mins = Math.floor((remainingTime % 3600) / 60);
        const secs = remainingTime % 60;
        
        if (hrs > 0) {
            return `${hrs}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        }
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    }

    function start() {
        if (remainingTime <= 0) remainingTime = duration;
        
        if (remainingTime === duration) {
            startTimestamp = Date.now();
        } else {
            startTimestamp = Date.now() - (duration - remainingTime) * 1000;
        }
        active = true;
    }

    function pause() {
        active = false;
    }

    function stop() {
        active = false;
        reset();
    }

    function reset() {
        active = false;
        remainingTime = duration;
        startTimestamp = Date.now();
        elapsedMs = 0;
    }

    function setDuration(secs) {
        duration = Math.max(1, secs);
        reset();
    }

    function completeTimer() {
        active = false;
        remainingTime = 0;
        
        // Play system sound
        Audio.playSystemSound("message");
        
        // Trigger desktop notification
        notifyProc.running = false;
        notifyProc.running = true;
    }

    Process {
        id: notifyProc
        command: ["notify-send", "-a", "Nandoroid Timer", "Temporizador finalizado", "¡El tiempo ha terminado!", "-i", "alarm-symbolic"]
    }

    Timer {
        id: timer
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: {
            const now = Date.now();
            root.elapsedMs = now - root.startTimestamp;
            const elapsed = Math.floor(root.elapsedMs / 1000);
            
            if (elapsed >= root.duration) {
                root.completeTimer();
            } else {
                root.remainingTime = Math.max(0, root.duration - elapsed);
            }
        }
    }
}
