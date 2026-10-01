pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../core"

Singleton {
    id: root

    property string currentProfile: "daily"
    property bool hasAutoCpufreq: true

    readonly property bool useCustomProfile: (Config.ready && Config.options.powerProfile) ? Config.options.powerProfile.enabled : false
    readonly property string customPath: (Config.ready && Config.options.powerProfile) ? Config.options.powerProfile.customPath : "/tmp/ryzen_mode"

    // Reactive: PowerProfiles.profileChanged fires on D-Bus signal
    property var _ppProfile: useCustomProfile ? null : PowerProfiles.profile
    on_PpProfileChanged: {
        if (!useCustomProfile && !hasAutoCpufreq && _ppProfile !== null && _ppProfile !== undefined) {
            const map = ["daily", "balanced", "performance"];
            const val = map[_ppProfile] || "balanced";
            if (root.currentProfile !== val) root.currentProfile = val;
        }
    }

    // Reactive: custom path file changes via inotify
    FileView {
        id: customFileView
        path: root.useCustomProfile ? root.customPath : ""
        watchChanges: true
        onFileChanged: customFileView.reload()
        onLoaded: {
            const val = customFileView.text().trim().toLowerCase();
            if (root.useCustomProfile && ["daily", "balanced", "performance"].includes(val)) {
                if (root.currentProfile !== val) root.currentProfile = val;
            }
        }
    }

    // Process to check current auto-cpufreq profile
    Process {
        id: autoCpufreqCheckProc
        command: ["bash", "-c", "which auto-cpufreq >/dev/null 2>&1 && if [ -f /opt/auto-cpufreq/override.pickle ]; then if grep -qs 'performance' /opt/auto-cpufreq/override.pickle; then echo 'performance'; elif grep -qs 'powersave' /opt/auto-cpufreq/override.pickle; then echo 'daily'; else echo 'balanced'; fi; else echo 'balanced'; fi || echo 'none'"]
        stdout: SplitParser {
            onRead: data => {
                const val = data.trim();
                if (val === "none") {
                    root.hasAutoCpufreq = false;
                } else if (["daily", "balanced", "performance"].includes(val)) {
                    root.hasAutoCpufreq = true;
                    if (!root.useCustomProfile && root.currentProfile !== val) {
                        root.currentProfile = val;
                    }
                }
            }
        }
    }

    // Timer to periodically poll auto-cpufreq state
    Timer {
        id: pollTimer
        interval: 3000
        running: !root.useCustomProfile
        repeat: true
        onTriggered: {
            if (!autoCpufreqCheckProc.running) {
                autoCpufreqCheckProc.running = true;
            }
        }
    }

    // Delayed check timer for after executing a profile switch
    Timer {
        id: postApplyTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (!autoCpufreqCheckProc.running) {
                autoCpufreqCheckProc.running = true;
            }
        }
    }

    onUseCustomProfileChanged: {
        if (useCustomProfile) {
            ensureFileExists();
        } else {
            customFileView.path = "";
            checkCurrentProfile();
        }
    }

    onCustomPathChanged: {
        if (useCustomProfile) {
            customFileView.path = root.customPath;
            customFileView.reload();
        }
    }

    Component.onCompleted: {
        if (useCustomProfile) {
            ensureFileExists();
        } else {
            checkCurrentProfile();
        }
    }

    function checkCurrentProfile() {
        if (useCustomProfile) {
            customFileView.reload();
        } else {
            if (!autoCpufreqCheckProc.running) {
                autoCpufreqCheckProc.running = true;
            }
        }
    }

    function ensureFileExists() {
        // Ensure file exists before FileView reads it (silences warnings)
        Quickshell.execDetached(["bash", "-c", `[ -f "${customPath}" ] && grep -qsE '^(daily|balanced|performance)$' "${customPath}" || echo "${currentProfile}" > "${customPath}"`]);
        customFileView.path = root.customPath;
        customFileView.reload();
    }

    function setProfile(profile) {
        if (root.currentProfile === profile) return;
        
        // Optimistic update for UI feel
        root.currentProfile = profile;
        
        // Write to custom file if enabled
        if (useCustomProfile) {
            Quickshell.execDetached(["bash", "-c", `echo "${profile}" > "${customPath}"`]);
        } else if (hasAutoCpufreq) {
            // Map profile to auto-cpufreq argument
            const autoCpufreqMap = { "daily": "powersave", "balanced": "reset", "performance": "performance" };
            const forceArg = autoCpufreqMap[profile] || "reset";
            
            // Execute via sudo (if passwordless) or pkexec
            Quickshell.execDetached(["bash", "-c", `sudo -n /usr/bin/auto-cpufreq --force=${forceArg} || pkexec /usr/bin/auto-cpufreq --force=${forceArg}`]);
            postApplyTimer.restart();
        } else {
            // Use PowerProfiles D-Bus API
            const map = { "daily": "PowerSaver", "balanced": "Balanced", "performance": "Performance" };
            if (PowerProfiles.profile !== undefined) {
                PowerProfiles.profile = map[profile] || "Balanced";
            }
        }
    }

    function cycle() {
        if (currentProfile === "daily") setProfile("balanced");
        else if (currentProfile === "balanced") setProfile("performance");
        else setProfile("daily");
    }
}
