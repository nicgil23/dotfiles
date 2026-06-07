pragma Singleton
pragma ComponentBehavior: Bound
import "../../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

/**
 * Shared lock context — auth state synced across all monitor surfaces.
 * Ported from the ii example's common/panels/lock/LockContext.qml.
 */
Scope {
    id: root

    enum ActionEnum { Unlock, Poweroff, Reboot, Suspend }

    signal shouldReFocus()
    signal unlocked(var targetAction)
    signal failed()

    property string currentText: ""
    property string maskedText: ""
    readonly property list<string> kokomi: ["k", "o", "k", "o", "m", "i"]
    property string wallFg: ""
    property bool fgGenerating: false

    property string lockscreenWallpaper: {
        if (!Config.ready) return "";
        if (Config.options.lock.useSeparateWallpaper && Config.options.lock.wallpaperPath !== "") {
            return Config.options.lock.wallpaperPath;
        }
        return Config.options.appearance?.background?.wallpaperPath ?? "";
    }

    function trimFileProtocol(path) {
        return path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString();
    }

    function triggerForegroundExtraction() {
        if (!Config.ready) return;
        if (!Config.options.lock.useForegroundIsolation) {
            root.wallFg = "";
            return;
        }
        const path = trimFileProtocol(root.lockscreenWallpaper);
        if (path === "") return;
        
        generateFgProc.command = [
            "bash",
            Quickshell.shellPath("scripts/extractFg.sh"),
            path,
            Directories.genericCache + "/nandoroid"
        ];
        generateFgProc.running = false;
        Qt.callLater(() => { generateFgProc.running = true; });
    }

    Process {
        id: generateFgProc
        
        onRunningChanged: {
            root.fgGenerating = running;
        }

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("FOREGROUND")) {
                    root.wallFg = "file://" + data.split(" ")[1];
                }
            }
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                root.triggerForegroundExtraction();
            }
        }
    }

    Connections {
        target: (Config.ready && Config.options.lock) ? Config.options.lock : null
        ignoreUnknownSignals: true
        function onWallpaperPathChanged() { root.triggerForegroundExtraction(); }
        function onUseSeparateWallpaperChanged() { root.triggerForegroundExtraction(); }
        function onUseForegroundIsolationChanged() { root.triggerForegroundExtraction(); }
    }

    Connections {
        target: (Config.ready && Config.options.appearance?.background) ? Config.options.appearance.background : null
        ignoreUnknownSignals: true
        function onWallpaperPathChanged() {
            if (!Config.options.lock.useSeparateWallpaper) {
                root.triggerForegroundExtraction();
            }
        }
    }

    property bool unlockInProgress: false
    property bool showFailure: false
    property bool fingerprintsConfigured: false
    property var targetAction: LockContext.ActionEnum.Unlock
    property bool alsoInhibitIdle: false

    function resetTargetAction() {
        root.targetAction = LockContext.ActionEnum.Unlock
    }

    function clearText() {
        root.currentText = ""
    }

    function resetClearTimer() {
        passwordClearTimer.restart()
    }

    function reset() {
        root.resetTargetAction()
        root.clearText()
        root.maskedText = ""
        root.unlockInProgress = false
        stopFingerPam()
    }

    // Clear password after 10s of inactivity
    Timer {
        id: passwordClearTimer
        interval: 10000
        onTriggered: root.reset()
    }

    onCurrentTextChanged: {
        if (currentText.length > 0) {
            showFailure = false
            GlobalStates.screenUnlockFailed = false
        }
        GlobalStates.screenLockContainsCharacters = currentText.length > 0
        passwordClearTimer.restart()

        // Sync maskedText
        while (maskedText.length > currentText.length) {
            maskedText = maskedText.slice(0, -1);
        }
        while (maskedText.length < currentText.length) {
            maskedText += kokomi[Math.floor(Math.random() * kokomi.length)];
        }
    }

    function tryUnlock(alsoInhibitIdle = false) {
        root.alsoInhibitIdle = alsoInhibitIdle
        root.unlockInProgress = true
        pam.start()
    }

    function tryFingerUnlock() {
        if (root.fingerprintsConfigured) {
            fingerPam.start()
        }
    }

    function stopFingerPam() {
        if (fingerPam.active) {
            fingerPam.abort()
        }
    }

    // Check if fingerprints are enrolled
    Process {
        id: fingerprintCheckProc
        running: true
        command: ["bash", "-c", "fprintd-list $(whoami) 2>/dev/null"]
        stdout: StdioCollector {
            id: fingerprintOutput
            onStreamFinished: {
                root.fingerprintsConfigured = fingerprintOutput.text.includes("Fingerprints for user")
            }
        }
        onExited: (code, status) => {
            if (code !== 0) root.fingerprintsConfigured = false
        }
    }

    // Password PAM auth
    PamContext {
        id: pam
        onPamMessage: {
            if (this.responseRequired) this.respond(root.currentText)
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked(root.targetAction)
                stopFingerPam()
            } else {
                root.clearText()
                root.unlockInProgress = false
                GlobalStates.screenUnlockFailed = true
                root.showFailure = true
            }
        }
    }

    // Fingerprint PAM auth
    PamContext {
        id: fingerPam
        configDirectory: Quickshell.shellPath("panels/Lock/pam")
        config: "fprintd.conf"
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked(root.targetAction)
                stopFingerPam()
            } else if (result === PamResult.Error) {
                tryFingerUnlock()  // retry on timeout/error
            }
        }
    }
}
