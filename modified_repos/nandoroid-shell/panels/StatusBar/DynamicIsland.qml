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

    // KDE Connect Notch Status
    property bool kdeConnectShowing: false
    property string kdeConnectText: ""
    property bool kdeConnectIsError: false

    Timer {
        id: kdeConnectHideTimer
        interval: 3500
        onTriggered: root.kdeConnectShowing = false
    }

    Timer {
        id: kdeConnectStartTimer
        interval: 300
        onTriggered: {
            root.kdeConnectShowing = true
            kdeConnectHideTimer.restart()
        }
    }

    Connections {
        target: DropzoneService
        function onKdeConnectSent(count, isError) {
            root.kdeConnectIsError = !!isError
            if (isError) {
                root.kdeConnectText = (count === 1) ? "Error sending file" : "Error sending files"
            } else {
                root.kdeConnectText = (count === 1) ? "1 file sent" : (count + " files sent")
            }
            kdeConnectStartTimer.restart()
        }
    }

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
        if (kdeConnectShowing) return "kdeconnect"
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
        if (islandState === "kdeconnect") {
            let w = 0
            if (kdeConnectIcon.visible || kdeConnectAppImg.visible) w += (18 * Appearance.effectiveScale) + (6 * Appearance.effectiveScale)
            if (kdeConnectAppLabel.visible) w += kdeConnectAppLabel.implicitWidth + (4 * Appearance.effectiveScale)
            return w > 0 ? w + (4 * Appearance.effectiveScale) : 0
        }
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
        if (islandState === "kdeconnect") return kdeConnectSummaryLabel.implicitWidth + (8 * Appearance.effectiveScale)
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
                appIcon: (Notifications.activePopup ? Notifications.activePopup.appIcon : "") || (islandStateOverride !== "" ? "chat" : "")
                appName: Notifications.activePopup ? Notifications.activePopup.appName : ""
                image: Notifications.activePopup ? Notifications.activePopup.image : ""
                summary: (Notifications.activePopup ? Notifications.activePopup.summary : "") || (islandStateOverride !== "" ? "New Message" : "")
                urgency: (Notifications.activePopup ? Notifications.activePopup.urgency : "") || "normal"
                color: "transparent"
            }
            StyledText {
                id: notifAppNameLabel
                text: (Notifications.activePopup ? Notifications.activePopup.appName : "") || (islandStateOverride !== "" ? "Messages" : "Notification")
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

        // KDE Connect - centered
        Row {
            anchors.centerIn: parent
            visible: islandState === "kdeconnect"
            spacing: 6 * Appearance.effectiveScale
            IconImage {
                id: kdeConnectAppImg
                width: 18 * Appearance.effectiveScale
                height: 18 * Appearance.effectiveScale
                source: {
                    let p = Quickshell.iconPath("kdeconnect", "org.kde.kdeconnect")
                    if (p) return p
                    let g = AppSearch.guessIcon("kdeconnect", "org.kde.kdeconnect", "KDE Connect")
                    return g ? Quickshell.iconPath(g, "") : ""
                }
                visible: islandState === "kdeconnect" && status === Image.Ready
                opacity: parent.parent.width > (18 * Appearance.effectiveScale) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            MaterialSymbol {
                id: kdeConnectIcon
                text: root.kdeConnectIsError ? "phonelink_erase" : "phonelink"
                iconSize: 18 * Appearance.effectiveScale
                color: root.kdeConnectIsError ? Appearance.m3colors.m3error : Appearance.colors.colNotchText
                visible: islandState === "kdeconnect" && kdeConnectAppImg.status !== Image.Ready
                opacity: parent.parent.width > (18 * Appearance.effectiveScale) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            StyledText {
                id: kdeConnectAppLabel
                text: "KDE Connect"
                visible: islandState === "kdeconnect"
                opacity: parent.parent.width > (30 * Appearance.effectiveScale) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                font.weight: Font.Medium
                color: root.kdeConnectIsError ? Appearance.m3colors.m3error : Appearance.colors.colNotchText
                verticalAlignment: Text.AlignVCenter
            }
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
            id: kdeConnectSummaryLabel
            anchors.centerIn: parent
            text: root.kdeConnectText
            visible: islandState === "kdeconnect"
            opacity: parent.width > (15 * Appearance.effectiveScale) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: Math.round(12 * Appearance.effectiveScale)
            font.weight: Font.DemiBold
            color: root.kdeConnectIsError ? Appearance.m3colors.m3error : Appearance.colors.colNotchText
            width: Math.min(implicitWidth, root.currentEarMaxWidth - (8 * Appearance.effectiveScale))
            elide: Text.ElideRight
        }

        StyledText {
            id: notifSummaryLabel; anchors.centerIn: parent
            text: (Notifications.activePopup ? Notifications.activePopup.summary : "") || (islandStateOverride !== "" ? "New Message" : "")
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
                PropertyChanges { target: backgroundPill; pillHeight: Math.min(500 * Appearance.effectiveScale, dropzoneLayout.implicitHeight + (24 * Appearance.effectiveScale)) }
                PropertyChanges { target: backgroundPill; pillX: -backgroundPill.targetDropzoneWidth / 2 }
            }
        ]

        transitions: [
            Transition {
                from: "closed"; to: "open"
                SequentialAnimation {
                    // Stage 1: Expand Width & X horizontally first with smooth OutCubic easing
                    ParallelAnimation {
                        NumberAnimation { target: backgroundPill; property: "pillWidth"; duration: 180; easing.type: Easing.OutCubic }
                        NumberAnimation { target: backgroundPill; property: "pillX"; duration: 180; easing.type: Easing.OutCubic }
                    }
                    // Stage 2: Expand Height vertically & fade in content smoothly
                    ParallelAnimation {
                        NumberAnimation { target: backgroundPill; property: "pillHeight"; duration: 150; easing.type: Easing.OutCubic }
                        NumberAnimation { target: dropzoneLayout; property: "opacity"; to: 1; duration: 130; easing.type: Easing.OutCubic }
                    }
                }
            },
            Transition {
                from: "open"; to: "closed"
                SequentialAnimation {
                    // Stage 1: Fade out content & shrink Height vertically first
                    ParallelAnimation {
                        NumberAnimation { target: dropzoneLayout; property: "opacity"; to: 0; duration: 100; easing.type: Easing.OutCubic }
                        NumberAnimation { target: backgroundPill; property: "pillHeight"; duration: 140; easing.type: Easing.OutCubic }
                    }
                    // Stage 2: Shrink Width & X horizontally back to normal
                    ParallelAnimation {
                        NumberAnimation { target: backgroundPill; property: "pillWidth"; duration: 170; easing.type: Easing.OutCubic }
                        NumberAnimation { target: backgroundPill; property: "pillX"; duration: 170; easing.type: Easing.OutCubic }
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
        DropzoneNotchPopup {
            id: dropzoneLayout
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: backgroundPill.targetDropzoneWidth - (32 * Appearance.effectiveScale)
            anchors.topMargin: (isWaterdrop ? 6 : (isM3 ? 6 : 4)) * Appearance.effectiveScale
            anchors.bottomMargin: 12 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale
            visible: opacity > 0
            opacity: 0
        }
    }
}
