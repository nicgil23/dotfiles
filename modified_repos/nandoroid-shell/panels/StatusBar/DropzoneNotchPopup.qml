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

    readonly property var availableTransforms: {
        let list = []
        if (hasImage) {
            list.push({ id: "png", label: "PNG" })
            list.push({ id: "jpg", label: "JPG" })
            list.push({ id: "webp", label: "WEBP" })
            list.push({ id: "exif", label: "Clean EXIF" })
        }
        if (hasVideo) {
            list.push({ id: "gif", label: "MP4 → GIF" })
            list.push({ id: "mp3", label: "MP4 → MP3" })
        }
        list.push({ id: "zip", label: "ZIP" })
        list.push({ id: "targz", label: "TAR.GZ" })
        if (hasArchive) {
            list.push({ id: "extract", label: "Extract Archive" })
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

        let count = DropzoneService.stashedFiles.length || 1

        if (transformId === "png" || transformId === "jpg" || transformId === "webp") {
            let img = DropzoneService.stashedFiles.find(f => f.isImage)
            if (img) DropzoneService.convertImage(img.path, transformId, dest)
        } else if (transformId === "exif") {
            let img = DropzoneService.stashedFiles.find(f => f.isImage)
            if (img) DropzoneService.cleanExif(img.path, dest)
        } else if (transformId === "gif" || transformId === "mp3") {
            let vid = DropzoneService.stashedFiles.find(f => f.isVideo)
            if (vid) DropzoneService.convertVideo(vid.path, transformId, dest)
        } else if (transformId === "zip") {
            let paths = DropzoneService.stashedFiles.map(f => f.path)
            DropzoneService.compressArchive(paths, "zip", dest)
        } else if (transformId === "targz") {
            let paths = DropzoneService.stashedFiles.map(f => f.path)
            DropzoneService.compressArchive(paths, "tar.gz", dest)
        } else if (transformId === "extract") {
            let arch = DropzoneService.stashedFiles.find(f => f.isArchive)
            if (arch) DropzoneService.decompressArchive(arch.path, dest)
        }

        root.selectedTransformId = ""
        root.selectedTransformLabel = ""
        root.transformationsOpen = false

        if (dest === "kdeconnect") {
            GlobalStates.dropzoneNotchOpen = false
            let notifCmd = `sleep 0.75 && notify-send -a "KDE Connect" "KDE Connect" "Has subido ${count} ${count === 1 ? "archivo" : "archivos"}"`
            Quickshell.execDetached(["bash", "-c", notifCmd])
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

        // Files grid
        ScrollView {
            anchors.fill: parent
            visible: DropzoneService.hasFiles
            clip: true

            GridView {
                id: gridView
                anchors.fill: parent
                cellWidth: gridView.width / 3
                cellHeight: 70 * Appearance.effectiveScale
                model: DropzoneService.stashedFiles

                delegate: Item {
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4 * Appearance.effectiveScale
                        color: itemHover.hovered ? Appearance.colors.colLayer2 : Qt.rgba(1, 1, 1, 0.08)
                        radius: 8 * Appearance.effectiveScale
                        border.color: itemHover.hovered ? Qt.rgba(1, 1, 1, 0.3) : "transparent"
                        border.width: 1

                        HoverHandler { id: itemHover }

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
                            Drag.hotSpot.x: 16 * Appearance.effectiveScale
                            Drag.hotSpot.y: 16 * Appearance.effectiveScale
                        }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.OpenHandCursor
                            drag.target: dragTarget
                            onReleased: {
                                dragTarget.x = 0
                                dragTarget.y = 0
                            }
                            onClicked: DropzoneService.grabFile(modelData.path)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6 * Appearance.effectiveScale
                            spacing: 6 * Appearance.effectiveScale

                            // Icon / Thumbnail
                            Item {
                                width: 34 * Appearance.effectiveScale
                                height: 34 * Appearance.effectiveScale

                                Image {
                                    anchors.fill: parent
                                    source: modelData.isImage ? "file://" + modelData.path : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: modelData.isImage && status === Image.Ready
                                    mipmap: true
                                }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: modelData.isDir ? "folder" : (modelData.isImage ? "image" : (modelData.isVideo ? "movie" : (modelData.isAudio ? "audiotrack" : (modelData.isArchive ? "folder_zip" : "description"))))
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: Appearance.colors.colNotchText
                                    visible: !modelData.isImage || (status !== Image.Ready)
                                }
                            }

                            // File details
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * Appearance.effectiveScale

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colNotchText
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    text: modelData.isDir ? "FOLDER" : modelData.ext.toUpperCase()
                                    font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                }
                            }

                            // Delete single file button
                            MaterialSymbol {
                                text: "close"
                                iconSize: 14 * Appearance.effectiveScale
                                color: Qt.rgba(1, 1, 1, 0.6)

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: DropzoneService.removeFile(index)
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
        spacing: 6 * Appearance.effectiveScale

        // ── ROW 1: BATCH ACTIONS (Grab All 75% width - text only, Clear All, Transformations, Send to Mobile) ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 6 * Appearance.effectiveScale

            // 1. "Grab All Files" Card (75% width, Text Only)
            Rectangle {
                id: grabAllCard
                Layout.fillWidth: true
                Layout.preferredWidth: 9
                implicitHeight: 34 * Appearance.effectiveScale
                radius: 8 * Appearance.effectiveScale
                color: grabAllHover.hovered ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.1)
                border.color: grabAllHover.hovered ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.15)
                border.width: 1

                HoverHandler { id: grabAllHover }

                Item {
                    id: grabAllDragTarget
                    anchors.fill: parent
                    Drag.active: grabAllMouseArea.drag.active
                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
                    Drag.mimeData: {
                        "text/uri-list": DropzoneService.stashedFiles.map(f => "file://" + f.path).join("\r\n")
                    }
                    Drag.hotSpot.x: 16 * Appearance.effectiveScale
                    Drag.hotSpot.y: 16 * Appearance.effectiveScale
                }

                MouseArea {
                    id: grabAllMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.OpenHandCursor
                    drag.target: grabAllDragTarget
                    onReleased: {
                        grabAllDragTarget.x = 0
                        grabAllDragTarget.y = 0
                    }
                    onClicked: DropzoneService.grabAllFiles()
                }

                StyledText {
                    anchors.centerIn: parent
                    text: "Grab All Files (" + DropzoneService.stashedFiles.length + ")"
                    font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                    font.weight: Font.Bold
                    color: Appearance.colors.colNotchText
                    elide: Text.ElideRight
                }
            }

            // 2. "Clear All" Icon Button (Trash icon delete_sweep)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 34 * Appearance.effectiveScale
                radius: 8 * Appearance.effectiveScale
                color: clearHover.hovered ? Qt.rgba(0.9, 0.2, 0.2, 0.3) : Qt.rgba(1, 1, 1, 0.08)
                border.color: clearHover.hovered ? Qt.rgba(0.9, 0.2, 0.2, 0.5) : Qt.rgba(1, 1, 1, 0.12)
                border.width: 1

                HoverHandler { id: clearHover }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "delete_sweep"
                    iconSize: 18 * Appearance.effectiveScale
                    color: clearHover.hovered ? "#ff6b6b" : Qt.rgba(1, 1, 1, 0.8)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DropzoneService.clearAll()
                }
            }

            // 3. Transformations Icon Button (Icon: "tune")
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 34 * Appearance.effectiveScale
                radius: 8 * Appearance.effectiveScale
                color: root.transformationsOpen ? Qt.rgba(1, 1, 1, 0.25) : (plusHover.hovered ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.1))
                border.color: root.transformationsOpen ? Appearance.colors.colAccent : (plusHover.hovered ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.15))
                border.width: 1

                HoverHandler { id: plusHover }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.transformationsOpen ? "close" : "tune"
                    iconSize: 18 * Appearance.effectiveScale
                    color: root.transformationsOpen ? Appearance.colors.colAccent : Qt.rgba(1, 1, 1, 0.8)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.transformationsOpen = !root.transformationsOpen
                }
            }

            // 4. "Send to Mobile" Icon Button (Icon: "phonelink")
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 34 * Appearance.effectiveScale
                radius: 8 * Appearance.effectiveScale
                color: mobileHover.hovered ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.1)
                border.color: mobileHover.hovered ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.15)
                border.width: 1

                HoverHandler { id: mobileHover }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "phonelink"
                    iconSize: 18 * Appearance.effectiveScale
                    color: mobileHover.hovered ? Appearance.colors.colAccent : Qt.rgba(1, 1, 1, 0.8)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (DropzoneService.stashedFiles.length > 0) {
                            let count = DropzoneService.stashedFiles.length
                            DropzoneService.sendToKdeConnect(DropzoneService.stashedFiles[0].path)
                            GlobalStates.dropzoneNotchOpen = false
                            let notifCmd = `sleep 0.75 && notify-send -a "KDE Connect" "KDE Connect" "Has subido ${count} ${count === 1 ? "archivo" : "archivos"}"`
                            Quickshell.execDetached(["bash", "-c", notifCmd])
                        }
                    }
                }
            }
        }

        // ── ROW 2 / SECTION 4: TRANSFORMATIONS OPTIONS & DESTINATION SELECTOR WITH SMOOTH TRANSITION ──
        Item {
            id: transformationsContainer
            Layout.fillWidth: true
            clip: true

            readonly property bool isExpanded: root.transformationsOpen || root.selectedTransformId !== ""

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

                // Expanded Transformation Options (Flow of chips)
                Flow {
                    Layout.fillWidth: true
                    spacing: 6 * Appearance.effectiveScale
                    visible: root.transformationsOpen

                    Repeater {
                        model: root.availableTransforms
                        delegate: Rectangle {
                            implicitWidth: itemText.implicitWidth + 20 * Appearance.effectiveScale
                            implicitHeight: 28 * Appearance.effectiveScale
                            radius: 6 * Appearance.effectiveScale
                            color: itemHover.hovered ? Qt.rgba(1, 1, 1, 0.22) : (root.selectedTransformId === modelData.id ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.1))
                            border.color: root.selectedTransformId === modelData.id ? Appearance.colors.colAccent : Qt.rgba(1, 1, 1, 0.15)
                            border.width: 1

                            HoverHandler { id: itemHover }

                            StyledText {
                                id: itemText
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                                font.weight: root.selectedTransformId === modelData.id ? Font.Bold : Font.Normal
                                color: Appearance.colors.colNotchText
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
                    }
                }

                // ── DESTINATION SELECTION (Original Folder vs Mobile) ──
                // Appears when a transformation option is selected!
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6 * Appearance.effectiveScale
                    visible: root.selectedTransformId !== ""

                    StyledText {
                        text: "Save to:"
                        font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                        font.weight: Font.Medium
                        color: Qt.rgba(1, 1, 1, 0.6)
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 30 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: origHover.hovered ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.12)
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        border.width: 1

                        HoverHandler { id: origHover }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Original Folder"
                            font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colNotchText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.executeTransform(root.selectedTransformId, "original")
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 30 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: destMobHover.hovered ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.12)
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        border.width: 1

                        HoverHandler { id: destMobHover }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Mobile"
                            font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colNotchText
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
