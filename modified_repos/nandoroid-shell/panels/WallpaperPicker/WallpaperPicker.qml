import "../../core"
import "../../services"
import "../../widgets"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtCore
import Qt.labs.folderlistmodel
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * Serpantinum-Style QuickShell 3D Carousel Wallpaper Picker for NAnDoroid Shell.
 * Features:
 * - 3D skewed horizontal carousel wallpaper view.
 * - Integration with NAnDoroid Wallpapers & Appearance services.
 * - Online DuckDuckGo wallpaper search & local video previews.
 * - Integrated Native Accent Picker trigger to replace pure static color picker.
 */
Variants {
    id: root
    model: Quickshell.screens

    Loader {
        id: panelLoader
        required property var modelData
        active: GlobalStates.carouselWallpaperPickerOpen

        sourceComponent: PanelWindow {
            id: window
            screen: modelData
            exclusiveZone: 0
            WlrLayershell.namespace: "nandoroid:wallpaperpicker"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                
                TapHandler {
                    onTapped: GlobalStates.carouselWallpaperPickerOpen = false
                }
            }

            Item {
                id: pickerContent
                anchors.fill: parent
                focus: true

                function applyCurrentWallpaper() {
                    if (view.currentIndex >= 0 && view.currentIndex < view.count) {
                        let currentData = view.model.get(view.currentIndex);
                        if (currentData) {
                            let fn = currentData.fileName;
                            let fp = currentData.fullPath !== undefined ? currentData.fullPath : "";
                            let isLive = currentData.isLiveEngine === true;
                            pickerContent.applyWallpaper(fn, fn && (fn.startsWith("000_") || fn.endsWith(".mp4") || fn.endsWith(".webm")), fp, isLive);
                        }
                    }
                }

                Keys.onEscapePressed: (event) => {
                    GlobalStates.carouselWallpaperPickerOpen = false;
                    if (event) event.accepted = true;
                }

                Keys.onReturnPressed: (event) => {
                    if (searchInput.activeFocus) {
                        view.forceActiveFocus();
                        if (event) event.accepted = true;
                        return;
                    }
                    pickerContent.applyCurrentWallpaper();
                }

                Keys.onEnterPressed: (event) => {
                    if (searchInput.activeFocus) {
                        view.forceActiveFocus();
                        if (event) event.accepted = true;
                        return;
                    }
                    pickerContent.applyCurrentWallpaper();
                }

                Keys.onLeftPressed: (event) => {
                    if (searchInput.activeFocus) return;
                    if (view.currentIndex > 0) {
                        view.currentIndex--;
                    }
                    view.forceActiveFocus();
                    event.accepted = true;
                }

                Keys.onRightPressed: (event) => {
                    if (searchInput.activeFocus) return;
                    if (view.currentIndex < view.count - 1) {
                        view.currentIndex++;
                    }
                    view.forceActiveFocus();
                    event.accepted = true;
                }

                Keys.onTabPressed: (event) => {
                    let filters = ["All", "Static", "Live"];
                    let idx = filters.indexOf(pickerContent.currentFilter);
                    if (idx === -1) idx = 0;
                    if (event.modifiers & Qt.ShiftModifier) {
                        idx = (idx - 1 + filters.length) % filters.length;
                    } else {
                        idx = (idx + 1) % filters.length;
                    }
                    pickerContent.currentFilter = filters[idx];
                    view.forceActiveFocus();
                    event.accepted = true;
                }

                Keys.onBacktabPressed: (event) => {
                    let filters = ["All", "Static", "Live"];
                    let idx = filters.indexOf(pickerContent.currentFilter);
                    if (idx === -1) idx = 0;
                    idx = (idx - 1 + filters.length) % filters.length;
                    pickerContent.currentFilter = filters[idx];
                    view.forceActiveFocus();
                    event.accepted = true;
                }

                Keys.onPressed: (event) => {
                    if (!searchInput.activeFocus && event.text && event.text.length === 1) {
                        if (!(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                            let ch = event.text;
                            if (ch >= ' ' && event.key !== Qt.Key_Escape && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Tab && event.key !== Qt.Key_Backtab) {
                                searchInput.forceActiveFocus();
                                searchInput.text = searchInput.text + ch;
                                searchInput.cursorPosition = searchInput.text.length;
                                event.accepted = true;
                                return;
                            }
                        }
                    }
                }

                property string widgetArg: ""
                property string targetWallName: ""
                property bool initialFocusSet: false
                property int visibleItemCount: -1
                property int scrollAccum: 0
                property real scrollThreshold: 300 * Appearance.effectiveScale

                property string currentFilter: "All"
                property string _lastFilter: "All"
                property string searchQuery: ""
                property bool isOnlineSearch: false
                property bool isSearchPaused: false
                property bool hasSearched: false
                property var colorMap: ({})
                property int cacheVersion: 0 

                property bool isDownloadingWallpaper: false
                property string currentDownloadName: ""

                property bool isApplying: false
                property bool isMonitorSelectorOpen: false
                property bool allowAddAnimation: false

                Timer {
                    id: applyUnlockTimer
                    interval: 250
                    onTriggered: pickerContent.isApplying = false
                }

                property bool isStartup: localFolderModel.status === FolderListModel.Loading || srcModel.status === FolderListModel.Loading
                property bool isReady: localFolderModel.status === FolderListModel.Ready
                property bool isSearchActive: pickerContent.currentFilter === "Search" && pickerContent.hasSearched && searchFolderModel.status === FolderListModel.Loading

                property string lastSearchName: ""
                property bool isModelChanging: false
                property bool searchIndexRestored: false

                property bool isScrollingBlocked: pickerContent.currentFilter === "Search" && pickerContent.hasSearched && pickerContent.isSearchActive && !pickerContent.isSearchPaused
                property bool jumpToLastOnFilterChange: false

                readonly property var filterData: [
                    { name: "All", hex: "", label: "All" },
                    { name: "Video", hex: "", label: "Vid" },
                    { name: "Red", hex: "#FF4500", label: "" },
                    { name: "Orange", hex: "#FFA500", label: "" },
                    { name: "Yellow", hex: "#FFD700", label: "" },
                    { name: "Green", hex: "#32CD32", label: "" },
                    { name: "Blue", hex: "#1E90FF", label: "" },
                    { name: "Purple", hex: "#8A2BE2", label: "" },
                    { name: "Pink", hex: "#FF69B4", label: "" },
                    { name: "Monochrome", hex: "#A9A9A9", label: "" },
                    { name: "Search", hex: "", label: "Search" } 
                ]

                ListModel { id: monitorModel }

                Process {
                    id: monitorProc
                    command: ["sh", "-c", "hyprctl monitors -j"]
                    running: false
                    
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let response = this.text; 
                            if (response && response.trim().length > 0) {
                                try {
                                    var monitors = JSON.parse(response);
                                    monitorModel.clear();
                                    for (var i = 0; i < monitors.length; i++) {
                                        monitorModel.append({ "name": monitors[i].name, "selected": true });
                                    }
                                } catch(e) {
                                    console.log("[WallpaperPicker] Error parsing monitors: " + e);
                                }
                            }
                        }
                    }
                }

                function loadMonitors() {
                    monitorProc.running = true;
                }

                function getMonitorOutputs() {
                    if (monitorModel.count <= 1) return "all"; 
                    let selected = [];
                    for (let i = 0; i < monitorModel.count; i++) {
                        if (monitorModel.get(i).selected) {
                            selected.push(monitorModel.get(i).name);
                        }
                    }
                    if (selected.length === 0) return "none";
                    if (selected.length === monitorModel.count) return "all";
                    return selected.join(",");
                }

                function applyWallpaper(safeFileName, isVideo, fullPath, isLiveEngine) {
                    if (!safeFileName || pickerContent.isApplying) return;
                    
                    pickerContent.isApplying = true;
                    applyUnlockTimer.restart();
                    pickerContent.targetWallName = safeFileName;

                    if (isLiveEngine || (fullPath && fullPath.includes("431960"))) {
                        let itemFileUrl = "";
                        let model = pickerContent.activeModel;
                        if (view.currentIndex >= 0 && view.currentIndex < model.count) {
                            itemFileUrl = model.get(view.currentIndex).fileUrl || "";
                        }
                        WallpaperEngineService.apply(fullPath, itemFileUrl);
                        pickerContent.isApplying = false;
                        return;
                    }

                    if (pickerContent.currentFilter === "Search" && pickerContent.hasSearched) {
                        let destFile = pickerContent.srcDir + "/" + safeFileName;
                        let mapFile = Directories.genericCache + "/nandoroid/wallpaper_picker/search_map.txt";
                        let alreadyExists = pickerContent.isDownloaded(safeFileName);

                        if (alreadyExists) {
                            Wallpapers.select(destFile);
                            pickerContent.isApplying = false;
                        } else {
                            pickerContent.isDownloadingWallpaper = true;
                            pickerContent.currentDownloadName = safeFileName;

                            const downloadScript = `
                                MAP_FILE="${mapFile}"
                                DEST_FILE="${destFile}"
                                SAFE_NAME="${safeFileName}"
                                URL=$(awk -F'|' -v fname="$SAFE_NAME" '$1 == fname {print $2; exit}' "$MAP_FILE")
                                if [ -n "$URL" ]; then
                                    curl -s -L -A "Mozilla/5.0" "$URL" -o "$DEST_FILE.tmp"
                                    if file "$DEST_FILE.tmp" | grep -iq "webp"; then
                                        if command -v magick &>/devnull; then
                                            magick "$DEST_FILE.tmp" "$DEST_FILE"
                                            rm -f "$DEST_FILE.tmp"
                                        else
                                            mv "$DEST_FILE.tmp" "$DEST_FILE"
                                        fi
                                    else
                                        mv "$DEST_FILE.tmp" "$DEST_FILE"
                                    fi
                                fi
                            `;
                            const dlProc = Quickshell.exec(["bash", "-c", downloadScript]);
                            dlProc.finished.connect(() => {
                                pickerContent.isDownloadingWallpaper = false;
                                Wallpapers.select(destFile);
                                pickerContent.isApplying = false;
                            });
                        }
                        return;
                    }

                    const originalFile = (fullPath && fullPath !== "") ? fullPath : (pickerContent.srcDir + "/" + pickerContent.getCleanName(safeFileName));
                    Wallpapers.select(originalFile);
                }

                readonly property string thumbDir: Directories.genericCache + "/nandoroid/wallpaper_picker/thumbs"
                readonly property string searchDir: Directories.genericCache + "/nandoroid/wallpaper_picker/search_thumbs"
                readonly property string srcDir: Functions.FileUtils.trimFileProtocol(Wallpapers.directory)

                readonly property real itemWidth: 400 * Appearance.effectiveScale
                readonly property real itemHeight: 420 * Appearance.effectiveScale
                readonly property real borderWidth: 3 * Appearance.effectiveScale
                readonly property real spacing: 10 * Appearance.effectiveScale
                readonly property real skewFactor: -0.35

                Timer {
                    id: scrollThrottle
                    interval: 150
                }

                property bool isFilterAnimating: false
                Timer {
                    id: filterAnimationTimer
                    interval: 800
                    onTriggered: pickerContent.isFilterAnimating = false
                }

                property bool isItemAnimating: false
                Timer {
                    id: itemAnimationTimer
                    interval: 500
                    onTriggered: pickerContent.isItemAnimating = false
                }

                function getHexBucket(hexStr) {
                    if (!hexStr) return "Monochrome";
                    hexStr = String(hexStr).trim().replace(/#/g, '');
                    if (hexStr.length > 6) hexStr = hexStr.substring(0, 6);
                    if (hexStr.length !== 6) return "Monochrome";

                    let r = parseInt(hexStr.substring(0,2), 16) / 255;
                    let g = parseInt(hexStr.substring(2,4), 16) / 255;
                    let b = parseInt(hexStr.substring(4,6), 16) / 255;

                    if (isNaN(r) || isNaN(g) || isNaN(b)) return "Monochrome";

                    let max = Math.max(r, g, b), min = Math.min(r, g, b);
                    let d = max - min;
                    let h = 0;
                    let s = max === 0 ? 0 : d / max;
                    let v = max;

                    if (max !== min) {
                        if (max === r) h = (g - b) / d + (g < b ? 6 : 0);
                        else if (max === g) h = (b - r) / d + 2;
                        else h = (r - g) / d + 4;
                        h /= 6;
                    }
                    h = h * 360;

                    if (s < 0.05 || v < 0.08) return "Monochrome";
                    if (h >= 345 || h < 15) return "Red";
                    if (h >= 15 && h < 45) return "Orange";
                    if (h >= 45 && h < 75) return "Yellow";
                    if (h >= 75 && h < 165) return "Green";
                    if (h >= 165 && h < 260) return "Blue";
                    if (h >= 260 && h < 315) return "Purple";
                    if (h >= 315 && h < 345) return "Pink";

                    return "Monochrome";
                }

                function checkItemMatchesFilter(fileName, isVid, cv, filter) {
                    if (filter === "Search" || filter === "All") return true;
                    if (filter === "Video") return isVid;
                    let hexColor = pickerContent.colorMap[String(fileName)];
                    if (!hexColor) return filter === "Monochrome";
                    return pickerContent.getHexBucket(hexColor) === filter;
                }

                function getCleanName(name) {
                    if (!name) return "";
                    let clean = String(name);
                    return clean.startsWith("000_") ? clean.substring(4) : clean;
                }

                function isDownloaded(name) {
                    if (!name) return false;
                    for (let i = 0; i < srcModel.count; i++) {
                        if (srcModel.get(i, "fileName") === name) return true;
                    }
                    return false;
                }

                FolderListModel {
                    id: srcModel
                    folder: "file://" + pickerContent.srcDir
                    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
                    showDirs: false
                }

                ListModel { id: localProxyModel }
                ListModel { id: searchProxyModel }

                readonly property var activeModel: pickerContent.currentFilter === "Search" ? searchProxyModel : localProxyModel

                FolderListModel {
                    id: localFolderModel
                    folder: "file://" + pickerContent.srcDir
                    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
                    showDirs: false
                    sortField: FolderListModel.Name
                    
                    onCountChanged: pickerContent.syncLocalModel()
                    onStatusChanged: { if (status === FolderListModel.Ready) pickerContent.syncLocalModel() }
                }

                Connections {
                    target: Wallpapers
                    function onFavoritesChanged() { pickerContent.syncLocalModel(); }
                    function onRecursiveWallpapersChanged() { pickerContent.syncLocalModel(); }
                }

                onVisibleChanged: {
                    if (visible) {
                        Wallpapers.refreshRecursiveWallpapers();
                        if (Config.options.appearance.background.liveWallpaperPath !== "" && WallpaperEngineService.results.count === 0 && !WallpaperEngineService.loading) {
                            WallpaperEngineService.fetch();
                        }
                        syncLocalModel();
                        Qt.callLater(pickerContent.selectCurrentWallpaper);
                    }
                }

                onCurrentFilterChanged: syncLocalModel()
                onSearchQueryChanged: syncLocalModel()

                function selectCurrentWallpaper() {
                    let livePath = Config.ready ? Config.options.appearance.background.liveWallpaperPath : "";
                    let currentRaw = (livePath && livePath !== "") ? livePath : Config.options.appearance.background.wallpaperPath;
                    let currentPath = Functions.FileUtils.trimFileProtocol(currentRaw);
                    if (!currentPath || currentPath === "") return;

                    currentPath = currentPath.replace(/\/+/g, "/").replace(/\/+$/, "");
                    let currentFolderId = currentPath.split("/").pop();

                    let model = pickerContent.activeModel;
                    if (!model || model.count === 0) return;

                    let targetIndex = -1;

                    for (let i = 0; i < model.count; i++) {
                        let item = model.get(i);
                        let itemRaw = item.fullPath ? item.fullPath : item.fileUrl;
                        if (itemRaw) {
                            let itemPath = Functions.FileUtils.trimFileProtocol(itemRaw).replace(/\/+/g, "/").replace(/\/+$/, "");
                            if (itemPath === currentPath || (currentFolderId && (itemPath.endsWith("/" + currentFolderId) || itemPath === currentFolderId))) {
                                targetIndex = i;
                                break;
                            }
                        }
                        let itemCleanName = pickerContent.getCleanName(item.fileName);
                        if (targetIndex === -1 && itemCleanName && currentFolderId && itemCleanName === currentFolderId) {
                            targetIndex = i;
                        }
                    }

                    if (targetIndex >= 0 && targetIndex < model.count) {
                        view.currentIndex = targetIndex;
                        view.positionViewAtIndex(targetIndex, ListView.Beginning);
                    }
                }

                function syncLocalModel() {
                    localProxyModel.clear();
                    let rawList = Wallpapers.recursiveWallpapers;
                    let batch = [];
                    let filter = pickerContent.currentFilter;
                    let query = pickerContent.searchQuery.toLowerCase().trim();

                    if (rawList && rawList.length > 0) {
                        for (let i = 0; i < rawList.length; i++) {
                            let item = rawList[i];
                            let fn = item.fileName;
                            let fu = item.fileUrl;
                            let fp = item.fullPath;
                            let isVid = item.isVideo;

                            if (filter === "Static" && isVid) continue;
                            if (filter === "Live" && !isVid) continue;

                            if (query !== "" && !fn.toLowerCase().includes(query)) continue;

                            batch.push({ "fileName": fn, "fileUrl": fu, "fullPath": fp, "isLiveEngine": false });
                        }
                    } else {
                        let folderCount = localFolderModel.count;
                        for (let i = 0; i < folderCount; i++) {
                            let fn = localFolderModel.get(i, "fileName");
                            let fu = localFolderModel.get(i, "fileUrl");
                            if (fn !== undefined) {
                                let lowerFn = String(fn).toLowerCase();
                                let isVid = fn.startsWith("000_") || lowerFn.endsWith(".mp4") || lowerFn.endsWith(".webm") || lowerFn.endsWith(".mkv") || lowerFn.endsWith(".mov") || lowerFn.endsWith(".gif");
                                if (filter === "Static" && isVid) continue;
                                if (filter === "Live" && !isVid) continue;
                                if (query !== "" && !lowerFn.includes(query)) continue;
                                batch.push({ "fileName": fn, "fileUrl": String(fu), "fullPath": "", "isLiveEngine": false });
                            }
                        }
                    }

                    if (filter === "All" || filter === "Live") {
                        if (WallpaperEngineService.results && WallpaperEngineService.results.count > 0) {
                            for (let i = 0; i < WallpaperEngineService.results.count; i++) {
                                let weItem = WallpaperEngineService.results.get(i);
                                let title = weItem.title ? weItem.title : "Live Wallpaper";
                                let previewUrl = weItem.preview ? weItem.preview : "";
                                let folderPath = weItem.folder ? weItem.folder : "";

                                if (query !== "" && !title.toLowerCase().includes(query)) continue;

                                batch.push({
                                    "fileName": title,
                                    "fileUrl": previewUrl,
                                    "fullPath": folderPath,
                                    "isLiveEngine": true
                                });
                            }
                        }
                    }

                    if (batch.length > 0) {
                        localProxyModel.append(batch);
                    }
                    Qt.callLater(pickerContent.selectCurrentWallpaper);
                }

                FolderListModel {
                    id: searchFolderModel
                    folder: "file://" + pickerContent.searchDir
                    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
                    showDirs: false
                    sortField: FolderListModel.Name
                    onCountChanged: pickerContent.syncSearchModel()
                }

                function syncSearchModel() {
                    let startIdx = searchProxyModel.count;
                    let endIdx = searchFolderModel.count;
                    if (endIdx < startIdx) {
                        searchProxyModel.clear();
                        startIdx = 0;
                    }
                    let batch = [];
                    for (let i = startIdx; i < endIdx; i++) {
                        let fn = searchFolderModel.get(i, "fileName");
                        let fu = searchFolderModel.get(i, "fileUrl");
                        if (fn !== undefined) {
                            batch.push({ "fileName": fn, "fileUrl": String(fu) });
                        }
                    }
                    if (batch.length > 0) searchProxyModel.append(batch);
                }

                function triggerOnlineSearch() {
                    if (searchInput.text.trim() === "") return;
                    searchProxyModel.clear();
                    pickerContent.isOnlineSearch = true;
                    pickerContent.hasSearched = true;
                    pickerContent.isSearchPaused = false;
                    pickerContent.searchQuery = searchInput.text.trim();

                    let rawSearchDir = pickerContent.searchDir;
                    let scriptPath = Directories.assetsPath + "/../scripts/wallpaper/ddg_search.sh";
                    let runDir = Directories.genericCache + "/nandoroid/wallpaper_picker";

                    const cmd = `
                        mkdir -p "${rawSearchDir}" "${runDir}"
                        echo 'run' > "${runDir}/ddg_search_control"
                        bash "${scriptPath}" "${pickerContent.searchQuery}" &
                    `;
                    Quickshell.execDetached(["bash", "-c", cmd]);
                    searchInput.focus = false;
                    view.forceActiveFocus();
                }

                // ── Carousel ListView ──
                ListView {
                    id: view
                    anchors.fill: parent
                    spacing: 0
                    orientation: ListView.Horizontal
                    clip: false
                    cacheBuffer: 2000
                    flickDeceleration: 5000
                    maximumFlickVelocity: 2500

                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: (width / 2) - ((pickerContent.itemWidth * 1.5 + pickerContent.spacing) / 2)
                    preferredHighlightEnd: (width / 2) + ((pickerContent.itemWidth * 1.5 + pickerContent.spacing) / 2)
                    highlightMoveDuration: 500
                    focus: true

                    header: Item { width: Math.max(0, (view.width / 2) - ((pickerContent.itemWidth * 1.5) / 2)) }
                    footer: Item { width: Math.max(0, (view.width / 2) - ((pickerContent.itemWidth * 1.5) / 2)) }

                    model: pickerContent.activeModel

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        onWheel: (wheel) => {
                            if (scrollThrottle.running) { wheel.accepted = true; return; }
                            let dx = wheel.angleDelta.x;
                            let dy = wheel.angleDelta.y;
                            let delta = Math.abs(dx) > Math.abs(dy) ? dx : dy;
                            if (delta < 0 && view.currentIndex < view.count - 1) {
                                view.currentIndex++;
                            } else if (delta > 0 && view.currentIndex > 0) {
                                view.currentIndex--;
                            }
                            scrollThrottle.start();
                            wheel.accepted = true;
                        }
                    }

                    delegate: Item {
                        id: delegateRoot
                        readonly property string safeFileName: fileName !== undefined ? String(fileName) : ""
                        readonly property bool isCurrent: ListView.isCurrentItem
                        readonly property bool isVideo: safeFileName.startsWith("000_") || safeFileName.endsWith(".mp4") || safeFileName.endsWith(".webm")
                        readonly property real targetWidth: isCurrent ? (pickerContent.itemWidth * 1.5) : (pickerContent.itemWidth * 0.5)
                        readonly property real targetHeight: isCurrent ? (pickerContent.itemHeight + (30 * Appearance.effectiveScale)) : pickerContent.itemHeight

                        width: targetWidth + pickerContent.spacing
                        height: targetHeight
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        opacity: isCurrent ? 1.0 : 0.6
                        z: isCurrent ? 10 : 1

                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }

                        Item {
                            anchors.centerIn: parent
                            width: parent.width > 0 ? parent.width * (targetWidth / (targetWidth + pickerContent.spacing)) : 0
                            height: parent.height

                            transform: Matrix4x4 {
                                property real s: pickerContent.skewFactor
                                matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    view.currentIndex = index;
                                    pickerContent.applyWallpaper(delegateRoot.safeFileName, delegateRoot.isVideo, model.fullPath !== undefined ? model.fullPath : "", model.isLiveEngine === true);
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: Appearance.colors.colLayer1
                                radius: 16 * Appearance.effectiveScale
                                border.color: delegateRoot.isCurrent ? Appearance.m3colors.m3primary : Appearance.colors.colOutlineVariant
                                border.width: delegateRoot.isCurrent ? (3 * Appearance.effectiveScale) : 1
                                clip: true

                                Image {
                                    anchors.centerIn: parent
                                    anchors.horizontalCenterOffset: pickerContent.skewFactor * (parent.height / 2)
                                    width: parent.width + Math.abs(pickerContent.skewFactor) * parent.height
                                    height: parent.height
                                    fillMode: Image.PreserveAspectCrop
                                    source: fileUrl !== undefined ? fileUrl : ""
                                    asynchronous: true

                                    transform: Matrix4x4 {
                                        property real s: -pickerContent.skewFactor
                                        matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Top Navigation / Control Bar ──
                Rectangle {
                    id: topBar
                    anchors.top: parent.top
                    anchors.topMargin: Math.max(20 * Appearance.effectiveScale, (parent.height / 2) - (pickerContent.itemHeight / 2) - (110 * Appearance.effectiveScale))
                    anchors.horizontalCenter: parent.horizontalCenter
                    z: 20
                    height: 56 * Appearance.effectiveScale
                    width: topRow.width + (32 * Appearance.effectiveScale)
                    radius: 28 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer0
                    border.color: Appearance.colors.colOutlineVariant
                    border.width: 1

                    RowLayout {
                        id: topRow
                        anchors.centerIn: parent
                        spacing: 10 * Appearance.effectiveScale

                        // --- Filter Buttons in exact requested order ---
                        RippleButton {
                            implicitWidth: 70 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            toggled: pickerContent.currentFilter === "All"
                            colBackground: toggled ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                            onClicked: { pickerContent.currentFilter = "All"; view.forceActiveFocus(); }

                            StyledText {
                                anchors.centerIn: parent
                                text: "All"
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: parent.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                            }
                        }

                        RippleButton {
                            implicitWidth: 64 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            toggled: pickerContent.currentFilter === "Static"
                            colBackground: toggled ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                            onClicked: { pickerContent.currentFilter = "Static"; view.forceActiveFocus(); }

                            StyledText {
                                anchors.centerIn: parent
                                text: "Static"
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: parent.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                            }
                        }

                        RippleButton {
                            implicitWidth: 64 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            toggled: pickerContent.currentFilter === "Live"
                            colBackground: toggled ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                            onClicked: { pickerContent.currentFilter = "Live"; view.forceActiveFocus(); }

                            StyledText {
                                anchors.centerIn: parent
                                text: "Live"
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: parent.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                            }
                        }

                        // --- Real-time Search Input Pill ---
                        Rectangle {
                            height: 38 * Appearance.effectiveScale
                            width: 220 * Appearance.effectiveScale
                            radius: 19 * Appearance.effectiveScale
                            color: Appearance.colors.colLayer1
                            border.color: searchInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.colors.colOutlineVariant
                            border.width: 1
                            clip: true

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10 * Appearance.effectiveScale
                                anchors.rightMargin: 10 * Appearance.effectiveScale
                                spacing: 6 * Appearance.effectiveScale

                                MaterialSymbol {
                                    text: "search"
                                    iconSize: 18 * Appearance.effectiveScale
                                    color: Appearance.colors.colSubtext
                                }

                                TextInput {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.family: Appearance.font.family.main
                                    clip: true
                                    onTextChanged: pickerContent.searchQuery = text
                                    onAccepted: view.forceActiveFocus()
                                    Keys.onReturnPressed: (event) => { view.forceActiveFocus(); event.accepted = true; }
                                    Keys.onEnterPressed: (event) => { view.forceActiveFocus(); event.accepted = true; }

                                    StyledText {
                                        anchors.fill: parent
                                        text: "Search..."
                                        color: Appearance.colors.colSubtext
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.family: Appearance.font.family.main
                                        visible: !searchInput.text && !searchInput.activeFocus
                                    }
                                }

                                RippleButton {
                                    visible: searchInput.text !== ""
                                    implicitWidth: 24 * Appearance.effectiveScale
                                    implicitHeight: 24 * Appearance.effectiveScale
                                    buttonRadius: 12 * Appearance.effectiveScale
                                    colBackground: "transparent"
                                    onClicked: { searchInput.text = ""; pickerContent.searchQuery = ""; }

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        iconSize: 14 * Appearance.effectiveScale
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }
                        }

                        // --- Close Button ---
                        RippleButton {
                            implicitWidth: 36 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: GlobalStates.carouselWallpaperPickerOpen = false

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: 20 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }
                            StyledToolTip { text: "Close (ESC)" }
                        }
                    }
                }

                Connections {
                    target: WallpaperEngineService
                    function onLoadingChanged() {
                        if (!WallpaperEngineService.loading) {
                            pickerContent.syncLocalModel();
                        }
                    }
                }

                Component.onCompleted: {
                    Wallpapers.refreshRecursiveWallpapers();
                    if (WallpaperEngineService.results.count === 0 && !WallpaperEngineService.loading) {
                        WallpaperEngineService.fetch();
                    }
                    pickerContent.syncLocalModel();
                    pickerContent.loadMonitors();
                    view.forceActiveFocus();
                    Qt.callLater(pickerContent.selectCurrentWallpaper);
                }
            }
        }
    }
}
