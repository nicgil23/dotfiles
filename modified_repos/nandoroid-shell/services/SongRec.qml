pragma Singleton
pragma ComponentBehavior: Bound

import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    enum MonitorSource { Monitor, Input }

    property var monitorSource: SongRec.MonitorSource.Monitor
    property int timeoutInterval: (Config.ready && Config.options.musicRecognition) ? Config.options.musicRecognition.interval : 2
    property int timeoutDuration: (Config.ready && Config.options.musicRecognition) ? Config.options.musicRecognition.timeout : 30
    readonly property bool running: recognizeMusicProc.running

    function toggleRunning(runningState) {
        if (recognizeMusicProc.running && runningState === false) root.manuallyStopped = true;
        if (runningState !== undefined) {
            recognizeMusicProc.running = runningState
        } else {
            recognizeMusicProc.running = !recognizeMusicProc.running
        }
        musicRecognizedProc.running = false
    }

    function toggleMonitorSource(source) {
        if (source !== undefined) {
            root.monitorSource = source
            return
        }
        root.monitorSource = (root.monitorSource === SongRec.MonitorSource.Monitor) ? SongRec.MonitorSource.Input : SongRec.MonitorSource.Monitor
    }

    function monitorSourceToString(src) {
        return src === SongRec.MonitorSource.Monitor ? "monitor" : "input"
    }

    readonly property string monitorSourceString: monitorSourceToString(monitorSource)
    readonly property string nandoroidIcon: Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/assets/icons/NAnDoroid.svg"
    property var recognizedTrack: ({ title:"", subtitle:"", url:""})
    property bool manuallyStopped: false

    function handleRecognition(jsonText) {
        if (!jsonText || jsonText.trim() === "") {
            Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", root.nandoroidIcon, "--", "No music detected", "The recognizer finished without finding any matches."])
            return;
        }

        try {
            // songrec might output multiple JSON objects separated by newlines
            var lines = jsonText.split("\n");
            var found = false;

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line === "") continue;

                var obj = JSON.parse(line);
                if (obj.track) {
                    root.recognizedTrack = {
                        title: obj.track.title,
                        subtitle: obj.track.subtitle,
                        url: obj.track.url
                    }
                    musicRecognizedProc.running = true
                    found = true;
                    break;
                }
            }

            if (!found) {
                Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", root.nandoroidIcon, "--", "Music not recognized", "Shazam couldn't find a match for this audio."])
            }
        } catch(e) {
            console.error("Error parsing music recognition JSON: " + e);
            Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", root.nandoroidIcon, "--", "Recognition Error", "Failed to parse recognition results."])
        }
    }

    Process {
        id: recognizeMusicProc
        running: false
        command: ["bash", Quickshell.shellPath("scripts/musicRecognition/recognize-music.sh"), "-i", root.timeoutInterval, "-t", root.timeoutDuration, "-s", root.monitorSourceString]
        
        onRunningChanged: {
            if (running) {
                Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", root.nandoroidIcon, "-t", "2000", "--", "Music Recognition", "Listening for music..."])
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.manuallyStopped) {
                    root.manuallyStopped = false
                    return
                }
                if (this.text.trim() !== "") {
                    handleRecognition(this.text)
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 1) {
                Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", root.nandoroidIcon, "--", "Couldn't recognize music", "Make sure you have songrec installed and script permissions are correct"])
            }
        }
    }

    Process {
        id: musicRecognizedProc
        running: false
        command: [
            "notify-send",
            "-A", "Shazam",
            "-A", "YouTube",
            "-a", "NAnDoroid",
            "-i", root.nandoroidIcon,
            "-t", "10000",
            "-e", // Transient
            "--",
            "Music Recognized", 
            root.recognizedTrack.title + " - " + root.recognizedTrack.subtitle
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text === "") return
                if (this.text.trim() == "0") {
                    Qt.openUrlExternally(root.recognizedTrack.url);
                } else {
                    Qt.openUrlExternally("https://www.youtube.com/results?search_query=" + encodeURIComponent(root.recognizedTrack.title + " - " + root.recognizedTrack.subtitle));
                }
            }
        }
    }
}
