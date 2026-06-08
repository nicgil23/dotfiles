pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import "../core"

Singleton {
    id: root
    
    // Directory to scan for wallpapers
    property url directory: Qt.resolvedUrl(Directories.home + "/Pictures/wallpapers")
    property string searchQuery: ""
    
    readonly property list<string> imagePatterns: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.avif"]

    property list<string> favorites: []

    function isFavorite(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString();
        // Case-insensitive check for favorites
        for (let i = 0; i < favorites.length; i++) {
            if (favorites[i].toLowerCase() === cleanPath.toLowerCase()) return true;
        }
        return false;
    }

    function toggleFavorite(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString();
        let currentFavs = favorites.slice();
        
        let foundIndex = -1;
        for (let i = 0; i < currentFavs.length; i++) {
            if (currentFavs[i].toLowerCase() === cleanPath.toLowerCase()) {
                foundIndex = i;
                break;
            }
        }
        
        if (foundIndex === -1) {
            currentFavs.push(cleanPath);
        } else {
            currentFavs.splice(foundIndex, 1);
        }
        
        root.favorites = currentFavs;
        saveFavorites();
    }

    function selectRandomFavorite() {
        // Filter favorites to include only static images and exclude Wallpaper Engine paths
        const staticFavs = favorites.filter(path => {
            const p = path.toLowerCase();
            const isImage = p.endsWith(".jpg") || p.endsWith(".jpeg") || p.endsWith(".png") || p.endsWith(".webp") || p.endsWith(".avif");
            const isWE = p.includes("431960"); // Steam Workshop ID for Wallpaper Engine
            return isImage && !isWE;
        });

        if (staticFavs.length > 0) {
            const index = Math.floor(Math.random() * staticFavs.length);
            root.select(staticFavs[index]);
            return true;
        }
        return false;
    }

    function selectRandomFromDirectory(dirPath) {
        let cleanPath = dirPath.toString().startsWith("file://") ? dirPath.toString().substring(7) : dirPath.toString();
        // Use a shell command to pick a random image file from the directory
        const cmd = `find "${cleanPath}" -maxdepth 1 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.avif" \\) | shuf -n 1`;
        
        const proc = Quickshell.exec(["bash", "-c", cmd]);
        proc.finished.connect(() => {
            const result = proc.stdout.readAll().trim();
            if (result !== "") {
                root.select(result);
            }
        });
    }

    function saveFavorites() {
        const data = JSON.stringify(root.favorites);
        const path = Directories.favoritesPathRaw;
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" > "$2"', "sh", data, path]);
    }

    FileView {
        id: favsFile
        path: Directories.favoritesPath
        watchChanges: true
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (Array.isArray(parsed)) {
                    root.favorites = parsed;
                }
            } catch(e) {

            }
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                saveFavorites(); // Create it empty
            }
        }
    }

    // Helper process to generate material colors
    Process {
        id: matugenProc
        command: ["bash", "-c", `matugen -c ~/.config/matugen/config.toml -t "$1" -m "$2" image "$3" --source-color-index 0`, "matugen", scheme, (Config.options.appearance.background.darkmode ? "dark" : "light"), filePath]
        property string filePath
        property string scheme: Config.options.appearance.background.matugenScheme || "scheme-tonal-spot"
        
        onRunningChanged: if (running) CavaService.stop(); else CavaService.start();

        stderr: StdioCollector {
            onStreamFinished: {
                // Look for actual fatal error markers (Matugen v4 specific fatal markers)
                if (this.text.includes("Failed to generate base16 color schemes") || this.text.includes("Invalid PNG signature")) {
                    root.sendNotification("Theming Error", "Failed to process wallpaper. The file might be corrupted.");
                }
            }
        }
    }

    Process {
        id: matugenColorProc
        command: ["bash", "-c", `matugen -c ~/.config/matugen/config.toml -t "$1" -m "$2" color hex "$3"`, "matugen", scheme, (Config.options.appearance.background.darkmode ? "dark" : "light"), hexColor]
        property string hexColor
        property string scheme: {
            // When in Basic mode, always use tonal-spot for the system generation
            if (Config.ready && !Config.options.appearance.background.matugen) return "scheme-tonal-spot";
            return Config.options.appearance.background.matugenScheme || "scheme-tonal-spot";
        }

        onRunningChanged: if (running) CavaService.stop(); else CavaService.start();

        stderr: StdioCollector {
            onStreamFinished: {
                // Ignore benign errors (missing unrelated files/commands)
                if (this.text.includes("Failed to generate base16 color schemes")) {
                    root.sendNotification("Theming Error", "Failed to generate theme from color.");
                }
            }
        }
    }

    /**
     * PATH 1 — Immediate color loading via stdout.
     * Mirrors `getPreviewColoursProc` from the Caelestia shell's Wallpapers.qml.
     * Uses `matugen -j hex image PATH` which outputs full M3 JSON to stdout
     * without writing any template files, completing in ~1s.
     * MaterialThemeLoader.load() detects the stdout format and applies instantly.
     */
    Process {
        id: matugenColorsProc
        command: ["matugen",
            "-t", colorsScheme,
            "-m", (Config.options.appearance.background.darkmode ? "dark" : "light"),
            "-j", "hex",
            "image", colorsFilePath,
            "--source-color-index", "0"
        ]
        property string colorsFilePath
        property string colorsScheme: Config.options.appearance.background.matugenScheme || "scheme-tonal-spot"

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    MaterialThemeLoader.load(text);
                }
            }
        }
    }

    function sendNotification(title, body) {
        const iconPath = Quickshell.shellPath("assets/icons/NAnDoroid.svg");
        const cmd = [
            "notify-send",
            "-a", "NAnDoroid",
            "-i", iconPath,
            title,
            body
        ];
        Quickshell.execDetached(cmd);
    }

    function getWallpaperPath(source = "desktop") {
        if (source === "lockscreen") {
            return Config.options.lock.wallpaperPath;
        }
        
        if (WallpaperEngineService.active) {
            return WallpaperEngineService.screenshotPath;
        }
        
        return Config.options.appearance.background.wallpaperPath;
    }

    function toggleDarkMode() {
        if (!Config.ready) return;
        Config.options.appearance.background.darkmode = !Config.options.appearance.background.darkmode;
        
        // Re-run colors generation
        if (Config.options.appearance.background.matugen) {
            const source = Config.options.appearance.background.matugenSource || "desktop"
            const path = root.getWallpaperPath(source)
            const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
            if (cleanPath !== "") {
                // PATH 1: immediate via stdout
                matugenColorsProc.colorsFilePath = cleanPath
                matugenColorsProc.running = false
                Qt.callLater(() => { matugenColorsProc.running = true; })
                // PATH 2 (templates + system files): runs in background
                matugenProc.filePath = cleanPath
                matugenProc.running = true
            }
        } else {
            const hex = Config.options.appearance.background.matugenCustomColor
            if (hex) applyColor(hex)
        }
    }

    function select(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
        Config.options.appearance.background.wallpaperPath = "file://" + cleanPath
        
        // Sync to lockscreen if separate wallpapers are disabled
        if (Config.options.lock && !Config.options.lock.useSeparateWallpaper) {
            Config.options.lock.wallpaperPath = "file://" + cleanPath
        }
        
        if (Config.options.appearance.background.matugen) {
            // PATH 1: immediate via stdout
            matugenColorsProc.colorsFilePath = cleanPath
            matugenColorsProc.running = false
            Qt.callLater(() => { matugenColorsProc.running = true; })
            // PATH 2 (templates + system files): runs in background
            matugenProc.filePath = cleanPath
            matugenProc.running = true
        }
    }

    function applyScheme(scheme, source = "") {
        if (source === "") source = Config.options.appearance.background.matugenSource || "desktop"
        Config.options.appearance.background.matugen = true
        Config.options.appearance.background.matugenScheme = scheme
        Config.options.appearance.background.matugenSource = source
        
        if (Config.options.appearance.background.matugen) {
            const path = root.getWallpaperPath(source)
            const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
            if (cleanPath === "") return
            // PATH 1: immediate via stdout
            matugenColorsProc.colorsFilePath = cleanPath
            matugenColorsProc.running = false
            Qt.callLater(() => { matugenColorsProc.running = true; })
            // PATH 2 (templates + system files)
            matugenProc.filePath = cleanPath
            matugenProc.running = true
        }
    }

    function applyColor(hex, source = "desktop") {
        if (!Config.ready) return;
        Config.options.appearance.background.matugen = false // Disable wallpaper-based matugen
        Config.options.appearance.background.matugenCustomColor = hex
        Config.options.appearance.background.matugenThemeFile = ""
        Config.options.appearance.background.matugenSource = source
        
        matugenColorProc.running = false;
        matugenColorProc.hexColor = hex;
        // Small delay to ensure process state reset
        Qt.callLater(() => { matugenColorProc.running = true; });
    }

    function pickAccent(target = "desktop") {
        // Normalize target name to "lockscreen" if it's "lock"
        const finalTarget = target === "lock" ? "lockscreen" : target;
        const cmd = `
            pkill hyprpicker || true
            sleep 0.5
            HEX=$(hyprpicker --no-fancy)
            if [[ "$HEX" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
                ${Directories.ipcCommandPrefixString} ipc call wallpaper_accent apply_accent "$HEX" "${finalTarget}"
            else
                ${Directories.ipcCommandPrefixString} ipc call wallpaper_accent close_accent
            fi
        `;
        Quickshell.execDetached(["bash", "-c", cmd]);
    }

    IpcHandler {
        target: "wallpaper_accent"
        function apply_accent(hex: string, source: string): void {
            console.log("[Wallpapers] Accent color picked: " + hex + " for " + source);
            root.applyColor(hex, source);
            GlobalStates.accentPickerOpen = false;
        }
        function close_accent(): void {
            GlobalStates.accentPickerOpen = false;
        }
    }

    IpcHandler {
        target: "wallpaper"
        function random_favorite(): void {
            console.log("[Wallpapers] IPC call received to select random favorite");
            root.selectRandomFavorite();
        }
    }

    // Kill hyprpicker if the overlay is closed through other means (shortcut, launcher, etc)
    Connections {
        target: GlobalStates
        function onAccentPickerOpenChanged() {
            if (!GlobalStates.accentPickerOpen) {
                Quickshell.execDetached(["pkill", "hyprpicker"]);
            }
        }
    }

    Process {
        id: themeWriteProc
        command: ["bash", "-c", `cat "${sourcePath}" > "${targetPath}"`]
        property string sourcePath
        property string targetPath: Directories.generatedMaterialThemePath
    }


    function applyTheme(fileName) {
        if (!Config.ready) return;
        const themesDir = Qt.resolvedUrl("../assets/themes/").toString();
        const cleanDir = themesDir.startsWith("file://") ? themesDir.substring(7) : themesDir;
        const fullPath = cleanDir + fileName;
        
        // Update config first for proper dark mode detection in matugen
        const theme = root.findBasicThemeByFile(fileName);
        if (theme) {
            Config.options.appearance.background.matugen = false;
            Config.options.appearance.background.matugenCustomColor = theme.colors[0];
            Config.options.appearance.background.matugenThemeFile = fileName; // Unique identifier
            
            // Automatic mode switching based on theme file
            const lowerFile = fileName.toLowerCase();
            const isLight = lowerFile.includes("latte") || lowerFile.includes("_light") || lowerFile.includes("mercury") || lowerFile.includes("github");
            
            if (isLight && Config.options.appearance.background.darkmode) {
                Config.options.appearance.background.darkmode = false;
            } else if (!isLight && !Config.options.appearance.background.darkmode) {
                Config.options.appearance.background.darkmode = true;
            }

            // Run matugen to generate full system colors (GTK, KDE, etc) from the first basic color
            matugenColorProc.hexColor = theme.colors[0];
            matugenColorProc.running = true;
        }

        // 1. Save for persistence
        themeWriteProc.sourcePath = fullPath;
        themeWriteProc.running = true;

        // 2. Force immediate UI reload (FileView watcher fires after write,
        //    but for static themes we trigger it explicitly for instant feedback)
        MaterialThemeLoader.reapplyTheme();
    }
    
    function initializeMatugen() {
        if (!Config.ready) {
            configWaitTimer.start();
            return;
        }
        
        if (Config.options.appearance.background.matugen) {
            const source = Config.options.appearance.background.matugenSource || "desktop"
            const path = root.getWallpaperPath(source);
            const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString();
            if (cleanPath !== "") {
                // PATH 1: immediate — load colors from stdout (-j hex, no template files written)
                matugenColorsProc.colorsFilePath = cleanPath;
                matugenColorsProc.running = false;
                Qt.callLater(() => { matugenColorsProc.running = true; });
                // PATH 2: full template run (writes GTK, Hyprland, colors.json, etc.)
                matugenProc.filePath = cleanPath;
                matugenProc.running = true;
            }
        }
    }

    Timer {
        id: configWaitTimer
        interval: 500
        repeat: false
        onTriggered: root.initializeMatugen()
    }

    function findBasicThemeByFile(fileName) {
        const basicThemes = [
            { file: "angel.json", colors: ["#5682A3"] },
            { file: "angel_light.json", colors: ["#5682A3"] },
            { file: "ayu.json", colors: ["#ffb454"] },
            { file: "cobalt2.json", colors: ["#ffc600"] },
            { file: "cursor.json", colors: ["#2DD5B7"] },
            { file: "dracula.json", colors: ["#bd93f9"] },
            { file: "flexoki.json", colors: ["#ceb3a2"] },
            { file: "frappe.json", colors: ["#ca9ee6"] },
            { file: "github.json", colors: ["#d73a49"] },
            { file: "gruvbox.json", colors: ["#fab387"] },
            { file: "kanagawa.json", colors: ["#7e9cd8"] },
            { file: "latte.json", colors: ["#8839ef"] },
            { file: "macchiato.json", colors: ["#c6a0f6"] },
            { file: "material_ocean.json", colors: ["#89ddff"] },
            { file: "matrix.json", colors: ["#00FF41"] },
            { file: "mercury.json", colors: ["#E0E0E0"] },
            { file: "mocha.json", colors: ["#cba6f7"] },
            { file: "nord.json", colors: ["#88c0d0"] },
            { file: "open_code.json", colors: ["#2DD5B7"] },
            { file: "orng.json", colors: ["#FF9500"] },
            { file: "osaka_jade.json", colors: ["#00A676"] },
            { file: "rose_pine.json", colors: ["#c4a7e7"] },
            { file: "sakura.json", colors: ["#d4869c"] },
            { file: "samurai.json", colors: ["#c41e3a"] },
            { file: "synthwave84.json", colors: ["#36f9f6"] },
            { file: "vercel.json", colors: ["#0070F3"] },
            { file: "vesper.json", colors: ["#FFC799"] },
            { file: "zen_burn.json", colors: ["#8cd0d3"] },
            { file: "zen_garden.json", colors: ["#7a9a7a"] }
        ];
        return basicThemes.find(t => t.file === fileName);
    }

    function selectForLockscreen(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
        Config.options.lock.wallpaperPath = "file://" + cleanPath
    }

    function generateColors(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
        if (Config.options.appearance.background.matugen) {
            matugenProc.filePath = cleanPath
            matugenProc.running = true
        }
    }

    // --- Local state for better reactivity ---
    property bool _autoCycleEnabled: false
    property string _autoCycleDirectory: ""
    property int _autoCycleInterval: 30

    // Explicit setters for the UI to call directly
    function setAutoCycle(enabled) {
        if (!Config.ready) return;
        Config.options.appearance.background.autoCycleEnabled = enabled;
        _autoCycleEnabled = enabled;
        if (enabled) {
            autoCycleStartTimer.restart();
        } else {
            root.autoCyclePending = false;
        }
    }

    function setAutoCycleDirectory(dir) {
        if (!Config.ready) return;
        Config.options.appearance.background.autoCycleDirectory = dir;
        _autoCycleDirectory = dir;
    }

    function setAutoCycleInterval(interval) {
        if (!Config.ready) return;
        Config.options.appearance.background.autoCycleInterval = interval;
        _autoCycleInterval = interval;
    }

    function syncSettings() {
        if (!Config.ready) return;
        const bg = Config.options.appearance.background;
        _autoCycleEnabled = bg.autoCycleEnabled;
        _autoCycleDirectory = bg.autoCycleDirectory || "";
        _autoCycleInterval = bg.autoCycleInterval || 30;
        
        
        // Initial theme load on startup/reload
        if (bg.matugen) {
            root.initializeMatugen();
        } else {
            const theme = bg.matugenThemeFile;
            if (theme && theme !== "") {
                root.applyTheme(theme);
            } else if (bg.matugenCustomColor && bg.matugenCustomColor !== "") {
                root.applyColor(bg.matugenCustomColor);
            } else {
                root.applyTheme("mocha.json");
            }
        }

        if (_autoCycleEnabled) {
            // Kickstart the cycle on startup or reload
            autoCycleStartTimer.restart();
        }

        root.scanDirectory();
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                root.syncSettings();
            }
        }
    }

    // --- Sorting ---
    property int sortField: FolderListModel.Name
    property bool sortReversed: false

    // --- Folder Picker ---
    Process {
        id: folderPickerProc
        command: ["zenity", "--file-selection", "--directory", "--title=Select Wallpaper Folder"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path !== "") {
                    let current = (Config.options.appearance.background.customFolders || []).slice();
                    if (!current.includes(path)) {
                        current.push(path);
                        Config.options.appearance.background.customFolders = current;
                        root.customFoldersChanged();
                    }
                }
                // Use a timer to ensure the process has fully detached before reopening UI
                reopenTimer.start();
            }
        }
    }

    Timer {
        id: reopenTimer
        interval: 100
        repeat: false
        onTriggered: root.pickerFinished()
    }

    signal customFoldersChanged()
    signal pickerFinished()

    function browseFolder() {
        GlobalStates.wallpaperSelectorOpen = false;
        folderPickerProc.running = true;
    }

    // Model for grid view
    property alias folderModel: model
    ListModel {
        id: model
        onCountChanged: {
            if (count > 0 && root._autoCycleEnabled && root.autoCyclePending) {
                root.autoCyclePending = false;
                root.nextWallpaper();
            }
        }
    }

    property string activeFolder: {
        if (!root._autoCycleEnabled || root._autoCycleDirectory === "") return root.directory.toString();
        let dir = root._autoCycleDirectory;
        if (!dir.startsWith("file://")) dir = "file://" + dir;
        return dir;
    }
    
    onActiveFolderChanged: scanDirectory()
    onSearchQueryChanged: refreshModel()
    onSortFieldChanged: refreshModel()
    onSortReversedChanged: refreshModel()

    property var _allWallpapers: []
    property bool loading: false

    function scanDirectory() {
        let path = activeFolder;
        if (path.startsWith("file://")) {
            path = path.substring(7);
        }
        if (path === "") return;
        
        let isRecursive = path.toLowerCase().includes("/pictures/wallpapers");
        if (!isRecursive) {
            const custom = Config.options.appearance.background.customFolders || [];
            for (let i = 0; i < custom.length; i++) {
                if (path.startsWith(custom[i])) {
                    isRecursive = true;
                    break;
                }
            }
        }
        
        scannerProcess.running = false;
        
        let cmd = ["find", "-L", path];
        if (!isRecursive) {
            cmd.push("-maxdepth", "1");
        }
        cmd.push("-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", "-o", "-iname", "*.avif", ")");
        
        scannerProcess.command = cmd;
        root.loading = true;
        scannerProcess.running = true;
    }

    Process {
        id: scannerProcess
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                const lines = this.text.split("\n");
                let list = [];
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line !== "") {
                        list.push(line);
                    }
                }
                root._allWallpapers = list;
                root.refreshModel();
            }
        }
    }

    function refreshModel() {
        model.clear();
        
        let filtered = root._allWallpapers.slice();
        if (root.searchQuery !== "") {
            const queryLower = root.searchQuery.toLowerCase();
            filtered = filtered.filter(p => {
                const fileName = p.substring(p.lastIndexOf('/') + 1);
                return fileName.toLowerCase().includes(queryLower);
            });
        }
        
        // Sort by filename (case-insensitive)
        filtered.sort((a, b) => {
            const fileA = a.substring(a.lastIndexOf('/') + 1).toLowerCase();
            const fileB = b.substring(b.lastIndexOf('/') + 1).toLowerCase();
            let cmp = fileA.localeCompare(fileB);
            return root.sortReversed ? -cmp : cmp;
        });
        
        // Populate
        for (let i = 0; i < filtered.length; i++) {
            const path = filtered[i];
            const fileName = path.substring(path.lastIndexOf('/') + 1);
            model.append({
                "filePath": path,
                "fileName": fileName,
                "fileUrl": "file://" + path
            });
        }
    }

    function notifyFileDeleted(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString();
        const index = _allWallpapers.indexOf(cleanPath);
        if (index !== -1) {
            _allWallpapers.splice(index, 1);
            refreshModel();
        }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen) {
                root.scanDirectory();
            }
        }
    }

    property bool autoCyclePending: false

    Timer {
        id: autoCycleStartTimer
        interval: 1000 // Give it a bit more time on startup
        repeat: false
        onTriggered: {
            if (!root._autoCycleEnabled) return;
            
            if (model.count > 0) {
                root.nextWallpaper();
            } else {
                root.autoCyclePending = true;
            }
        }
    }

    Component.onCompleted: {
        if (Config.ready) {
            root.syncSettings();
        }
    }

    Connections {
        // Matugen doesn't suffer as much because it's usually called by other UI interactions
        // but we'll leave it as is or handle it similarly if needed
        target: (Config.ready && Config.options.appearance) ? Config.options.appearance.background : null
        ignoreUnknownSignals: true
        function onMatugenChanged() {
            if (!Config.ready) return;
            const bg = Config.options.appearance.background;
            if (bg.matugen) {
                root.initializeMatugen();
            } else {
                const theme = bg.matugenThemeFile;
                if (theme && theme !== "") {
                    root.applyTheme(theme);
                } else if (bg.matugenCustomColor && bg.matugenCustomColor !== "") {
                    root.applyColor(bg.matugenCustomColor);
                } else {
                    root.applyTheme("mocha.json");
                }
            }
        }
    }

    // --- Wallpaper Auto-Cycle ---
    Timer {
        id: autoCycleTimer
        interval: Math.max(1, root._autoCycleInterval) * 60 * 1000
        running: root._autoCycleEnabled && !GameMode.active
        repeat: true
        onTriggered: {
            root.nextWallpaper();
        }
    }

    function nextWallpaper() {
        if (!Config.ready) return;
        if (!root._autoCycleEnabled) return;

        const count = model.count;
        if (count <= 0) {
            root.autoCyclePending = true;
            return;
        }

        let index = Math.floor(Math.random() * count);
        let newPath = null;
        try {
            let item = model.get(index);
            if (item && item.fileUrl) newPath = item.fileUrl;
        } catch (e) {}
        if (!newPath) {
            try {
                newPath = model.get(index, "fileUrl");
            } catch (e) {}
        }

        if (!newPath) {
            root.autoCyclePending = true;
            return;
        }


        if (newPath.toString() === Config.options.appearance.background.wallpaperPath.toString() && count > 1) {
            index = (index + 1) % count;
            
            let secondPath = null;
            try {
                let secondItem = model.get(index);
                if (secondItem && secondItem.fileUrl) secondPath = secondItem.fileUrl;
            } catch (e) {}
            if (!secondPath) {
                try {
                    secondPath = model.get(index, "fileUrl");
                } catch (e) {}
            }
            if (secondPath) newPath = secondPath;
        }

        root.select(newPath);
    }
}
