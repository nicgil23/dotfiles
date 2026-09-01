pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * Service managing files dropped or stashed into the Dynamic Island (Dropzone).
 * Handles file metadata, format detection, KDE Connect sharing, and conversion tasks.
 */
Singleton {
    id: root

    property var stashedFiles: []
    readonly property bool hasFiles: stashedFiles.length > 0
    readonly property int folderCount: stashedFiles.filter(f => f.isDir).length
    readonly property int fileCount: stashedFiles.filter(f => !f.isDir).length

    property var kdeConnectDevices: []
    readonly property string defaultKdeDevice: kdeConnectDevices.length > 0 ? kdeConnectDevices[0] : ""

    signal filesUpdated()
    signal kdeConnectSent(int count, bool isError)

    // Recognized file extensions by category
    readonly property var imgExts: ["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg", "ico", "tiff", "avif"]
    readonly property var vidExts: ["mp4", "mkv", "webm", "avi", "mov", "flv", "wmv", "m4v"]
    readonly property var audExts: ["mp3", "flac", "wav", "ogg", "m4a", "aac", "opus", "wma"]
    readonly property var archExts: ["zip", "tar", "gz", "tgz", "7z", "rar", "xz", "bz2"]

    // ── Path Helper Utilities ──

    function getFileName(path) {
        if (!path) return ""
        let clean = String(path).replace(/\/+$/, "")
        let idx = clean.lastIndexOf("/")
        return idx !== -1 ? clean.substring(idx + 1) : clean
    }

    function getFileDir(path) {
        if (!path) return ""
        let clean = String(path).replace(/\/+$/, "")
        let idx = clean.lastIndexOf("/")
        return idx !== -1 ? clean.substring(0, idx) : ""
    }

    function getFileExt(name) {
        if (!name) return ""
        let cleanName = getFileName(name)
        let idx = cleanName.lastIndexOf(".")
        return (idx > 0 && idx < cleanName.length - 1) ? cleanName.substring(idx + 1).toLowerCase() : ""
    }

    // ── Stash Management ──

    function addFiles(paths) {
        if (!paths) return
        if (typeof paths === "string") paths = [paths]
        
        let current = Array.from(root.stashedFiles)
        let pathsToCheck = []

        for (let i = 0; i < paths.length; i++) {
            let p = String(paths[i]).trim()
            if (!p) continue
            if (p.startsWith("file://")) {
                p = p.substring(7)
                try { p = decodeURIComponent(p) } catch(e) {}
            } else if (p.includes("%")) {
                try { p = decodeURIComponent(p) } catch(e) {}
            }

            // Avoid duplicate paths
            if (current.some(f => f.path === p)) continue

            let name = getFileName(p)
            let dir = getFileDir(p)
            let ext = getFileExt(name)

            let isImg = imgExts.includes(ext)
            let isVid = vidExts.includes(ext)
            let isAud = audExts.includes(ext)
            let isArch = archExts.includes(ext)
            let initialIsDir = p.endsWith("/") || (ext === "" && !isImg && !isVid && !isAud && !isArch)

            let itemObj = {
                path: p,
                name: name,
                dir: dir,
                ext: ext,
                isDir: initialIsDir,
                isImage: isImg,
                isVideo: isVid,
                isAudio: isAud,
                isArchive: isArch
            }

            current.push(itemObj)
            pathsToCheck.push(p)
        }

        root.stashedFiles = current
        root.filesUpdated()
        GlobalStates.dropzoneNotchOpen = true

        if (pathsToCheck.length > 0) {
            checkDirsProcess.command = ["python3", "-c", "import sys, os, json; print(json.dumps({p: os.path.isdir(p) for p in sys.argv[1:]}))"].concat(pathsToCheck)
            checkDirsProcess.running = true
        }
    }

    function removeFile(index) {
        if (index >= 0 && index < stashedFiles.length) {
            let current = Array.from(root.stashedFiles)
            current.splice(index, 1)
            root.stashedFiles = current
            root.filesUpdated()
            if (current.length === 0) {
                GlobalStates.dropzoneNotchOpen = false
            }
        }
    }

    function clearAll() {
        root.stashedFiles = []
        root.filesUpdated()
        GlobalStates.dropzoneNotchOpen = false
    }

    function replaceStashedItems(pathsToRemove, outPathsToAdd) {
        if (!pathsToRemove || pathsToRemove.length === 0) return
        let current = Array.from(root.stashedFiles).filter(f => !pathsToRemove.includes(f.path))
        root.stashedFiles = current
        root.filesUpdated()
        if (outPathsToAdd && outPathsToAdd.length > 0) {
            addFiles(outPathsToAdd)
        }
    }

    // ── External Actions ──

    function openFile(path, isDir) {
        if (!path) return
        let itemFound = root.stashedFiles.find(f => f.path === path)
        let checkIsDir = (isDir !== undefined) ? isDir : (itemFound ? itemFound.isDir : false)
        if (checkIsDir) {
            Quickshell.execDetached(["bash", "-c", 'kitty -e yazi "$1"', "_", path])
        } else {
            Quickshell.execDetached(["xdg-open", path])
        }
    }

    function copyPath(path) {
        if (!path) return
        let name = getFileName(path)
        Quickshell.execDetached(["bash", "-c", 'printf "%s" "$1" | wl-copy && notify-send -a "Dropzone" "Ruta copiada" "$2"', "_", path, name])
    }

    function grabFile(path) {
        if (!path) return
        Quickshell.execDetached(["ripdrag", "-a", "-x", path])
    }

    function grabAllFiles() {
        if (stashedFiles.length === 0) return
        let paths = stashedFiles.map(f => f.path)
        Quickshell.execDetached(["ripdrag", "-a", "-x"].concat(paths))
    }

    // ── Processes ──

    Process {
        id: checkDirsProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                try {
                    let map = JSON.parse(text)
                    let updated = false
                    let current = Array.from(root.stashedFiles)
                    for (let i = 0; i < current.length; i++) {
                        let item = current[i]
                        if (map[item.path] !== undefined && item.isDir !== map[item.path]) {
                            item.isDir = map[item.path]
                            updated = true
                        }
                    }
                    if (updated) {
                        root.stashedFiles = current
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: kdeSendProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                try {
                    let res = JSON.parse(text.trim())
                    let isError = !res.success
                    let count = isError ? res.total : res.sent
                    root.kdeConnectSent(count, isError)
                } catch(e) {
                    root.kdeConnectSent(0, true)
                }
            }
        }
    }

    function sendToKdeConnect(files, deviceId) {
        if (!files) return
        let fileList = Array.isArray(files) ? files : [files]
        if (fileList.length === 0) return

        root.clearAll()

        let dev = deviceId || defaultKdeDevice
        let scriptPath = Quickshell.shellPath("scripts/kde_share.py")

        kdeSendProc.command = ["python3", scriptPath, dev || "", JSON.stringify(fileList)]
        kdeSendProc.running = true
    }

    property var pendingPathsToRemove: []
    property var pendingOutPathsToAdd: []
    property string pendingDestOption: ""
    property string pendingTargetDevice: ""

    Process {
        id: transformProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.pendingDestOption === "kdeconnect") {
                    let dev = root.pendingTargetDevice || root.defaultKdeDevice
                    if (dev && root.pendingOutPathsToAdd && root.pendingOutPathsToAdd.length > 0) {
                        root.sendToKdeConnect(root.pendingOutPathsToAdd, dev)
                    }
                } else {
                    if (root.pendingPathsToRemove && root.pendingPathsToRemove.length > 0) {
                        root.replaceStashedItems(root.pendingPathsToRemove, root.pendingOutPathsToAdd)
                    }
                }
                root.pendingPathsToRemove = []
                root.pendingOutPathsToAdd = []
                root.pendingDestOption = ""
                root.pendingTargetDevice = ""
            }
        }
    }

    function runTransformationCmd(cmd, pathsToRemove, outPathsToAdd, destOption, targetDevice) {
        if (!cmd) return
        root.pendingPathsToRemove = pathsToRemove || []
        root.pendingOutPathsToAdd = outPathsToAdd || []
        root.pendingDestOption = destOption || ""
        root.pendingTargetDevice = targetDevice || ""

        transformProc.command = ["bash", "-c", cmd]
        transformProc.running = true
    }

    // ── Transformation Handlers ──

    function convertImage(filePath, targetFormat, destOption, targetDevice) {
        let dir = getFileDir(filePath)
        let nameWithoutExt = getFileName(filePath).replace(/\.[^/.]+$/, "")
        let outPath = dir + "/" + nameWithoutExt + "_converted." + targetFormat.toLowerCase()
        let cmd = `magick "${filePath}" "${outPath}"`
        runTransformationCmd(cmd, [filePath], [outPath], destOption, targetDevice)
        return outPath
    }

    function convertVideo(filePath, targetFormat, destOption, targetDevice) {
        let dir = getFileDir(filePath)
        let nameWithoutExt = getFileName(filePath).replace(/\.[^/.]+$/, "")
        let outPath = dir + "/" + nameWithoutExt + "_converted." + targetFormat.toLowerCase()
        let cmd = `ffmpeg -y -i "${filePath}" "${outPath}"`
        runTransformationCmd(cmd, [filePath], [outPath], destOption, targetDevice)
        return outPath
    }

    function cleanExif(filePath, destOption, targetDevice) {
        let dir = getFileDir(filePath)
        let ext = getFileExt(filePath)
        let nameWithoutExt = getFileName(filePath).replace(/\.[^/.]+$/, "")
        let outPath = dir + "/" + nameWithoutExt + "_clean." + ext
        let cmd = `magick "${filePath}" -strip "${outPath}"`
        runTransformationCmd(cmd, [filePath], [outPath], destOption, targetDevice)
        return outPath
    }

    function compressArchive(filePaths, archiveType, destOption, targetDevice) {
        if (!filePaths || filePaths.length === 0) return ""
        let firstDir = getFileDir(filePaths[0])
        let ext = archiveType === "tar.gz" ? "tar.gz" : "zip"
        let outPath = firstDir + "/isla_archive." + ext
        let pathsStr = filePaths.map(p => `"${p}"`).join(" ")
        let cmd = archiveType === "tar.gz"
            ? `tar -czvf "${outPath}" ${pathsStr}`
            : `zip -j "${outPath}" ${pathsStr}`
        runTransformationCmd(cmd, filePaths, [outPath], destOption, targetDevice)
        return outPath
    }

    function decompressArchive(archivePath, destOption, targetDevice) {
        let dir = getFileDir(archivePath)
        let nameWithoutExt = getFileName(archivePath).replace(/\.[^/.]+$/, "").replace(/\.tar$/, "")
        let outDir = dir + "/" + nameWithoutExt + "_extracted"
        let ext = getFileExt(archivePath)
        let cmd = (ext === "zip")
            ? `mkdir -p "${outDir}" && unzip -o "${archivePath}" -d "${outDir}"`
            : `mkdir -p "${outDir}" && tar -xzvf "${archivePath}" -C "${outDir}"`
        runTransformationCmd(cmd, [archivePath], [outDir], destOption, targetDevice)
        return outDir
    }

    function refreshKdeDevices() {
        kdeDevicesProcess.running = true
    }

    Process {
        id: kdeDevicesProcess
        command: ["kdeconnect-cli", "-a", "--id-only"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n").filter(l => l.length > 0)
                root.kdeConnectDevices = lines
            }
        }
    }
}
