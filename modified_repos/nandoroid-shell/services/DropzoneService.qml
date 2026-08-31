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

    property string grabAllThumbPath: ""

    Process {
        id: makeThumbsProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                try {
                    let map = JSON.parse(text)
                    if (map["__grabAll"]) {
                        root.grabAllThumbPath = map["__grabAll"]
                    }
                    let current = Array.from(root.stashedFiles)
                    for (let i = 0; i < current.length; i++) {
                        let p = current[i].path
                        if (map[p]) {
                            current[i].thumbPath = map[p]
                        }
                    }
                    root.stashedFiles = current
                    root.filesUpdated()
                } catch(e) {}
            }
        }
    }

    function generateThumbnails(files) {
        if (!files || files.length === 0) return
        let pyScript = `import sys, os, glob, hashlib, json, subprocess, random
from PIL import Image

data = json.loads(sys.argv[1])
out_dir = "/tmp/dz_thumbs"
os.makedirs(out_dir, exist_ok=True)
res = {}

search_dirs = [
    os.path.expanduser("~/.local/share/icons"),
    os.path.expanduser("~/.icons"),
    "/usr/share/icons"
]

def find_system_icon(icon_names):
    for name in icon_names:
        for sdir in search_dirs:
            if not os.path.exists(sdir): continue
            matches = glob.glob(f"{sdir}/**/{name}.svg", recursive=True) or glob.glob(f"{sdir}/**/{name}.png", recursive=True)
            if matches:
                return matches[0]
    return ""

def resolve_src(item):
    if item.get("isImage"):
        return item.get("path", "")
    if item.get("isDir"):
        return find_system_icon(["folder", "inode-directory", "folder-blue"])
    if item.get("isVideo"):
        return find_system_icon(["video-x-generic", "video"])
    if item.get("isAudio"):
        return find_system_icon(["audio-x-generic", "audio"])
    if item.get("isArchive"):
        return find_system_icon(["package-x-generic", "folder-zip", "application-zip"])
    return find_system_icon(["text-x-generic", "document", "text-plain"])

for item in data:
    try:
        path = item.get("path", "")
        if not path: continue
        src = resolve_src(item)
        if not src: continue
        if src.startswith("file://"):
            src = src[7:]
        h = hashlib.md5((path + ("_img" if item.get("isImage") else "_icon")).encode("utf-8")).hexdigest()
        out_path = os.path.join(out_dir, f"thumb_{h}.png")

        if not os.path.exists(out_path):
            if item.get("isImage"):
                try:
                    with Image.open(src) as img:
                        img.thumbnail((40, 40))
                        if img.mode != "RGBA":
                            img = img.convert("RGBA")
                        img.save(out_path, "PNG")
                except Exception:
                    cmd = f'magick -background transparent "{src}" -resize 40x40 "{out_path}"'
                    subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            else:
                cmd = f'magick -background transparent "{src}" -resize 40x40 "{out_path}"'
                subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        if os.path.exists(out_path):
            res[path] = out_path
    except Exception:
        pass

try:
    canvas_size = (85, 85)
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    center_x, center_y = canvas_size[0] // 2, canvas_size[1] // 2

    items_to_stack = data[:10]
    seed_str = "".join([item.get("path", "") for item in items_to_stack])
    rng = random.Random(seed_str)

    for item in items_to_stack:
        p = item.get("path", "")
        tpath = res.get(p)
        if not tpath or not os.path.exists(tpath): continue
        try:
            item_img = Image.open(tpath).convert("RGBA")
            angle = rng.uniform(-25, 25)
            rotated = item_img.rotate(angle, resample=Image.BICUBIC, expand=True)
            dx = rng.randint(-12, 12)
            dy = rng.randint(-12, 12)
            pos_x = center_x - rotated.width // 2 + dx
            pos_y = center_y - rotated.height // 2 + dy
            pos_x = max(0, min(canvas_size[0] - rotated.width, pos_x))
            pos_y = max(0, min(canvas_size[1] - rotated.height, pos_y))
            canvas.alpha_composite(rotated, (pos_x, pos_y))
        except Exception:
            pass

    stack_out = os.path.join(out_dir, f"grab_all_{hashlib.md5(seed_str.encode()).hexdigest()}.png")
    canvas.save(stack_out, "PNG")
    res["__grabAll"] = stack_out
except Exception:
    pass

print(json.dumps(res))`
        let payload = JSON.stringify(files.map(f => ({
            path: f.path,
            isImage: f.isImage,
            isDir: f.isDir,
            isVideo: f.isVideo,
            isAudio: f.isAudio,
            isArchive: f.isArchive
        })))
        makeThumbsProcess.command = ["python3", "-c", pyScript, payload]
        makeThumbsProcess.running = true
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
                isArchive: isArch,
                thumbPath: ""
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

        if (root.stashedFiles.length > 0) {
            generateThumbnails(root.stashedFiles)
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
                root.grabAllThumbPath = ""
            } else {
                generateThumbnails(current)
            }
        }
    }

    function clearAll() {
        root.stashedFiles = []
        root.grabAllThumbPath = ""
        root.filesUpdated()
        GlobalStates.dropzoneNotchOpen = false
    }

    function replaceStashedItems(pathsToRemove, outPathsToAdd) {
        if (!pathsToRemove || pathsToRemove.length === 0) return
        let current = Array.from(root.stashedFiles).filter(f => !pathsToRemove.includes(f.path))
        root.stashedFiles = current
        root.filesUpdated()
        if (current.length === 0) {
            root.grabAllThumbPath = ""
        }
        if (outPathsToAdd && outPathsToAdd.length > 0) {
            addFiles(outPathsToAdd)
        }
    }

    function openFile(path, isDir) {
        if (!path) return
        let checkIsDir = (isDir !== undefined) ? isDir : (root.stashedFiles.find(f => f.path === path)?.isDir ?? false)
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

        let dev = targetDevice || defaultKdeDevice
        if (destOption === "kdeconnect" && dev) {
            let sendCmd = `sleep 1 && kdeconnect-cli --device "${dev}" --share "${outPath}"`
            Quickshell.execDetached(["bash", "-c", sendCmd])
        }
        return outPath
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

        let dev = targetDevice || defaultKdeDevice
        if (destOption === "kdeconnect" && dev) {
            let sendCmd = `sleep 1 && kdeconnect-cli --device "${dev}" --share "${outPath}"`
            Quickshell.execDetached(["bash", "-c", sendCmd])
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

        let dev = targetDevice || defaultKdeDevice
        if (destOption === "kdeconnect" && dev) {
            let sendCmd = `sleep 1.5 && kdeconnect-cli --device "${dev}" --share "${outPath}"`
            Quickshell.execDetached(["bash", "-c", sendCmd])
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

        let dev = targetDevice || defaultKdeDevice
        if (destOption === "kdeconnect" && dev) {
            let sendCmd = `sleep 2 && kdeconnect-cli --device "${dev}" --share "${outDir}"`
            Quickshell.execDetached(["bash", "-c", sendCmd])
        }
        return outDir
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
