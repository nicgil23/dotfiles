import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../core"
import "../../services"
import "../../widgets"

/**
 * Dropzone Notch Popup HUD Content.
 * Displays stashed files, quick batch actions (Grab All 75% width - text only, Clear All, Transformations, Send to Mobile),
 * and expandable transformation options with animated open/close transitions and output destination selection.
 */
ColumnLayout {
    id: root

    property string selectedTransformId: ""
    property string selectedTransformLabel: ""
    property bool transformationsOpen: false

    readonly property bool hasImage: DropzoneService.stashedFiles.some(f => f.isImage)
    readonly property bool hasVideo: DropzoneService.stashedFiles.some(f => f.isVideo)
    readonly property bool hasArchive: DropzoneService.stashedFiles.some(f => f.isArchive)
    readonly property bool hasNonArchive: DropzoneService.stashedFiles.some(f => !f.isArchive)

    property bool trashAnimActive: false

    Timer {
        id: trashAnimTimer
        interval: 280
        repeat: false
        onTriggered: {
            root.trashAnimActive = false
            DropzoneService.clearAll()
        }
    }

    readonly property var categorizedTransforms: {
        let list = []
        if (hasImage) {
            list.push({
                title: "IMAGES",
                items: [
                    { id: "png", label: "PNG" },
                    { id: "jpg", label: "JPG" },
                    { id: "webp", label: "WEBP" },
                    { id: "svg", label: "SVG" },
                    { id: "exif", label: "Clean EXIF" }
                ]
            })
        }
        if (hasVideo) {
            list.push({
                title: "VIDEO",
                items: [
                    { id: "gif", label: "GIF" },
                    { id: "webm", label: "WEBM" },
                    { id: "mp3", label: "MP3" }
                ]
            })
        }
        let archiveItems = []
        if (hasNonArchive) {
            archiveItems.push({ id: "zip", label: "ZIP" })
            archiveItems.push({ id: "targz", label: "TAR.GZ" })
            archiveItems.push({ id: "7z", label: "7Z" })
        }
        if (hasArchive) {
            archiveItems.push({ id: "extract", label: "Extract" })
        }
        if (archiveItems.length > 0) {
            list.push({
                title: "FILES",
                items: archiveItems
            })
        }
        return list
    }

    Connections {
        target: DropzoneService
        function onFilesUpdated() {
            root.selectedTransformId = ""
            root.selectedTransformLabel = ""
            root.transformationsOpen = false
        }
    }

    function executeTransform(transformId, dest) {
        if (!DropzoneService.hasFiles) return

        let count = 0
        let pathsToRemove = []
        let outPathsToAdd = []
        let cmds = []

        if (transformId === "png" || transformId === "jpg" || transformId === "webp") {
            let imgs = DropzoneService.stashedFiles.filter(f => f.isImage)
            count = imgs.length
            pathsToRemove = imgs.map(f => f.path)
            for (let i = 0; i < imgs.length; i++) {
                let dir = DropzoneService.getFileDir(imgs[i].path)
                let nameWithoutExt = DropzoneService.getFileName(imgs[i].path).replace(/\.[^/.]+$/, "")
                let outPath = dir + "/" + nameWithoutExt + "_converted." + transformId.toLowerCase()
                cmds.push(`magick "${imgs[i].path}" "${outPath}"`)
                outPathsToAdd.push(outPath)
            }
        } else if (transformId === "svg") {
            let imgs = DropzoneService.stashedFiles.filter(f => f.isImage)
            count = imgs.length
            pathsToRemove = imgs.map(f => f.path)
            for (let i = 0; i < imgs.length; i++) {
                let dir = DropzoneService.getFileDir(imgs[i].path)
                let nameWithoutExt = DropzoneService.getFileName(imgs[i].path).replace(/\.[^/.]+$/, "")
                let outPath = dir + "/" + nameWithoutExt + "_vector." + transformId.toLowerCase()
                cmds.push(`magick "${imgs[i].path}" pnm:- | potrace -s -o "${outPath}"`)
                outPathsToAdd.push(outPath)
            }
        } else if (transformId === "exif") {
            let imgs = DropzoneService.stashedFiles.filter(f => f.isImage)
            count = imgs.length
            pathsToRemove = imgs.map(f => f.path)
            for (let i = 0; i < imgs.length; i++) {
                let dir = DropzoneService.getFileDir(imgs[i].path)
                let ext = DropzoneService.getFileExt(DropzoneService.getFileName(imgs[i].path))
                let nameWithoutExt = DropzoneService.getFileName(imgs[i].path).replace(/\.[^/.]+$/, "")
                let outPath = dir + "/" + nameWithoutExt + "_clean." + ext
                cmds.push(`magick "${imgs[i].path}" -strip "${outPath}"`)
                outPathsToAdd.push(outPath)
            }
        } else if (transformId === "gif" || transformId === "mp3" || transformId === "webm") {
            let vids = DropzoneService.stashedFiles.filter(f => f.isVideo)
            count = vids.length
            pathsToRemove = vids.map(f => f.path)
            for (let i = 0; i < vids.length; i++) {
                let dir = DropzoneService.getFileDir(vids[i].path)
                let nameWithoutExt = DropzoneService.getFileName(vids[i].path).replace(/\.[^/.]+$/, "")
                let outPath = dir + "/" + nameWithoutExt + "_converted." + transformId.toLowerCase()
                cmds.push(`ffmpeg -y -i "${vids[i].path}" "${outPath}"`)
                outPathsToAdd.push(outPath)
            }
        } else if (transformId === "zip" || transformId === "targz" || transformId === "7z") {
            let paths = DropzoneService.stashedFiles.map(f => f.path)
            count = paths.length
            pathsToRemove = paths
            let firstDir = DropzoneService.getFileDir(paths[0])
            let ext = transformId === "targz" ? "tar.gz" : transformId
            let outPath = firstDir + "/isla_archive." + ext
            let pathsStr = paths.map(p => `"${p}"`).join(" ")
            let zipCmd = transformId === "targz"
                ? `tar -czvf "${outPath}" ${pathsStr}`
                : (transformId === "7z" ? `7z a "${outPath}" ${pathsStr}` : `zip -j "${outPath}" ${pathsStr}`)
            cmds.push(zipCmd)
            outPathsToAdd.push(outPath)
        } else if (transformId === "extract") {
            let archs = DropzoneService.stashedFiles.filter(f => f.isArchive)
            count = archs.length
            pathsToRemove = archs.map(f => f.path)
            for (let i = 0; i < archs.length; i++) {
                let dir = DropzoneService.getFileDir(archs[i].path)
                let nameWithoutExt = DropzoneService.getFileName(archs[i].path).replace(/\.[^/.]+$/, "").replace(/\.tar$/, "")
                let outDir = dir + "/" + nameWithoutExt + "_extracted"
                let extCmd = `mkdir -p "${outDir}" && 7z x "${archs[i].path}" -o"${outDir}" -y`
                cmds.push(extCmd)
                outPathsToAdd.push(outDir)
            }
        }

        root.selectedTransformId = ""
        root.selectedTransformLabel = ""
        root.transformationsOpen = false

        if (cmds.length > 0) {
            let fullCmd = cmds.join(" && ")
            DropzoneService.runTransformationCmd(fullCmd, pathsToRemove, outPathsToAdd, dest)
        }

        if (dest === "kdeconnect") {
            GlobalStates.dropzoneNotchOpen = false
        }
    }

    // ── 1. HEADER ──
    Item {
        Layout.fillWidth: true
        implicitHeight: 28 * Appearance.effectiveScale

        StyledText {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: {
                let parts = []
                if (DropzoneService.fileCount > 0) {
                    parts.push(DropzoneService.fileCount + (DropzoneService.fileCount === 1 ? " file" : " files"))
                }
                if (DropzoneService.folderCount > 0) {
                    parts.push(DropzoneService.folderCount + (DropzoneService.folderCount === 1 ? " folder" : " folders"))
                }
                return parts.length > 0 ? parts.join(", ") : "0 files"
            }
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Normal
            color: Appearance.colors.colNotchText
        }

        // Close Button ('X')
        Item {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 24 * Appearance.effectiveScale
            height: 24 * Appearance.effectiveScale

            MaterialSymbol {
                anchors.centerIn: parent
                text: "close"
                iconSize: 18 * Appearance.effectiveScale
                color: Appearance.colors.colNotchText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: GlobalStates.dropzoneNotchOpen = false
            }
        }
    }

    // ── 2. FILE GRID / STASH VIEW ──
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: DropzoneService.hasFiles ? Math.min(220 * Appearance.effectiveScale, Math.max(90 * Appearance.effectiveScale, Math.ceil(DropzoneService.stashedFiles.length / 3) * 75 * Appearance.effectiveScale)) : 80 * Appearance.effectiveScale

        // Empty state message
        ColumnLayout {
            anchors.centerIn: parent
            visible: !DropzoneService.hasFiles
            spacing: 4 * Appearance.effectiveScale

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "download_for_offline"
                iconSize: 32 * Appearance.effectiveScale
                color: Qt.rgba(1, 1, 1, 0.4)
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Drag files here or send them from Yazi with º"
                font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                color: Qt.rgba(1, 1, 1, 0.5)
            }
        }

        // Files list / grid
        ScrollView {
            anchors.fill: parent
            visible: DropzoneService.hasFiles
            clip: true
            opacity: root.trashAnimActive ? 0.0 : 1.0
            scale: root.trashAnimActive ? 0.85 : 1.0
            transformOrigin: Item.BottomRight

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutBack
                }
            }

            GridView {
                id: gridView
                anchors.fill: parent
                cellWidth: gridView.width / 3
                cellHeight: 65 * Appearance.effectiveScale
                model: DropzoneService.stashedFiles

                delegate: Item {
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3 * Appearance.effectiveScale
                        color: itemHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        radius: 8 * Appearance.effectiveScale

                        HoverHandler { id: itemHover }
                        property bool wasItemDragging: false

                        Item {
                            id: dragPreviewContainer
                            x: -9999
                            y: -9999
                            width: Math.round(48 * Appearance.effectiveScale)
                            height: Math.round(48 * Appearance.effectiveScale)
                            visible: true

                            Image {
                                id: dragPreviewImg
                                anchors.fill: parent
                                source: {
                                    if (modelData.isImage) return "file://" + modelData.path
                                    if (modelData.isDir) return Quickshell.iconPath("folder", "inode-directory")
                                    if (modelData.isVideo) return Quickshell.iconPath("video-x-generic", "video")
                                    if (modelData.isAudio) return Quickshell.iconPath("audio-x-generic", "audio")
                                    if (modelData.isArchive) return Quickshell.iconPath("package-x-generic", "folder-zip")
                                    return Quickshell.iconPath("text-x-generic", "document")
                                }
                                fillMode: modelData.isImage ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                mipmap: true
                                onStatusChanged: {
                                    if (status === Image.Ready) {
                                        dragPreviewContainer.grabToImage(function(result) {
                                            dragTarget.Drag.imageSource = result.url
                                        })
                                    }
                                }
                            }
                        }

                        Item {
                            id: dragTarget
                            anchors.fill: parent
                            Drag.active: itemMouseArea.drag.active
                            Drag.dragType: Drag.Automatic
                            Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
                            Drag.mimeData: {
                                "text/uri-list": "file://" + modelData.path
                            }
                            Drag.imageSource: {
                                if (modelData.isImage) return "file://" + modelData.path
                                if (modelData.isDir) return Quickshell.iconPath("folder", "inode-directory")
                                if (modelData.isVideo) return Quickshell.iconPath("video-x-generic", "video")
                                if (modelData.isAudio) return Quickshell.iconPath("audio-x-generic", "audio")
                                if (modelData.isArchive) return Quickshell.iconPath("package-x-generic", "folder-zip")
                                return Quickshell.iconPath("text-x-generic", "document")
                            }
                            Drag.hotSpot.x: Math.round(24 * Appearance.effectiveScale)
                            Drag.hotSpot.y: Math.round(24 * Appearance.effectiveScale)
                            Drag.onDragFinished: (dropAction) => {
                                DropzoneService.removeFile(index)
                            }
                        }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.OpenHandCursor
                            drag.target: dragTarget
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            drag.onActiveChanged: {
                                if (drag.active) {
                                    wasItemDragging = true
                                    dragPreviewContainer.grabToImage(function(result) {
                                        dragTarget.Drag.imageSource = result.url
                                    })
                                } else if (wasItemDragging) {
                                    wasItemDragging = false
                                    dragTarget.x = 0
                                    dragTarget.y = 0
                                    if (!containsMouse) {
                                        DropzoneService.removeFile(index)
                                    }
                                }
                            }
                            onReleased: {
                                dragTarget.x = 0
                                dragTarget.y = 0
                            }
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    DropzoneService.openFile(modelData.path, modelData.isDir)
                                } else if (mouse.button === Qt.MiddleButton) {
                                    DropzoneService.copyPath(modelData.path)
                                } else if (mouse.button === Qt.RightButton) {
                                    DropzoneService.removeFile(index)
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4 * Appearance.effectiveScale
                            spacing: 6 * Appearance.effectiveScale

                            // Icon / Thumbnail
                            Item {
                                width: 32 * Appearance.effectiveScale
                                height: 32 * Appearance.effectiveScale

                                Image {
                                    id: imgThumb
                                    anchors.fill: parent
                                    source: modelData.isImage ? "file://" + modelData.path : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: modelData.isImage && status === Image.Ready
                                    mipmap: true
                                }

                                Image {
                                    id: themeIcon
                                    anchors.fill: parent
                                    anchors.margins: 2 * Appearance.effectiveScale
                                    source: {
                                        if (modelData.isImage) return ""
                                        if (modelData.isDir) return Quickshell.iconPath("folder", "inode-directory")
                                        if (modelData.isVideo) return Quickshell.iconPath("video-x-generic", "video")
                                        if (modelData.isAudio) return Quickshell.iconPath("audio-x-generic", "audio")
                                        if (modelData.isArchive) return Quickshell.iconPath("package-x-generic", "folder-zip")
                                        return Quickshell.iconPath("text-x-generic", "document")
                                    }
                                    fillMode: Image.PreserveAspectFit
                                    visible: !modelData.isImage && status === Image.Ready
                                    mipmap: true
                                }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: modelData.isDir ? "folder" : (modelData.isImage ? "image" : (modelData.isVideo ? "movie" : (modelData.isAudio ? "audiotrack" : (modelData.isArchive ? "folder_zip" : "description"))))
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: Qt.rgba(1, 1, 1, 0.85)
                                    visible: !modelData.isImage ? (themeIcon.status !== Image.Ready) : (imgThumb.status !== Image.Ready)
                                }
                            }

                            // File details
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1 * Appearance.effectiveScale

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                                    font.weight: Font.DemiBold
                                    color: "#FFFFFF"
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    text: modelData.isDir ? "FOLDER" : modelData.ext.toUpperCase()
                                    font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 3. ACTIONS & TRANSFORMATIONS SECTION ──
    ColumnLayout {
        Layout.fillWidth: true
        visible: DropzoneService.hasFiles
        spacing: 8 * Appearance.effectiveScale

        // ── ROW 1: BATCH ACTIONS BAR (Agarrar Todos 75% + 3 Icon Buttons) ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale

            // 1. "Agarrar Todos (N)" Unified Textured Bar
            Rectangle {
                id: grabAllCard
                Layout.fillWidth: true
                Layout.preferredWidth: 8
                implicitHeight: 36 * Appearance.effectiveScale
                radius: 10 * Appearance.effectiveScale
                color: grabAllHover.hovered ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)
                border.color: grabAllHover.hovered ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.1)
                border.width: 1

                HoverHandler { id: grabAllHover }

                Item {
                    id: grabAllPreviewContainer
                    x: -9999
                    y: -9999
                    width: Math.round(72 * Appearance.effectiveScale)
                    height: Math.round(72 * Appearance.effectiveScale)
                    visible: true

                    Repeater {
                        model: DropzoneService.stashedFiles
                        delegate: Item {
                            width: Math.round(32 * Appearance.effectiveScale)
                            height: Math.round(32 * Appearance.effectiveScale)

                            property real centerX: 20 * Appearance.effectiveScale
                            property real centerY: 20 * Appearance.effectiveScale
                            property real scatterRadius: Math.min(18, 4 + index * 2.5) * Appearance.effectiveScale
                            property real angle: index * 2.39996
                            property real rotAngle: ((index * 29) % 36) - 18

                            x: Math.round(centerX + Math.cos(angle) * scatterRadius)
                            y: Math.round(centerY + Math.sin(angle) * scatterRadius)
                            rotation: rotAngle
                            z: index

                            Image {
                                anchors.fill: parent
                                source: {
                                    if (modelData.isImage) return "file://" + modelData.path
                                    if (modelData.isDir) return Quickshell.iconPath("folder", "inode-directory")
                                    if (modelData.isVideo) return Quickshell.iconPath("video-x-generic", "video")
                                    if (modelData.isAudio) return Quickshell.iconPath("audio-x-generic", "audio")
                                    if (modelData.isArchive) return Quickshell.iconPath("package-x-generic", "folder-zip")
                                    return Quickshell.iconPath("text-x-generic", "document")
                                }
                                fillMode: modelData.isImage ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                mipmap: true
                            }
                        }
                    }
                }

                Item {
                    id: grabAllDragTarget
                    anchors.fill: parent
                    Drag.active: grabAllMouseArea.drag.active
                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
                    Drag.mimeData: {
                        "text/uri-list": DropzoneService.stashedFiles.map(f => "file://" + f.path).join("\r\n")
                    }
                    Drag.hotSpot.x: Math.round(36 * Appearance.effectiveScale)
                    Drag.hotSpot.y: Math.round(36 * Appearance.effectiveScale)
                    Drag.onDragFinished: (dropAction) => {
                        DropzoneService.clearAll()
                    }
                }

                property bool wasGrabAllDragging: false

                MouseArea {
                    id: grabAllMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.OpenHandCursor
                    drag.target: grabAllDragTarget
                    onPressed: {
                        grabAllPreviewContainer.grabToImage(function(result) {
                            grabAllDragTarget.Drag.imageSource = result.url
                        })
                    }
                    drag.onActiveChanged: {
                        if (drag.active) {
                            wasGrabAllDragging = true
                            grabAllPreviewContainer.grabToImage(function(result) {
                                grabAllDragTarget.Drag.imageSource = result.url
                            })
                        } else if (wasGrabAllDragging) {
                            wasGrabAllDragging = false
                            grabAllDragTarget.x = 0
                            grabAllDragTarget.y = 0
                            if (!containsMouse) {
                                DropzoneService.clearAll()
                            }
                        }
                    }
                    onReleased: {
                        grabAllDragTarget.x = 0
                        grabAllDragTarget.y = 0
                    }
                    onClicked: DropzoneService.grabAllFiles()
                }

                StyledText {
                    anchors.centerIn: parent
                    text: "Grab All (" + DropzoneService.stashedFiles.length + ")"
                    font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                    font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.9)
                    elide: Text.ElideRight
                }
            }

            // 2. Clear All (Trash icon with original pop & shake animation)
            MaterialSymbol {
                id: trashIcon
                text: "delete"
                iconSize: 20 * Appearance.effectiveScale
                color: root.trashAnimActive ? "#ff4d4d" : (clearHover.hovered ? "#ff6b6b" : Qt.rgba(1, 1, 1, 0.5))
                scale: root.trashAnimActive ? 1.35 : 1.0
                rotation: root.trashAnimActive ? -25 : 0

                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on rotation {
                    SequentialAnimation {
                        NumberAnimation { to: -20; duration: 60 }
                        NumberAnimation { to: 20; duration: 60 }
                        NumberAnimation { to: -10; duration: 50 }
                        NumberAnimation { to: 0; duration: 70 }
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                MouseArea {
                    id: clearHoverArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    HoverHandler { id: clearHover }
                    onClicked: {
                        if (trashAnimTimer.running) return
                        root.trashAnimActive = true
                        trashAnimTimer.start()
                    }
                }
            }

            // 3. Transformations Toggle (Tune icon with rotation animation)
            MaterialSymbol {
                id: tuneIcon
                text: root.transformationsOpen ? "close" : "tune"
                iconSize: 20 * Appearance.effectiveScale
                color: tuneHover.hovered ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.5)
                rotation: root.transformationsOpen ? 180 : 0

                Behavior on rotation {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    HoverHandler { id: tuneHover }
                    onClicked: {
                        root.transformationsOpen = !root.transformationsOpen
                        if (!root.transformationsOpen) {
                            root.selectedTransformId = ""
                            root.selectedTransformLabel = ""
                        }
                    }
                }
            }

            // 4. Send to Mobile (Phonelink icon)
            MaterialSymbol {
                text: "phonelink"
                iconSize: 20 * Appearance.effectiveScale
                color: mobileHover.hovered ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.5)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    HoverHandler { id: mobileHover }
                    onClicked: {
                        if (DropzoneService.stashedFiles.length > 0) {
                            let paths = DropzoneService.stashedFiles.map(f => f.path)
                            DropzoneService.sendToKdeConnect(paths)
                            GlobalStates.dropzoneNotchOpen = false
                        }
                    }
                }
            }
        }

        // ── ROW 2: UNIFIED TRANSFORMATIONS BAR (Clean Container without Individual Capsules) ──
        Item {
            id: transformationsContainer
            Layout.fillWidth: true
            clip: true

            readonly property bool isExpanded: root.transformationsOpen

            implicitHeight: isExpanded ? innerContent.implicitHeight : 0
            opacity: isExpanded ? 1.0 : 0.0

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                id: innerContent
                width: parent.width
                spacing: 6 * Appearance.effectiveScale

                // Categorized Options (Floating layout without outer big capsule container)
                ColumnLayout {
                    id: catColumn
                    Layout.fillWidth: true
                    Layout.topMargin: 8 * Appearance.effectiveScale
                    spacing: 6 * Appearance.effectiveScale
                    visible: root.transformationsOpen

                    Repeater {
                        model: root.categorizedTransforms
                        delegate: RowLayout {
                            id: catRow
                            property var categoryData: modelData
                            Layout.fillWidth: true
                            spacing: 10 * Appearance.effectiveScale

                            // Category Label (e.g. IMÁGENES, VÍDEO, ARCHIVOS)
                            StyledText {
                                text: categoryData.title
                                font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                                font.weight: Font.Bold
                                color: Qt.rgba(1, 1, 1, 0.35)
                                Layout.preferredWidth: 68 * Appearance.effectiveScale
                            }

                            // Actions text list
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6 * Appearance.effectiveScale

                                Repeater {
                                    model: categoryData.items
                                    delegate: RowLayout {
                                        spacing: 6 * Appearance.effectiveScale

                                        Rectangle {
                                            implicitWidth: itemText.implicitWidth + 12 * Appearance.effectiveScale
                                            implicitHeight: 22 * Appearance.effectiveScale
                                            radius: 4 * Appearance.effectiveScale
                                            color: root.selectedTransformId === modelData.id ? Qt.rgba(1, 1, 1, 0.15) : (txHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

                                            HoverHandler { id: txHover }

                                            StyledText {
                                                id: itemText
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                                                font.weight: root.selectedTransformId === modelData.id ? Font.DemiBold : Font.Normal
                                                color: root.selectedTransformId === modelData.id ? "#FFFFFF" : (txHover.hovered ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.55))
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.selectedTransformId = modelData.id
                                                    root.selectedTransformLabel = modelData.label
                                                }
                                            }
                                        }

                                        StyledText {
                                            text: "•"
                                            font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                                            color: Qt.rgba(1, 1, 1, 0.2)
                                            visible: index < catRow.categoryData.items.length - 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Destination Selection (Save to:)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4 * Appearance.effectiveScale
                    spacing: 10 * Appearance.effectiveScale
                    visible: root.transformationsOpen && root.selectedTransformId !== ""

                    // Category Label
                    StyledText {
                        text: "SAVE TO"
                        font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                        font.weight: Font.Bold
                        color: Qt.rgba(1, 1, 1, 0.35)
                        Layout.preferredWidth: 68 * Appearance.effectiveScale
                    }

                    // Destination Options
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 * Appearance.effectiveScale

                        Rectangle {
                            implicitWidth: origText.implicitWidth + 12 * Appearance.effectiveScale
                            implicitHeight: 22 * Appearance.effectiveScale
                            radius: 4 * Appearance.effectiveScale
                            color: origHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                            HoverHandler { id: origHover }

                            StyledText {
                                id: origText
                                anchors.centerIn: parent
                                text: "Original Folder"
                                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                                font.weight: Font.Normal
                                color: origHover.hovered ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.55)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.executeTransform(root.selectedTransformId, "local")
                            }
                        }

                        StyledText {
                            text: "•"
                            font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                            color: Qt.rgba(1, 1, 1, 0.2)
                        }

                        Rectangle {
                            implicitWidth: mobText.implicitWidth + 12 * Appearance.effectiveScale
                            implicitHeight: 22 * Appearance.effectiveScale
                            radius: 4 * Appearance.effectiveScale
                            color: destMobHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                            HoverHandler { id: destMobHover }

                            StyledText {
                                id: mobText
                                anchors.centerIn: parent
                                text: "Mobile (KDE Connect)"
                                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                                font.weight: Font.Normal
                                color: destMobHover.hovered ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.55)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.executeTransform(root.selectedTransformId, "kdeconnect")
                            }
                        }
                    }
                }
            }
        }
    }
}
