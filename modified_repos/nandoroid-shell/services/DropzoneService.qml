pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * Service managing files dropped or stashed into the Dynamic Island (Dropzone).
 * Handles file metadata, formats, KDE Connect sharing, and conversion tasks.
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
                        root.filesUpdated()
                    }
                } catch(e) {}
            }
        }
    }

    function getFileName(path) {
        if (!path) return ""
        let parts = path.split("/")
        return parts[parts.length - 1]
    }

    function getFileDir(path) {
        if (!path) return ""
        let idx = path.lastIndexOf("/")
        return idx !== -1 ? path.substring(0, idx) : ""
    }

    function getFileExt(name) {
        if (!name) return ""
        let idx = name.lastIndexOf(".")
        return idx !== -1 ? name.substring(idx + 1).toLowerCase() : ""
    }

    function addFiles(paths) {
        if (!paths) return
        if (typeof paths === "string") paths = [paths]
        
        let current = Array.from(root.stashedFiles)
        let pathsToCheck = []

        for (let i = 0; i < paths.length; i++) {
            let p = String(paths[i]).trim()
            if (!p) continue
            if (p.startsWith("file://")) p = p.substring(7)
            
            // Avoid duplicate paths
            if (current.some(f => f.path === p)) continue

            let name = getFileName(p)
            let dir = getFileDir(p)
            let ext = getFileExt(name)

            let isImg = ["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg", "ico"].includes(ext)
            let isVid = ["mp4", "mkv", "webm", "avi", "mov", "flv"].includes(ext)
            let isAud = ["mp3", "flac", "wav", "ogg", "m4a", "aac", "opus"].includes(ext)
            let isArch = ["zip", "tar", "gz", "tgz", "7z", "rar", "xz", "bz2"].includes(ext)
            let initialIsDir = p.endsWith("/") || ext === ""

            current.push({
                path: p,
                name: name,
                dir: dir,
                ext: ext,
                isDir: initialIsDir,
                isImage: isImg,
                isVideo: isVid,
                isAudio: isAud,
                isArchive: isArch
            })

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

    function grabFile(path) {
        if (!path) return
        Quickshell.execDetached(["ripdrag", "-a", "-x", path])
    }

    function grabAllFiles() {
        if (stashedFiles.length === 0) return
        let paths = stashedFiles.map(f => f.path)
        Quickshell.execDetached(["ripdrag", "-a", "-x"].concat(paths))
    }

    // --- Action Handlers ---

    function convertImage(filePath, targetFormat, destOption, targetDevice) {
        let dir = getFileDir(filePath)
        let nameWithoutExt = getFileName(filePath).replace(/\.[^/.]+$/, "")
        let outPath = dir + "/" + nameWithoutExt + "_converted." + targetFormat.toLowerCase()

        let cmd = `convert "${filePath}" "${outPath}"`
        Quickshell.execDetached(["bash", "-c", cmd])

        let dev = targetDevice || defaultKdeDevice
        if (destOption === "kdeconnect" && dev) {
            let sendCmd = `sleep 1 && kdeconnect-cli --device "${dev}" --share "${outPath}"`
            Quickshell.execDetached(["bash", "-c", sendCmd])
        } else {
            let addCmd = `sleep 1 && quickshell -p /home/hypr/dotfiles/modified_repos/nandoroid-shell ipc call dropzone add "${outPath}"`
            Quickshell.execDetached(["bash", "-c", addCmd])
        }
    }

    function convertVideo(filePath, targetFormat, destOption, targetDevice) {
        let dir = getFileDir(filePath)
        let nameWithoutExt = getFileName(filePath).replace(/\.[^/.]+$/, "")
        let outPath = dir + "/" + nameWithoutExt + "_converted." + targetFormat.toLowerCase()

        let cmd = `ffmpeg -y -i "${filePath}" "${outPath}"`
        Quickshell.execDetached(["bash", "-c", cmd])

        let dev = targetDevice || defaultKdeDevice
        if (destOption === "kdeconnect" && dev) {
            let sendCmd = `sleep 2 && kdeconnect-cli --device "${dev}" --share "${outPath}"`
            Quickshell.execDetached(["bash", "-c", sendCmd])
        } else {
            let addCmd = `sleep 2 && quickshell -p /home/hypr/dotfiles/modified_repos/nandoroid-shell ipc call dropzone add "${outPath}"`
            Quickshell.execDetached(["bash", "-c", addCmd])
        }
    }

    function cleanExif(filePath, destOption, targetDevice) {
        let dir = getFileDir(filePath)
        let ext = getFileExt(getFileName(filePath))
        let nameWithoutExt = getFileName(filePath).replace(/\.[^/.]+$/, "")
        let outPath = dir + "/" + nameWithoutExt + "_clean." + ext

        let cmd = `convert "${filePath}" -strip "${outPath}"`
        Quickshell.execDetached(["bash", "-c", cmd])

        let dev = targetDevice || defaultKdeDevice
        if (destOption === "kdeconnect" && dev) {
            let sendCmd = `sleep 1 && kdeconnect-cli --device "${dev}" --share "${outPath}"`
            Quickshell.execDetached(["bash", "-c", sendCmd])
        } else {
            let addCmd = `sleep 1 && quickshell -p /home/hypr/dotfiles/modified_repos/nandoroid-shell ipc call dropzone add "${outPath}"`
            Quickshell.execDetached(["bash", "-c", addCmd])
        }
    }

    function compressArchive(filePaths, archiveType, destOption, targetDevice) {
        if (!filePaths || filePaths.length === 0) return
        let firstDir = getFileDir(filePaths[0])
        let ext = archiveType === "tar.gz" ? "tar.gz" : "zip"
        let outPath = firstDir + "/isla_archive." + ext

        let pathsStr = filePaths.map(p => `"${p}"`).join(" ")
        let cmd = archiveType === "tar.gz"
            ? `tar -czvf "${outPath}" ${pathsStr}`
            : `zip -j "${outPath}" ${pathsStr}`

        Quickshell.execDetached(["bash", "-c", cmd])

        let dev = targetDevice || defaultKdeDevice
        if (destOption === "kdeconnect" && dev) {
            let sendCmd = `sleep 1.5 && kdeconnect-cli --device "${dev}" --share "${outPath}"`
            Quickshell.execDetached(["bash", "-c", sendCmd])
        } else {
            let addCmd = `sleep 1.5 && quickshell -p /home/hypr/dotfiles/modified_repos/nandoroid-shell ipc call dropzone add "${outPath}"`
            Quickshell.execDetached(["bash", "-c", addCmd])
        }
    }

    function decompressArchive(archivePath, destOption, targetDevice) {
        let dir = getFileDir(archivePath)
        let nameWithoutExt = getFileName(archivePath).replace(/\.[^/.]+$/, "").replace(/\.tar$/, "")
        let outDir = dir + "/" + nameWithoutExt + "_extracted"

        let ext = getFileExt(archivePath)
        let cmd = (ext === "zip")
            ? `mkdir -p "${outDir}" && unzip -o "${archivePath}" -d "${outDir}"`
            : `mkdir -p "${outDir}" && tar -xzvf "${archivePath}" -C "${outDir}"`

        Quickshell.execDetached(["bash", "-c", cmd])

        let dev = targetDevice || defaultKdeDevice
        if (destOption === "kdeconnect" && dev) {
            let sendCmd = `sleep 2 && kdeconnect-cli --device "${dev}" --share "${outDir}"`
            Quickshell.execDetached(["bash", "-c", sendCmd])
        } else {
            let addCmd = `sleep 2 && quickshell -p /home/hypr/dotfiles/modified_repos/nandoroid-shell ipc call dropzone add "${outDir}"`
            Quickshell.execDetached(["bash", "-c", addCmd])
        }
    }

    function sendToKdeConnect(filePath, deviceId) {
        if (!filePath) return
        let dev = deviceId || defaultKdeDevice
        if (!dev) return
        Quickshell.execDetached(["kdeconnect-cli", "--device", dev, "--share", filePath])
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
