pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property double startTimestamp: Date.now()
    property int duration: 1500
    property int remainingTime: duration
    
    property bool active: false
    
    // 0: Classic (Clásico) - 25m work / 5m break
    // 1: Extended (Extendido) - 50m work / 10m break
    property int pomodoroType: 0
    
    // 0: Trabajo (Work), 1: Descanso (Break)
    property int mode: 0 
    
    property int rotations: 0
    property bool autoContinue: true
    
    readonly property bool isSessionRunning: active || (remainingTime < duration && remainingTime > 0)
    
    readonly property string timeString: {
        const mins = Math.floor(remainingTime / 60);
        const secs = remainingTime % 60;
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    }

    readonly property string modeName: {
        if (mode === 0) return "Trabajo";
        return "Descanso";
    }

    property double elapsedMs: 0
    readonly property real progress: (duration > 0) ? Math.min(1.0, elapsedMs / (duration * 1000)) : 0

    function start() { 
        if (remainingTime === duration) {
            startTimestamp = Date.now();
        } else {
            startTimestamp = Date.now() - (duration - remainingTime) * 1000;
        }
        active = true; 
    }
    function pause() { active = false; }
    function stop() {
        active = false;
        reset();
    }

    function reset() {
        active = false;
        if (pomodoroType === 0) { // Classic
            duration = (mode === 0) ? 1500 : 300;
        } else { // Extended
            duration = (mode === 0) ? 3000 : 600;
        }
        remainingTime = duration;
        startTimestamp = Date.now();
        elapsedMs = 0;
    }

    function setPomodoroType(type) {
        pomodoroType = type;
        active = false;
        reset();
    }

    function setMode(newMode) {
        mode = newMode;
        active = false;
        reset();
    }

    function completeSession() {
        active = false;

        // Feedback (Sound)
        Audio.playSystemSound("message");

        // Transition logic
        if (mode === 0) {
            mode = 1; // Trabajo -> Descanso
        } else {
            rotations++;
            mode = 0; // Descanso -> Trabajo
        }
        
        reset(); 
        
        if (autoContinue) {
            active = true;
        }
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
            
            if (elapsed > root.duration) {
                root.completeSession();
            } else {
                const newRemaining = Math.max(0, root.duration - elapsed);
                if (newRemaining !== root.remainingTime) {
                    root.remainingTime = newRemaining;
                }
            }
        }
    }
}
