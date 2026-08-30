import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import Quickshell.Hyprland
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

/**
 * Universal Dynamic Island container for the status bar.
 * Unified Dropzone HUD with structured controls and Grab All capability.
 */
Item {
    id: root
    
    property HyprlandMonitor monitor
    property bool pomodoroActive: PomodoroService.isSessionRunning
    property real indicatorWidth: 52 * Appearance.effectiveScale 
    
    width: 0 
    height: 40 * Appearance.effectiveScale // Matches status bar height for safe rendering

    property string forcedStyle: ""
    readonly property string islandStyle: forcedStyle !== "" ? forcedStyle : (Config.options.statusBar && Config.options.statusBar.islandStyle !== undefined ? Config.options.statusBar.islandStyle : "pill")
    readonly property bool isWaterdrop: islandStyle === "waterdrop"
    readonly property bool isM3: islandStyle === "m3"
    property string indicatorStyle: "pill"

    // Expose the background pill for absolute anchoring
    property alias pill: backgroundPill

    property string destMode: "original" // "original" or "kdeconnect"
    readonly property bool hasImage: DropzoneService.stashedFiles.some(f => f.isImage)
    readonly property bool hasVideo: DropzoneService.stashedFiles.some(f => f.isVideo)
    readonly property bool hasArchive: DropzoneService.stashedFiles.some(f => f.isArchive)

    // Expand ears on hover without opening media notch
    function triggerMediaHover() {
        if (MprisController.activePlayer) {
            root.mediaShowing = true;
            mediaTimer.restart();
            if (GlobalStates.mediaNotchOpen) GlobalStates.stopMediaNotchTimer();
        }
    }

    // --- State Logic ---
    property string islandStateOverride: ""
    property bool mediaShowing: false
    Timer { id: mediaTimer; interval: 3000; onTriggered: root.mediaShowing = false }

    Connections {
        target: MprisController
        function onTrackTitleChanged() {
            if (MprisController.isPlaying && MprisController.trackTitle !== "No media") {
                root.mediaShowing = true; mediaTimer.restart()
            }
        }
        function onIsPlayingChanged() {
            if (MprisController.isPlaying && MprisController.trackTitle !== "No media") {
                root.mediaShowing = true; mediaTimer.restart()
            }
        }
    }

    readonly property string islandState: {
        if (islandStateOverride !== "") return islandStateOverride
        if (Notifications.activePopup) return "notification"
        if (ScreenRecord.active) return "recording"
        if ((mediaShowing || GlobalStates.mediaNotchOpen) && MprisController.activePlayer) return "media"
        if (pomodoroActive) return "pomodoro"
        return "idle"
    }

    // Media Width Synchronization Logic
    readonly property real mediaLeftNaturalWidth: {
        let w = 0
        if (mediaLogo.visible) w += (18 * Appearance.effectiveScale) + (6 * Appearance.effectiveScale)
        if (mediaArtistLabel.visible) w += mediaArtistLabel.implicitWidth + (4 * Appearance.effectiveScale)
        return w > 0 ? w + (4 * Appearance.effectiveScale) : 0
    }

    readonly property real mediaRightNaturalWidth: {
        return (mediaTitleLabel.visible && mediaTitleLabel.text !== "") ? mediaTitleLabel.implicitWidth + (12 * Appearance.effectiveScale) : 0
    }

    // Dynamic Max Width Logic - HUD mode is tighter because Clock/Date are centered
    readonly property real earMaxWidthNormal: 150 * Appearance.effectiveScale
    readonly property real earMaxWidthHud: 100 * Appearance.effectiveScale 
    readonly property real currentEarMaxWidth: (islandState === "idle") ? earMaxWidthNormal : earMaxWidthHud

    // Universal Ear Width Calculation for ALL States
    readonly property real leftNaturalWidth: {
        if (islandState === "notification") {
            let w = 0
            if (notifLogo.visible) w += (20 * Appearance.effectiveScale) + (6 * Appearance.effectiveScale)
            if (notifAppNameLabel.visible) w += Math.min(notifAppNameLabel.implicitWidth, 80 * Appearance.effectiveScale) + (4 * Appearance.effectiveScale)
            return w > 0 ? w + (4 * Appearance.effectiveScale) : 0
        }
        if (islandState === "recording") return 24 * Appearance.effectiveScale
        if (islandState === "media") return mediaLeftNaturalWidth
        if (islandState === "pomodoro") return pomoModeLabel.implicitWidth + (8 * Appearance.effectiveScale)
        return 0
    }
    
    readonly property real rightNaturalWidth: {
        if (islandState === "notification") return notifSummaryLabel.visible ? Math.min(notifSummaryLabel.implicitWidth, root.currentEarMaxWidth - (8 * Appearance.effectiveScale)) + (8 * Appearance.effectiveScale) : 0
        if (islandState === "recording") return recordTimeLabel.implicitWidth + (8 * Appearance.effectiveScale)
        if (islandState === "media") return mediaRightNaturalWidth
        if (islandState === "pomodoro") return pomoTimeLabel.implicitWidth + (8 * Appearance.effectiveScale)
        return 0
    }

    // Balanced Width Calculation - Forces symmetric expansion
    readonly property real sharedEarWidth: {
        if (islandState === "idle") return 0
        let maxNatural = Math.max(leftNaturalWidth, rightNaturalWidth)
        return Math.min(maxNatural, root.currentEarMaxWidth)
    }

    // Gap width: 0px in idle, tight 2px in active states (0 means ear flush with pill edge)
    readonly property real gapHalf: (indicatorWidth / 2) + (islandState === "idle" ? 0 : 8 * Appearance.effectiveScale)

    // --- LEFT EAR ---
    Item {
        id: leftEar
        anchors.right: root.left
        anchors.rightMargin: root.gapHalf
        y: 6 * Appearance.effectiveScale 
        height: 28 * Appearance.effectiveScale
        clip: true
        visible: !GlobalStates.dropzoneNotchOpen && backgroundPill.pillWidth <= backgroundPill.normalWidth + 10
        
        HoverHandler {
            enabled: islandState === "media"
            onHoveredChanged: {
                if (hovered && Config.options.media.enableMediaHover) {
                    GlobalStates.openMediaNotch(root.QsWindow.window.screen);
                } else {
                    GlobalStates.closeMediaNotchWithDelay();
                }
            }
        }
        
        width: root.sharedEarWidth

        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on anchors.rightMargin { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        // Container for notification content - centered
        Row {
            anchors.centerIn: parent
            visible: islandState === "notification"
            spacing: 6 * Appearance.effectiveScale
            NotificationAppIcon {
                id: notifLogo
                width: 18 * Appearance.effectiveScale; height: 18 * Appearance.effectiveScale; implicitSize: 18 * Appearance.effectiveScale
                visible: islandState === "notification"
                opacity: parent.parent.width > (24 * Appearance.effectiveScale) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                appIcon: Notifications.activePopup?.appIcon || (islandStateOverride !== "" ? "chat" : "")
                appName: Notifications.activePopup?.appName || ""
                image: Notifications.activePopup?.image || ""
                summary: Notifications.activePopup?.summary || (islandStateOverride !== "" ? "New Message" : "")
                urgency: Notifications.activePopup?.urgency || "normal"
                color: "transparent"
            }
            StyledText {
                id: notifAppNameLabel
                text: Notifications.activePopup?.appName || (islandStateOverride !== "" ? "Messages" : "Notification")
                visible: islandState === "notification"
                opacity: parent.parent.width > (30 * Appearance.effectiveScale) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                font.pixelSize: Math.round(12 * Appearance.effectiveScale); font.weight: Font.Medium
                color: Appearance.colors.colNotchText
                width: Math.min(implicitWidth, root.currentEarMaxWidth - (notifLogo.visible ? 28 * Appearance.effectiveScale : 8 * Appearance.effectiveScale))
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Recording Icon - centered
        Item {
            anchors.centerIn: parent
            visible: islandState === "recording"
            opacity: parent.width > (12 * Appearance.effectiveScale) ? 1 : 0
            width: 16 * Appearance.effectiveScale; height: 16 * Appearance.effectiveScale
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MaterialSymbol {
                id: recordIcon; anchors.centerIn: parent; text: "screen_record"; iconSize: 16 * Appearance.effectiveScale
                color: Appearance.m3colors.m3error; fill: 1
                SequentialAnimation on opacity {
                    running: recordIcon.visible; loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.3; to: 1; duration: 800; easing.type: Easing.InOutSine }
                }
            }
        }

        // Media Group - centered
        Row {
            id: leftMediaGroup
            anchors.centerIn: parent
            visible: islandState === "media"
            spacing: 6 * Appearance.effectiveScale
            Loader {
                id: mediaLogo; width: 18 * Appearance.effectiveScale; height: 18 * Appearance.effectiveScale; visible: islandState === "media"
                opacity: parent.parent.width > (24 * Appearance.effectiveScale) ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 200 } }
                property string activeEntryStr: {
                    if (!MprisController.activePlayer) return "";
                    let entry = MprisController.activePlayer.desktopEntry.toString();
                    let identity = MprisController.activePlayer.identity ? MprisController.activePlayer.identity.toString() : "";
                    return AppSearch.guessIcon(entry, "", identity);
                }
                
                sourceComponent: Component { 
                    Item {
                        width: 18 * Appearance.effectiveScale; height: 18 * Appearance.effectiveScale
                        IconImage { 
                            id: innerImg; anchors.fill: parent; 
                            source: mediaLogo.activeEntryStr !== "" ? Quickshell.iconPath(mediaLogo.activeEntryStr, "") : ""
                            visible: status === Image.Ready
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent; text: "music_note"; iconSize: 18 * Appearance.effectiveScale
                            color: Appearance.colors.colNotchText; visible: innerImg.status !== Image.Ready
                        }
                    }
                }
            }
            StyledText {
                id: mediaArtistLabel; text: MprisController.trackArtist || "Unknown Artist"
                visible: islandState === "media"; opacity: parent.parent.width > (30 * Appearance.effectiveScale) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                font.pixelSize: Math.round(12 * Appearance.effectiveScale); font.weight: Font.Medium; color: Appearance.colors.colNotchText
                width: Math.min(implicitWidth, parent.parent.width - (mediaLogo.visible ? 28 * Appearance.effectiveScale : 8 * Appearance.effectiveScale))
                elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
            }
        }

        // Pomodoro - centered
        StyledText {
            id: pomoModeLabel; anchors.centerIn: parent
            text: PomodoroService.modeName
            opacity: parent.width > (20 * Appearance.effectiveScale) ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: Math.round(12 * Appearance.effectiveScale); font.weight: Font.DemiBold; color: Appearance.colors.colNotchText
            visible: islandState === "pomodoro"
        }
    }

    // --- RIGHT EAR ---
    Item {
        id: rightEar
        anchors.left: root.right
        anchors.leftMargin: root.gapHalf
        y: 6 * Appearance.effectiveScale
        height: 28 * Appearance.effectiveScale
        clip: true
        visible: !GlobalStates.dropzoneNotchOpen && backgroundPill.pillWidth <= backgroundPill.normalWidth + 10
        
        HoverHandler {
            enabled: islandState === "media"
            onHoveredChanged: {
                if (hovered && Config.options.media.enableMediaHover) {
                    GlobalStates.openMediaNotch(root.QsWindow.window.screen);
                } else {
                    GlobalStates.closeMediaNotchWithDelay();
                }
            }
        }
        
        width: root.sharedEarWidth

        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on anchors.leftMargin { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        StyledText {
            id: notifSummaryLabel; anchors.centerIn: parent
            text: Notifications.activePopup?.summary || (islandStateOverride !== "" ? "New Message" : "")
            visible: islandState === "notification"
            opacity: parent.width > (20 * Appearance.effectiveScale) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: Math.round(12 * Appearance.effectiveScale); font.weight: Font.DemiBold
            color: Appearance.colors.colNotchText
            width: Math.min(implicitWidth, root.currentEarMaxWidth - (8 * Appearance.effectiveScale))
            elide: Text.ElideRight
        }

        StyledText {
            id: recordTimeLabel; anchors.centerIn: parent
            text: Functions.General.formatDuration(ScreenRecord.seconds)
            opacity: parent.width > (10 * Appearance.effectiveScale) ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: Math.round(12 * Appearance.effectiveScale); font.weight: Font.DemiBold; color: Appearance.colors.colNotchText
            font.family: Appearance.font.family.numbers; visible: islandState === "recording"
        }

        StyledText {
            id: mediaTitleLabel; anchors.centerIn: parent
            text: MprisController.trackTitle || ""
            visible: text !== "" && islandState === "media"; opacity: parent.width > (20 * Appearance.effectiveScale) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: Math.round(12 * Appearance.effectiveScale); font.weight: Font.DemiBold; color: Appearance.colors.colNotchText
            width: Math.min(implicitWidth, parent.width - (8 * Appearance.effectiveScale))
            elide: Text.ElideRight
        }

        StyledText {
            id: pomoTimeLabel; anchors.centerIn: parent
            text: PomodoroService.timeString
            opacity: parent.width > (10 * Appearance.effectiveScale) ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: Math.round(12 * Appearance.effectiveScale); font.weight: Font.DemiBold; color: Appearance.colors.colNotchText
            font.family: Appearance.font.family.numbers; visible: islandState === "pomodoro"
        }
    }

    // Concave Corners (Outward semi-circles connecting expanded notch smoothly to the top status bar)
    RoundCorner {
        anchors.right: backgroundPill.left; anchors.top: backgroundPill.top
        implicitSize: 14 * Appearance.effectiveScale; color: "black"; corner: RoundCorner.CornerEnum.TopRight
        visible: isWaterdrop || (GlobalStates.dropzoneNotchOpen && backgroundPill.pillWidth > backgroundPill.normalWidth + 10)
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        z: 10
    }

    RoundCorner {
        anchors.left: backgroundPill.right; anchors.top: backgroundPill.top
        implicitSize: 14 * Appearance.effectiveScale; color: "black"; corner: RoundCorner.CornerEnum.TopLeft
        visible: isWaterdrop || (GlobalStates.dropzoneNotchOpen && backgroundPill.pillWidth > backgroundPill.normalWidth + 10)
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        z: 10
    }

    // --- BACKGROUND PILL ---
    Rectangle {
        id: backgroundPill
        color: "black"
        clip: GlobalStates.dropzoneNotchOpen

        readonly property real margin: isM3 ? 8 * Appearance.effectiveScale : (isWaterdrop && root.indicatorStyle === "unified" ? 10 : root.indicatorStyle === "unified" ? 4 : 10) * Appearance.effectiveScale
        readonly property real normalHeight: isWaterdrop ? 34 * Appearance.effectiveScale : (isM3 ? 32 * Appearance.effectiveScale : 28 * Appearance.effectiveScale)
        readonly property real normalWidth: (rightEar.x + rightEar.width) - leftEar.x + (2 * margin)
        readonly property real targetDropzoneWidth: Math.min(520 * Appearance.effectiveScale, (root.parent ? root.parent.width * 0.95 : 540 * Appearance.effectiveScale))
        readonly property real normalX: leftEar.x - margin

        property real pillWidth: normalWidth
        property real pillHeight: normalHeight
        property real pillX: normalX

        y: isWaterdrop ? 0 : (isM3 ? 4 * Appearance.effectiveScale : 6 * Appearance.effectiveScale)
        height: pillHeight
        width: pillWidth
        x: pillX
        radius: Math.min(Appearance.rounding.button, pillHeight / 2)
        
        z: -1

        // States for Smooth 2-Stage Expansion & Collapse
        states: [
            State {
                name: "closed"
                when: !GlobalStates.dropzoneNotchOpen
                PropertyChanges { target: backgroundPill; pillWidth: backgroundPill.normalWidth }
                PropertyChanges { target: backgroundPill; pillHeight: backgroundPill.normalHeight }
                PropertyChanges { target: backgroundPill; pillX: backgroundPill.normalX }
            },
            State {
                name: "open"
                when: GlobalStates.dropzoneNotchOpen
                PropertyChanges { target: backgroundPill; pillWidth: backgroundPill.targetDropzoneWidth }
                PropertyChanges { target: backgroundPill; pillHeight: Math.min(440 * Appearance.effectiveScale, dropzoneLayout.implicitHeight + (24 * Appearance.effectiveScale)) }
                PropertyChanges { target: backgroundPill; pillX: -backgroundPill.targetDropzoneWidth / 2 }
            }
        ]

        transitions: [
            Transition {
                from: "closed"; to: "open"
                SequentialAnimation {
                    // Stage 1: Expand Width & X horizontally first (exact reverse of collapse Stage 2)
                    ParallelAnimation {
                        NumberAnimation { target: backgroundPill; property: "pillWidth"; duration: 220; easing.type: Easing.OutQuint }
                        NumberAnimation { target: backgroundPill; property: "pillX"; duration: 220; easing.type: Easing.OutQuint }
                    }
                    // Stage 2: Expand Height vertically & fade in content (exact reverse of collapse Stage 1)
                    ParallelAnimation {
                        NumberAnimation { target: backgroundPill; property: "pillHeight"; duration: 180; easing.type: Easing.OutQuint }
                        NumberAnimation { target: dropzoneLayout; property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutQuint }
                    }
                }
            },
            Transition {
                from: "open"; to: "closed"
                SequentialAnimation {
                    // Stage 1: Shrink Height vertically & fade out content first
                    ParallelAnimation {
                        NumberAnimation { target: backgroundPill; property: "pillHeight"; duration: 180; easing.type: Easing.OutQuint }
                        NumberAnimation { target: dropzoneLayout; property: "opacity"; to: 0; duration: 140; easing.type: Easing.OutQuint }
                    }
                    // Stage 2: Shrink Width & X horizontally back to normal
                    ParallelAnimation {
                        NumberAnimation { target: backgroundPill; property: "pillWidth"; duration: 220; easing.type: Easing.OutQuint }
                        NumberAnimation { target: backgroundPill; property: "pillX"; duration: 220; easing.type: Easing.OutQuint }
                    }
                }
            }
        ]

        // The "Flattener" - Square off the top part
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: parent.radius
            color: "black"
            visible: isWaterdrop || GlobalStates.dropzoneNotchOpen
        }
        
        // Accept external drag-and-drop files onto the notch
        DropArea {
            anchors.fill: parent
            enabled: GlobalStates.dropzoneNotchOpen
            onDropped: (drop) => {
                if (drop.hasUrls) {
                    let paths = []
                    for (let i = 0; i < drop.urls.length; i++) {
                        paths.push(drop.urls[i])
                    }
                    DropzoneService.addFiles(paths)
                }
            }
        }

        FocusedScrollMouseArea {
            anchors.fill: parent; hoverEnabled: true; preventStealing: true; cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            visible: !GlobalStates.dropzoneNotchOpen
            onEntered: { if (MprisController.activePlayer) { root.mediaShowing = true; mediaTimer.restart(); if (GlobalStates.mediaNotchOpen) GlobalStates.stopMediaNotchTimer(); } }
            onExited: GlobalStates.closeMediaNotchWithDelay();
            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton) { HyprlandData.cycleLayout(); return; }
                if (islandState === "recording") { if (mouse.button === Qt.LeftButton) ScreenRecord.stop(); return; }
                if (mouse.button === Qt.RightButton) { GlobalStates.overviewOpen = !GlobalStates.overviewOpen; return; }
                if (islandState === "notification" && Notifications.activePopup) { Notifications.activePopup.expanded = !Notifications.activePopup.expanded }
                else if (islandState === "media") { MprisController.raisePlayer(); GlobalStates.closeAllPanels() }
                else if (islandState === "pomodoro") { GlobalStates.dashboardOpen = true }
            }
            onScrollUp: {
                if (root.monitor && root.monitor.activeWorkspace && root.monitor.activeWorkspace.id > 1) {
                    Hyprland.dispatch(HyprlandCompat.dspWorkspace("r-1"))
                }
            }
            onScrollDown: Hyprland.dispatch(HyprlandCompat.dspWorkspace("r+1"))
        }

        // ── EMBEDDED DROPZONE HUD CONTENT ──
        ColumnLayout {
            id: dropzoneLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 16 * Appearance.effectiveScale
            anchors.rightMargin: 16 * Appearance.effectiveScale
            anchors.topMargin: (isWaterdrop ? 6 : (isM3 ? 6 : 4)) * Appearance.effectiveScale
            anchors.bottomMargin: 12 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale
            visible: opacity > 0
            opacity: 0

            // ── 1. HEADER (Aligned with topbar elements) ──
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

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.15)
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

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.15)
                visible: DropzoneService.hasFiles
            }

            // ── 3. STRUCTURED BATCH ACTIONS & CONTROLS SECTION ──
            ColumnLayout {
                Layout.fillWidth: true
                visible: DropzoneService.hasFiles
                spacing: 10 * Appearance.effectiveScale

                // ── A. QUICK BATCH ACTIONS (Grab All & Clear All) ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                    // "Grab All Files" Card - Supports native Wayland Drag & Drop of ALL files simultaneously!
                    Rectangle {
                        id: grabAllCard
                        Layout.fillWidth: true
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

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6 * Appearance.effectiveScale

                            MaterialSymbol {
                                text: "swipe_up"
                                iconSize: 18 * Appearance.effectiveScale
                                color: Appearance.colors.colAccent
                            }

                            StyledText {
                                text: "Grab All Files (" + DropzoneService.stashedFiles.length + ")"
                                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                                font.weight: Font.Bold
                                color: Appearance.colors.colNotchText
                            }

                            StyledText {
                                text: "• Drag out to app"
                                font.pixelSize: Math.round(10 * Appearance.effectiveScale)
                                color: Qt.rgba(1, 1, 1, 0.5)
                            }
                        }
                    }

                    // "Clear All" Button
                    Rectangle {
                        implicitWidth: clearAllRow.implicitWidth + 16 * Appearance.effectiveScale
                        implicitHeight: 34 * Appearance.effectiveScale
                        radius: 8 * Appearance.effectiveScale
                        color: clearHover.hovered ? Qt.rgba(0.9, 0.2, 0.2, 0.3) : Qt.rgba(1, 1, 1, 0.08)
                        border.color: clearHover.hovered ? Qt.rgba(0.9, 0.2, 0.2, 0.5) : Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1

                        HoverHandler { id: clearHover }

                        Row {
                            id: clearAllRow
                            anchors.centerIn: parent
                            spacing: 4 * Appearance.effectiveScale

                            MaterialSymbol {
                                text: "delete_sweep"
                                iconSize: 16 * Appearance.effectiveScale
                                color: clearHover.hovered ? "#ff6b6b" : Qt.rgba(1, 1, 1, 0.7)
                            }

                            StyledText {
                                text: "Clear All"
                                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                                font.weight: Font.DemiBold
                                color: clearHover.hovered ? "#ff6b6b" : Qt.rgba(1, 1, 1, 0.7)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DropzoneService.clearAll()
                        }
                    }
                }

                // ── B. OUTPUT DESTINATION ──
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32 * Appearance.effectiveScale
                    radius: 8 * Appearance.effectiveScale
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3 * Appearance.effectiveScale
                        spacing: 4 * Appearance.effectiveScale

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6 * Appearance.effectiveScale
                            color: root.destMode === "original" ? Qt.rgba(1, 1, 1, 0.18) : "transparent"

                            Row {
                                anchors.centerIn: parent
                                spacing: 6 * Appearance.effectiveScale
                                MaterialSymbol { text: "folder"; iconSize: 14 * Appearance.effectiveScale; color: root.destMode === "original" ? Appearance.colors.colAccent : Qt.rgba(1, 1, 1, 0.5) }
                                StyledText { text: "Original Folder"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); font.weight: Font.DemiBold; color: root.destMode === "original" ? Appearance.colors.colNotchText : Qt.rgba(1, 1, 1, 0.5) }
                            }

                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.destMode = "original" }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6 * Appearance.effectiveScale
                            color: root.destMode === "kdeconnect" ? Qt.rgba(1, 1, 1, 0.18) : "transparent"

                            Row {
                                anchors.centerIn: parent
                                spacing: 6 * Appearance.effectiveScale
                                MaterialSymbol { text: "phonelink"; iconSize: 14 * Appearance.effectiveScale; color: root.destMode === "kdeconnect" ? Appearance.colors.colAccent : Qt.rgba(1, 1, 1, 0.5) }
                                StyledText { text: "Mobile (KDE Connect)"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); font.weight: Font.DemiBold; color: root.destMode === "kdeconnect" ? Appearance.colors.colNotchText : Qt.rgba(1, 1, 1, 0.5) }
                            }

                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.destMode = "kdeconnect" }
                        }
                    }
                }

                // ── C. CATEGORIZED CONVERSIONS & FILE TOOLS ──
                Flow {
                    Layout.fillWidth: true
                    spacing: 6 * Appearance.effectiveScale

                    // Mobile Direct Send
                    Rectangle {
                        implicitWidth: kdeBtnText.implicitWidth + 24 * Appearance.effectiveScale
                        implicitHeight: 26 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: Qt.rgba(1, 1, 1, 0.1)
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        border.width: 1

                        Row {
                            id: kdeBtnText
                            anchors.centerIn: parent
                            spacing: 4 * Appearance.effectiveScale
                            MaterialSymbol { text: "send_to_mobile"; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colNotchText }
                            StyledText { text: "Send to Mobile"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); color: Appearance.colors.colNotchText }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (DropzoneService.stashedFiles.length > 0) {
                                    DropzoneService.sendToKdeConnect(DropzoneService.stashedFiles[0].path)
                                }
                            }
                        }
                    }

                    // Image Conversions
                    Rectangle {
                        visible: root.hasImage
                        implicitWidth: pngBtnText.implicitWidth + 20 * Appearance.effectiveScale
                        implicitHeight: 26 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: Qt.rgba(1, 1, 1, 0.1)

                        StyledText { id: pngBtnText; anchors.centerIn: parent; text: "→ PNG"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); color: Appearance.colors.colNotchText }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { let img = DropzoneService.stashedFiles.find(f => f.isImage); if (img) DropzoneService.convertImage(img.path, "png", root.destMode) } }
                    }

                    Rectangle {
                        visible: root.hasImage
                        implicitWidth: jpgBtnText.implicitWidth + 20 * Appearance.effectiveScale
                        implicitHeight: 26 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: Qt.rgba(1, 1, 1, 0.1)

                        StyledText { id: jpgBtnText; anchors.centerIn: parent; text: "→ JPG"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); color: Appearance.colors.colNotchText }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { let img = DropzoneService.stashedFiles.find(f => f.isImage); if (img) DropzoneService.convertImage(img.path, "jpg", root.destMode) } }
                    }

                    Rectangle {
                        visible: root.hasImage
                        implicitWidth: webpBtnText.implicitWidth + 20 * Appearance.effectiveScale
                        implicitHeight: 26 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: Qt.rgba(1, 1, 1, 0.1)

                        StyledText { id: webpBtnText; anchors.centerIn: parent; text: "→ WEBP"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); color: Appearance.colors.colNotchText }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { let img = DropzoneService.stashedFiles.find(f => f.isImage); if (img) DropzoneService.convertImage(img.path, "webp", root.destMode) } }
                    }

                    Rectangle {
                        visible: root.hasImage
                        implicitWidth: exifBtnText.implicitWidth + 24 * Appearance.effectiveScale
                        implicitHeight: 26 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Row {
                            id: exifBtnText
                            anchors.centerIn: parent
                            spacing: 4 * Appearance.effectiveScale
                            MaterialSymbol { text: "cleaning_services"; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colNotchText }
                            StyledText { text: "Clean EXIF"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); color: Appearance.colors.colNotchText }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { let img = DropzoneService.stashedFiles.find(f => f.isImage); if (img) DropzoneService.cleanExif(img.path, root.destMode) } }
                    }

                    // Video Conversions
                    Rectangle {
                        visible: root.hasVideo
                        implicitWidth: gifBtnText.implicitWidth + 20 * Appearance.effectiveScale
                        implicitHeight: 26 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: Qt.rgba(1, 1, 1, 0.1)

                        StyledText { id: gifBtnText; anchors.centerIn: parent; text: "MP4 → GIF"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); color: Appearance.colors.colNotchText }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { let vid = DropzoneService.stashedFiles.find(f => f.isVideo); if (vid) DropzoneService.convertVideo(vid.path, "gif", root.destMode) } }
                    }

                    Rectangle {
                        visible: root.hasVideo
                        implicitWidth: mp3BtnText.implicitWidth + 20 * Appearance.effectiveScale
                        implicitHeight: 26 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: Qt.rgba(1, 1, 1, 0.1)

                        StyledText { id: mp3BtnText; anchors.centerIn: parent; text: "MP4 → MP3"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); color: Appearance.colors.colNotchText }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { let vid = DropzoneService.stashedFiles.find(f => f.isVideo); if (vid) DropzoneService.convertVideo(vid.path, "mp3", root.destMode) } }
                    }

                    // Archive Operations
                    Rectangle {
                        implicitWidth: zipBtnText.implicitWidth + 24 * Appearance.effectiveScale
                        implicitHeight: 26 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Row {
                            id: zipBtnText
                            anchors.centerIn: parent
                            spacing: 4 * Appearance.effectiveScale
                            MaterialSymbol { text: "archive"; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colNotchText }
                            StyledText { text: "ZIP"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); color: Appearance.colors.colNotchText }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { let paths = DropzoneService.stashedFiles.map(f => f.path); DropzoneService.compressArchive(paths, "zip", root.destMode) } }
                    }

                    Rectangle {
                        implicitWidth: tarBtnText.implicitWidth + 24 * Appearance.effectiveScale
                        implicitHeight: 26 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Row {
                            id: tarBtnText
                            anchors.centerIn: parent
                            spacing: 4 * Appearance.effectiveScale
                            MaterialSymbol { text: "archive"; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colNotchText }
                            StyledText { text: "TAR.GZ"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); color: Appearance.colors.colNotchText }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { let paths = DropzoneService.stashedFiles.map(f => f.path); DropzoneService.compressArchive(paths, "tar.gz", root.destMode) } }
                    }

                    Rectangle {
                        visible: root.hasArchive
                        implicitWidth: unarchiveBtnText.implicitWidth + 24 * Appearance.effectiveScale
                        implicitHeight: 26 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Row {
                            id: unarchiveBtnText
                            anchors.centerIn: parent
                            spacing: 4 * Appearance.effectiveScale
                            MaterialSymbol { text: "unarchive"; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colNotchText }
                            StyledText { text: "Extract"; font.pixelSize: Math.round(11 * Appearance.effectiveScale); color: Appearance.colors.colNotchText }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { let arch = DropzoneService.stashedFiles.find(f => f.isArchive); if (arch) DropzoneService.decompressArchive(arch.path, root.destMode) } }
                    }
                }
            }
        }
    }
}
