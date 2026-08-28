pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../core/functions" as Functions

/**
 * Service for interacting with na-ive wallpaper collection.
 */
Singleton {
    id: root

    property string wallpaperDir: Functions.FileUtils.trimFileProtocol(Directories.pictures) + "/wallpapers/downloads"
    readonly property string nandoroidIcon: Quickshell.shellPath("assets/icons/NAnDoroid.svg")
    readonly property alias results: naiveModel
    property bool loading: false
    property string errorMessage: ""
    
    readonly property string baseUrl: "https://raw.githubusercontent.com/na-ive/wallpapers/main/"
    readonly property string previewBaseUrl: "https://raw.githubusercontent.com/na-ive/wallpapers/gh-pages/"
    readonly property string jsonUrl: "https://raw.githubusercontent.com/na-ive/wallpapers/gh-pages/wallpapers.json"

    ListModel {
        id: naiveModel
    }

    signal fetchFinished()

    function fetch() {
        if (naiveModel.count > 0 && !root.errorMessage) return; // Cache results
        
        root.loading = true;
        root.errorMessage = "";
        naiveModel.clear();

        const xhr = new XMLHttpRequest();
        xhr.open("GET", root.jsonUrl);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.loading = false;
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        if (Array.isArray(response)) {
                            // Sort by mtime descending (newest first)
                            response.sort((a, b) => new Date(b.mtime) - new Date(a.mtime));
                            
                            const newItems = response.map(item => ({
                                "id": item.wallhaven_id || item.filename.split('.')[0],
                                "wallhaven_id": item.wallhaven_id || "",
                                "filename": item.filename,
                                "preview": root.previewBaseUrl + (item.preview || item.thumbnail),
                                "full": root.baseUrl + item.filename,
                                "color": item.color || "#000000",
                                "is_naive": true
                            }));
                            
                            for (let i = 0; i < newItems.length; i++) {
                                naiveModel.append(newItems[i]);
                            }
                        }
                    } catch (e) {
                        console.error("[Na-ive] Parse error:", e);
                        root.errorMessage = "Failed to parse wallpaper list";
                    }
                } else {
                    root.errorMessage = "Server error (" + xhr.status + ")";
                }
                root.fetchFinished();
            }
        };
        xhr.onerror = function() {
            root.loading = false;
            root.errorMessage = "Network error. Check connection.";
            root.fetchFinished();
        };
        xhr.send();
    }

    function download(url, filename, apply = false) {
        const fullPath = root.wallpaperDir + "/" + filename;

        Quickshell.execDetached(["mkdir", "-p", root.wallpaperDir]);

        // Check if file exists and is a valid image (not 0 bytes or HTML)
        const checkProc = createProcess.createObject(null, {
            command: ["sh", "-c", 'if [ -f "$1" ] && file "$1" | grep -iqE "image|bitmap"; then exit 0; else rm -f "$1"; exit 1; fi', "sh", fullPath]
        });
        
        checkProc.exited.connect((exitCode) => {
            if (exitCode === 0) {
                if (apply) {
                    if (GlobalStates.wallpaperSelectorTarget === "desktop") {
                        Wallpapers.select("file://" + fullPath);
                    } else {
                        Wallpapers.selectForLockscreen("file://" + fullPath);
                    }
                    root.sendNotification("Na-ive Wallpapers", "Already exists. Applied!");
                } else {
                    root.sendNotification("Na-ive Wallpapers", "Already downloaded: " + filename);
                }
                checkProc.destroy();
            } else {
                checkProc.destroy();
                if (apply) {
                    const p = createProcess.createObject(null, {
                        command: ["sh", "-c", 'curl -s -L "$1" -o "$2" && file "$2" | grep -iqE "image|bitmap"', "sh", url, fullPath]
                    });
                    p.exited.connect((exitCode) => {
                        if (exitCode === 0) {
                            if (GlobalStates.wallpaperSelectorTarget === "desktop") {
                                Wallpapers.select("file://" + fullPath);
                            } else {
                                Wallpapers.selectForLockscreen("file://" + fullPath);
                            }
                            root.sendNotification("Na-ive Wallpapers", "Wallpaper applied successfully!");
                        } else {
                            Quickshell.execDetached(["rm", "-f", fullPath]);
                            root.sendNotification("Na-ive Wallpapers", "Download failed.");
                        }
                        p.destroy();
                    });
                    p.running = true;
                } else {
                    Quickshell.execDetached([
                        "sh", "-c", 
                        'curl -s -L "$1" -o "$2" && file "$2" | grep -iqE "image|bitmap" && notify-send -a "NAnDoroid" -i "$3" -- "Na-ive Wallpapers" "Downloaded: $4" || (rm -f "$2" && notify-send -a "NAnDoroid" -i "$3" -- "Na-ive Wallpapers" "Download failed.")',
                        "sh", url, fullPath, root.nandoroidIcon, filename
                    ]);
                }
            }
        });
        checkProc.running = true;
    }

    function sendNotification(title, body) {
        Quickshell.execDetached([
            "notify-send", 
            "-a", "NAnDoroid", 
            "-i", root.nandoroidIcon, 
            "--", title, body
        ]);
    }

    Component {
        id: createProcess
        Process {}
    }
}
