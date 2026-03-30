pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Service providing basic MPD support using 'mpc'.
 * Mimics a subset of the MprisPlayer interface.
 */
Singleton {
    id: root

    property bool isMpdAvailable: false
    property bool isPlaying: false
    property string trackTitle: ""
    property string trackArtist: ""
    property string trackAlbum: ""
    property string trackArtUrl: ""
    property string identity: "MPD"
    property string desktopEntry: "mpd"
    
    property bool canTogglePlaying: isMpdAvailable
    property bool canGoPrevious: isMpdAvailable
    property bool canGoNext: isMpdAvailable
    property bool canSeek: isMpdAvailable
    property bool canControl: isMpdAvailable
    
    property real position: 0 // in seconds
    property real length: 0 // in seconds

    // Mimic MprisPlayer methods
    function togglePlaying() { Quickshell.execDetached(["mpc", "toggle"]); update(); }
    function previous() { Quickshell.execDetached(["mpc", "prev"]); update(); }
    function next() { Quickshell.execDetached(["mpc", "next"]); update(); }
    function stop() { Quickshell.execDetached(["mpc", "stop"]); update(); }
    function setPosition(pos) {
        if (!isMpdAvailable || length <= 0) return;
        const pct = Math.min(100, Math.max(0, (pos / length) * 100));
        Quickshell.execDetached(["mpc", "seek", pct.toFixed(2) + "%"]);
        root.position = pos;
        update();
    }
    function seek(offset) {
        if (!isMpdAvailable) return;
        const sign = offset >= 0 ? "+" : "";
        Quickshell.execDetached(["mpc", "seek", sign + Math.floor(offset).toString()]);
        update();
    }
    
    // For MprisController compatibility
    function requestPositionUpdate() { root.update(); }

    signal postTrackChanged()

    Process {
        id: mpcStatusProc
        command: ["mpc", "status", "--format", "%title%\\n%artist%\\n%album%\\n%file%"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "" || this.text.includes("MPD_HOST") || this.text.includes("Connection refused")) {
                    root.isMpdAvailable = false;
                    return;
                }
                
                const lines = this.text.split("\n");
                if (lines.length >= 4) {
                    root.isMpdAvailable = true;
                    const oldTitle = root.trackTitle;
                    root.trackTitle = lines[0].trim() || lines[3].split("/").pop() || "Unknown Title";
                    root.trackArtist = lines[1].trim() || "Unknown Artist";
                    root.trackAlbum = lines[2].trim() || "Unknown Album";
                    
                    if (oldTitle !== root.trackTitle) {
                        root.postTrackChanged();
                        root.updateArt();
                    }
                }
                
                // Parse status line (usually the second or third line)
                // [playing] #1/10  0:01/3:45 (0%)
                const statusLine = lines.find(l => l.includes("[playing]") || l.includes("[paused]"));
                if (statusLine) {
                    root.isPlaying = statusLine.includes("[playing]");
                    const timeMatch = statusLine.match(/(\d+:\d+(:?\d+)?)\/(\d+:\d+(:?\d+)?)/);
                    if (timeMatch) {
                        root.position = parseTime(timeMatch[1]);
                        root.length = parseTime(timeMatch[3]);
                    }
                } else {
                    root.isPlaying = false;
                }
            }
        }
    }

    function parseTime(timeStr) {
        if (!timeStr) return 0;
        const parts = timeStr.split(":").map(Number);
        if (parts.length === 2) return parts[0] * 60 + parts[1];
        if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
        return 0;
    }

    readonly property string _artFilePath: "/tmp/nandoroid_mpd_cover.jpg"
    function updateArt() {
        if (mpcArtProc.running) return;
        mpcArtProc.running = true;
    }

    Process {
        id: mpcArtProc
        // Extract album art to a temporary file, using a temporary path first to ensure success
        command: ["bash", "-c", `rm -f "${root._artFilePath}"; mpc readpicture "$(mpc current -f %file%)" > "${root._artFilePath}" && [ -s "${root._artFilePath}" ]`]
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.trackArtUrl = ""; // Flush trigger
                root.trackArtUrl = "file://" + root._artFilePath;
            } else {
                root.trackArtUrl = "";
                Quickshell.execDetached(["rm", "-f", root._artFilePath]);
            }
        }
    }

    function update() {
        if (!mpcStatusProc.running) {
            mpcStatusProc.running = true;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.update()
    }

    Component.onCompleted: update()
}
