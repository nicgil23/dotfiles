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
                        for (let i = 0; i < root.pendingOutPathsToAdd.length; i++) {
                            Quickshell.execDetached(["kdeconnect-cli", "--device", dev, "--share", root.pendingOutPathsToAdd[i]])
                        }
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

    function sendToKdeConnect(files, deviceId) {
        if (!files) return
        let fileList = Array.isArray(files) ? files : [files]
        if (fileList.length === 0) return

        let dev = deviceId || defaultKdeDevice

        let pyScript = `import sys, os, subprocess, json, time

dev = sys.argv[1]
files = json.loads(sys.argv[2])
count = len(files)
label = "1 archivo" if count == 1 else f"{count} archivos"

if not dev:
    cmd = 'notify-send -a "KDE Connect" -u critical "KDE Connect" "Error: no hay ningún móvil conectado"'
    subprocess.run(cmd, shell=True)
    sys.exit(1)

args = ["kdeconnect-cli", "--device", dev]
for f in files:
    if f.startswith("file://"): f = f[7:]
    args.extend(["--share", f])

res = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
err = (res.returncode != 0)

if err and count > 1:
    err = False
    for f in files:
        if f.startswith("file://"): f = f[7:]
        r = subprocess.run(["kdeconnect-cli", "--device", dev, "--share", f], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if r.returncode != 0: err = True
        time.sleep(0.5)

if err:
    cmd = f'notify-send -a "KDE Connect" -u critical "KDE Connect" "Ha habido un error al enviar {label} al móvil"'
    subprocess.run(cmd, shell=True)
`
        let cmd = ["python3", "-c", pyScript, dev || "", JSON.stringify(fileList)]
        Quickshell.execDetached(cmd)
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
