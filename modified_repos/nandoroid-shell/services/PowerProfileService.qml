pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * Power Profile Service
 * Manages system power profiles (Power Saving, Balanced, Performance).
 * Uses internal state tracking (booleans) to ensure UI responsiveness.
 */
Singleton {
    id: root

    // -- State --
    property string currentProfile: "daily" // Always start in Power Saving as requested
    property bool hasPowerProfilesCtl: false
    property bool hasAutoCpufreq: false

    readonly property bool useCustomProfile: (Config.ready && Config.options.powerProfile) ? Config.options.powerProfile.enabled : false
    readonly property string customPath: (Config.ready && Config.options.powerProfile) ? Config.options.powerProfile.customPath : "/tmp/ryzen_mode"
    readonly property string powerIcon: Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/assets/icons/NAnDoroid.svg"

    Component.onCompleted: {
        checkToolsProc.running = true;
    }

    // -- Backend: Process for switching --
    Process {
        id: setProc
        onExited: (exitCode, exitStatus) => {
            console.log("PowerProfileService: setProc finished with code " + exitCode);
        }
    }

    // -- Backend: Tool Detection --
    Process {
        id: checkToolsProc
        command: ["bash", "-c", "which auto-cpufreq >/dev/null && echo 'acf'; which powerprofilesctl >/dev/null && echo 'ppc'"]
        stdout: SplitParser {
            onRead: data => {
                if (data.includes("ppc")) root.hasPowerProfilesCtl = true;
                if (data.includes("acf")) root.hasAutoCpufreq = true;
            }
        }
    }

    /**
     * setProfile
     * Updates internal state and sends the command to the system backend.
     */
    function setProfile(profile) {
        if (root.currentProfile === profile) return;
        
        console.log("PowerProfileService: switching to", profile);
        root.currentProfile = profile; // Update UI state immediately (Boolean-like logic)

        let cmd = [];
        if (useCustomProfile) {
            cmd = ["bash", "-c", `echo "${profile}" > "${customPath}"`];
        } else if (hasAutoCpufreq) {
            // Priority: auto-cpufreq via pkexec
            let acfMode = (profile === "daily") ? "powersave" : (profile === "performance" ? "performance" : "reset");
            cmd = ["pkexec", "auto-cpufreq", "--force", acfMode];
        } else if (hasPowerProfilesCtl) {
            // Fallback: powerprofilesctl
            let mapping = { "daily": "power-saver", "balanced": "balanced", "performance": "performance" };
            let ppcMode = mapping[profile] || "balanced";
            cmd = ["powerprofilesctl", "set", ppcMode];
        }

        if (cmd.length > 0) {
            setProc.command = cmd;
            setProc.running = true;
        }

        // Notification
        const notifyMsg = profile.charAt(0).toUpperCase() + profile.slice(1) + " profile active";
        Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", root.powerIcon, "-t", "1500", "--", "Power", notifyMsg]);
    }

    /**
     * cycle
     * Cycles through the 3 available modes.
     */
    function cycle() {
        if (currentProfile === "daily") setProfile("balanced");
        else if (currentProfile === "balanced") setProfile("performance");
        else setProfile("daily");
    }

    /**
     * refresh
     * No longer polls system state to avoid conflicting feedback. 
     * We trust the internal shell state.
     */
    function refresh() {
        // Explicitly empty for state-based management.
    }
}