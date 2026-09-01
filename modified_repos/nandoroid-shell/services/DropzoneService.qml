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
    signal kdeConnectSent(int count, bool isError)

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

        let pyScript = `import sys, os, subprocess, json, time

dev = sys.argv[1]
files = json.loads(sys.argv[2])
count = len(files)

if not dev:
    print(json.dumps({"success": False, "sent": 0, "total": count, "error": "no_device"}))
    sys.exit(0)

err_count = 0
for f in files:
    if f.startswith("file://"): f = f[7:]
    r = subprocess.run(["kdeconnect-cli", "--device", dev, "--share", f], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if r.returncode != 0:
        err_count += 1
    time.sleep(0.2)

label = "1 archivo" if count == 1 else f"{count} archivos"

if err_count == count:
    print(json.dumps({"success": False, "sent": 0, "total": count, "error": "all_failed"}))
elif err_count > 0:
    print(json.dumps({"success": False, "sent": count - err_count, "total": count, "error": "partial_failed"}))
else:
    print(json.dumps({"success": True, "sent": count, "total": count}))
    cmd = f'notify-send -i kdeconnect -a "KDE Connect" -u normal "KDE Connect" "Enviados {label} al móvil correctamente"'
    subprocess.run(cmd, shell=True)
`
        kdeSendProc.command = ["python3", "-c", pyScript, dev || "", JSON.stringify(fileList)]
        kdeSendProc.running = true
    }

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
        let newItems = []

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

            let isImg = ["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg", "ico"].includes(ext)
            let isVid = ["mp4", "mkv", "webm", "avi", "mov", "flv"].includes(ext)
            let isAud = ["mp3", "flac", "wav", "ogg", "m4a", "aac", "opus"].includes(ext)
            let isArch = ["zip", "tar", "gz", "tgz", "7z", "rar", "xz", "bz2"].includes(ext)
            let initialIsDir = p.endsWith("/") || ext === ""

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
            newItems.push(itemObj)
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

    function openFile(path, isDir) {
        if (!path) return
        let itemFound = root.stashedFiles.find(f => f.path === path)
        let checkIsDir = (isDir !== undefined) ? isDir : (itemFound ? itemFound.isDir : false)
        if (checkIsDir) {
            let cmd = `kitty -e yazi "${path}"`
            Quickshell.execDetached(["bash", "-c", cmd])
        } else {
            Quickshell.execDetached(["xdg-open", path])
        }
    }

    function copyPath(path) {
        if (!path) return
        let name = getFileName(path)
        let cmd = `printf '%s' "${path}" | wl-copy && notify-send -a "Dropzone" "Ruta copiada" "${name}"`
        Quickshell.execDetached(["bash", "-c", cmd])
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

        let pyScript = `import sys, subprocess; subprocess.run(sys.argv[1], shell=True)`
        transformProc.command = ["python3", "-c", pyScript, cmd]
        transformProc.running = true
    }

    // --- Action Handlers ---

    function convertImage(filePath, targetFormat, destOption, targetDevice) {
        let dir = getFileDir(filePath)
        let nameWithoutExt = getFileName(filePath).replace(/\.[^/.]+$/, "")
        let outPath = dir + "/" + nameWithoutExt + "_converted." + targetFormat.toLowerCase()

        let cmd = `magick "${filePath}" "${outPath}"`
        Quickshell.execDetached(["bash", "-c", cmd])

        if (destOption === "kdeconnect") {
            let dev = targetDevice || defaultKdeDevice
            let sendCmd = `sleep 1`
            runTransformationCmd(`magick "${filePath}" "${outPath}"`, null, [outPath], "kdeconnect", dev)
        }
        return outPath
    }

    function convertVideo(filePath, targetFormat, destOption, targetDevice) {
        let dir = getFileDir(filePath)
        let nameWithoutExt = getFileName(filePath).replace(/\.[^/.]+$/, "")
        let outPath = dir + "/" + nameWithoutExt + "_converted." + targetFormat.toLowerCase()

        let cmd = `ffmpeg -y -i "${filePath}" "${outPath}"`
        Quickshell.execDetached(["bash", "-c", cmd])

        if (destOption === "kdeconnect") {
            let dev = targetDevice || defaultKdeDevice
            runTransformationCmd(`ffmpeg -y -i "${filePath}" "${outPath}"`, null, [outPath], "kdeconnect", dev)
        }
        return outPath
    }

    function cleanExif(filePath, destOption, targetDevice) {
        let dir = getFileDir(filePath)
        let ext = getFileExt(getFileName(filePath))
        let nameWithoutExt = getFileName(filePath).replace(/\.[^/.]+$/, "")
        let outPath = dir + "/" + nameWithoutExt + "_clean." + ext

        let cmd = `magick "${filePath}" -strip "${outPath}"`
        Quickshell.execDetached(["bash", "-c", cmd])

        if (destOption === "kdeconnect") {
            let dev = targetDevice || defaultKdeDevice
            runTransformationCmd(`magick "${filePath}" -strip "${outPath}"`, null, [outPath], "kdeconnect", dev)
        }
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

        Quickshell.execDetached(["bash", "-c", cmd])

        if (destOption === "kdeconnect") {
            let dev = targetDevice || defaultKdeDevice
            runTransformationCmd(cmd, null, [outPath], "kdeconnect", dev)
        }
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

        Quickshell.execDetached(["bash", "-c", cmd])

        if (destOption === "kdeconnect") {
            let dev = targetDevice || defaultKdeDevice
            runTransformationCmd(cmd, null, [outDir], "kdeconnect", dev)
        }
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
