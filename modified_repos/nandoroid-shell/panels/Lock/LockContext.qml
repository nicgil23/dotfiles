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
    property bool unlockSuccess: false

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

    function toggleForegroundExtraction() {
        if (!Config.ready) return;
        const path = trimFileProtocol(root.lockscreenWallpaper);
        if (path === "") return;

        let prefs = {};
        try { prefs = JSON.parse(Config.options.lock.fgPreferencesJson); } catch(e) {}
        
        let isEnabled = prefs[path] === true;
        prefs[path] = !isEnabled;
        Config.options.lock.fgPreferencesJson = JSON.stringify(prefs);
        
        applyForegroundPreference();
    }

    function applyForegroundPreference() {
        if (!Config.ready) return;
        const path = trimFileProtocol(root.lockscreenWallpaper);
        if (path === "") {
            root.wallFg = "";
            return;
        }

        let prefs = {};
        try { prefs = JSON.parse(Config.options.lock.fgPreferencesJson); } catch(e) {}
        
        let isEnabled = prefs[path] === true;
        if (!isEnabled) {
            root.wallFg = "";
            return;
        }
        
        root.wallFg = ""; // Clear old image while generating
        fgProcComponent.createObject(root, { targetPath: path });
    }

    property int activeGenerations: 0
    onActiveGenerationsChanged: root.fgGenerating = (activeGenerations > 0)

    Component {
        id: fgProcComponent
        Process {
            property string targetPath: ""
            command: [
                "bash",
                Quickshell.shellPath("scripts/extractFg.sh"),
                targetPath,
                Directories.genericCache + "/nandoroid"
            ]
            running: true
            
            Component.onCompleted: root.activeGenerations++
            
            onRunningChanged: {
                if (!running) {
                    root.activeGenerations--
                    this.destroy()
                }
            }

            stdout: SplitParser {
                onRead: data => {
                    if (data.includes("FOREGROUND")) {
                        if (targetPath === root.trimFileProtocol(root.lockscreenWallpaper)) {
                            root.wallFg = "file://" + data.split(" ")[1];
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                root.applyForegroundPreference();
            }
        }
    }

    Connections {
        target: (Config.ready && Config.options.lock) ? Config.options.lock : null
        ignoreUnknownSignals: true
        function onWallpaperPathChanged() { root.applyForegroundPreference(); }
        function onUseSeparateWallpaperChanged() { root.applyForegroundPreference(); }
    }

    Connections {
        target: (Config.ready && Config.options.appearance?.background) ? Config.options.appearance.background : null
        ignoreUnknownSignals: true
        function onWallpaperPathChanged() {
            if (!Config.options.lock.useSeparateWallpaper) {
                root.applyForegroundPreference();
            }
        }
    }

    property bool unlockInProgress: false
    property bool showFailure: false
    property bool fingerprintsConfigured: false
    property var targetAction: LockContext.ActionEnum.Unlock
    property bool alsoInhibitIdle: false

    // Fingerprint failure tracking
    property int fingerFailCount: 0
    readonly property int maxFingerAttempts: 5
    property bool fingerFailed: false   // momentary flash on each failure
    property bool fingerLocked: false   // true after maxFingerAttempts reached
    property bool manualAbort: false

    // Password failure and lockout tracking
    property int passwordFailCount: 0
    readonly property int maxPasswordAttempts: 5
    property bool passwordLocked: false
    property int lockoutTimeRemaining: 0

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
        root.unlockSuccess = false
        root.fingerFailed = false
        stopFingerPam()
    }

    // Clear password after 10s of inactivity
    Timer {
        id: passwordClearTimer
        interval: 10000
        onTriggered: root.reset()
    }

    Timer {
        id: unlockDelayTimer
        interval: 500
        repeat: false
        onTriggered: {
            root.unlocked(root.targetAction)
            root.unlockSuccess = false
            root.unlockInProgress = false
        }
    }

    function handleSuccess() {
        root.passwordFailCount = 0
        root.fingerFailCount = 0
        root.passwordLocked = false
        root.lockoutTimeRemaining = 0
        root.fingerLocked = false
        stopFingerPam()
        
        root.unlockSuccess = true
        unlockDelayTimer.start()
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
        if (root.passwordLocked) return
        root.alsoInhibitIdle = alsoInhibitIdle
        root.unlockInProgress = true
        pam.start()
    }

    property double lastFingerPamStartTime: 0

    function tryFingerUnlock() {
        if (root.fingerprintsConfigured && !root.fingerLocked && !fingerPam.active) {
            root.lastFingerPamStartTime = Date.now()
            fingerPam.start()
        }
    }

    function stopFingerPam() {
        if (fingerPam.active) {
            root.manualAbort = true
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
                root.handleSuccess()
            } else {
                root.clearText()
                root.unlockInProgress = false
                GlobalStates.screenUnlockFailed = true
                root.showFailure = true

                root.passwordFailCount++
                if (root.passwordFailCount >= root.maxPasswordAttempts) {
                    root.passwordLocked = true
                    root.lockoutTimeRemaining = 180 // 3 minutes
                }
            }
        }
    }

    // Fingerprint failure flash reset timer
    Timer {
        id: fingerFailResetTimer
        interval: 1500
        onTriggered: root.fingerFailed = false
    }

    // Fingerprint retry delay timer
    Timer {
        id: fingerRetryTimer
        interval: 900
        onTriggered: root.tryFingerUnlock()
    }

    // Lockout countdown timer
    Timer {
        id: lockoutTimer
        interval: 1000
        repeat: true
        running: root.lockoutTimeRemaining > 0
        onTriggered: {
            root.lockoutTimeRemaining--
            if (root.lockoutTimeRemaining <= 0) {
                root.passwordLocked = false
                root.passwordFailCount = 0
            }
        }
    }

    // Watchdog to ensure fingerprint polling is active when locked
    Timer {
        id: fingerWatchdogTimer
        interval: 2000
        repeat: true
        running: GlobalStates.screenLocked && root.fingerprintsConfigured && !root.fingerLocked
        onTriggered: {
            if (!fingerPam.active) {
                root.tryFingerUnlock()
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
                root.handleSuccess()
            } else {
                if (root.manualAbort) {
                    root.manualAbort = false
                    return
                }

                var elapsed = Date.now() - root.lastFingerPamStartTime
                if (elapsed < 500) {
                    // Ignore instant failures caused by daemon restart/initialization
                    fingerRetryTimer.restart()
                    return
                }

                root.fingerFailCount++
                root.fingerFailed = true
                fingerFailResetTimer.restart()

                if (root.fingerFailCount >= root.maxFingerAttempts) {
                    root.fingerLocked = true
                } else {
                    fingerRetryTimer.restart()
                }
            }
        }
    }
}
