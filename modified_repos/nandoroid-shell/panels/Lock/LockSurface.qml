pragma ComponentBehavior: Bound
import "../../core"
import "../../widgets"
import "../../services"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Qt5Compat.GraphicalEffects
import "../NotificationCenter"
import "../StatusBar"

/**
 * Ported Zaphkiel "Kuru Kuru" lock screen surface.
 * Retains NAnDoroid's status bar topbar exactly as shown when locked.
 */
MouseArea {
    id: root
    anchors.fill: parent
    required property LockContext context

    readonly property bool requirePasswordToPower: Config.options.lock?.security?.requirePasswordToPower ?? true

    // Monitor detection for adaptive colors/background
    readonly property var screen: root.QsWindow.window ? root.QsWindow.window.screen : null
    readonly property int monitorIndex: screen ? screen.index : 0
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    function forceFieldFocus() { passwordInput.forceActiveFocus() }

    property bool showPasswordCounter: false
    property bool showFingerCounter: false

    Timer {
        id: passwordCounterTimer
        interval: 1500
        onTriggered: root.showPasswordCounter = false
    }

    Timer {
        id: fingerCounterTimer
        interval: 1500
        onTriggered: root.showFingerCounter = false
    }

    Connections {
        target: context
        function onShouldReFocus() { root.forceFieldFocus() }

        function onPasswordFailCountChanged() {
            if (root.context.passwordFailCount > 0) {
                root.showPasswordCounter = true
                passwordCounterTimer.restart()
            } else {
                root.showPasswordCounter = false
            }
        }

        function onFingerFailCountChanged() {
            if (root.context.fingerFailCount > 0) {
                root.showFingerCounter = true
                fingerCounterTimer.restart()
            } else {
                root.showFingerCounter = false
            }
        }
    }

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton

    onPressed: {
        forceFieldFocus()
        root.context.tryFingerUnlock()
    }
    onPositionChanged: {
        forceFieldFocus()
        root.context.tryFingerUnlock()
    }

    property bool ctrlHeld: false
    Keys.onPressed: event => {
        root.context.resetClearTimer()
        if (event.key === Qt.Key_Control) root.ctrlHeld = true
        if (event.key === Qt.Key_Escape)  root.context.currentText = ""
        forceFieldFocus()
        root.context.tryFingerUnlock()
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control) root.ctrlHeld = false
        forceFieldFocus()
    }

    Component.onCompleted: {
        forceFieldFocus()
    }

    // ── Wallpaper with Blur ──
    Image {
        id: wallpaper
        anchors.fill: parent
        z: -2
        visible: false
        source: {
            if (!Config.ready) return ""
            if (Config.options.lock.useSeparateWallpaper && Config.options.lock.wallpaperPath !== "") {
                return Config.options.lock.wallpaperPath
            }
            return Config.options.appearance?.background?.wallpaperPath ?? ""
        }
        fillMode: Image.PreserveAspectCrop
    }

    FastBlur {
        id: blurredWallpaper
        anchors.fill: parent
        source: wallpaper
        z: -2
        radius: (root.context.currentText.length > 0) ? 64 : 0

        Behavior on radius {
            NumberAnimation {
                duration: 400
                easing.type: Easing.InOutQuad
            }
        }
    }

    // ── Barcode (Password Masking) ──
    Item {
        id: barcodeContainer
        anchors.centerIn: parent
        clip: true
        z: -1
        height: barcodeText.contentHeight
        width: root.context.unlockInProgress ? 0 : barcodeText.contentWidth

        Behavior on width {
            NumberAnimation {
                duration: 400
                easing.type: Easing.InOutQuad
            }
        }

        Text {
            id: barcodeText
            anchors.centerIn: parent
            font.bold: true
            font.family: "Libre Barcode 128"
            font.pointSize: 300 * Appearance.effectiveScale
            color: Appearance.colors.colPrimary
            renderType: Text.NativeRendering
            text: root.context.maskedText
            visible: text.length > 0
        }
    }

    // ── Foreground Isolated Image ──
    Image {
        id: fgCharacter
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: root.context.wallFg
        visible: !root.context.fgGenerating && Config.ready && Config.options.lock.useForegroundIsolation && source !== ""
        z: 0
    }

    // ── Hidden TextInput for keyboard capture ──
    TextInput {
        id: passwordInput
        anchors.fill: parent
        color: "transparent"
        cursorVisible: false
        inputMethodHints: Qt.ImhSensitiveData
        echoMode: TextInput.Normal
        cursorDelegate: Item {}
        clip: true
        z: -3 // Behind wallpaper but still captures focus
        readOnly: root.context.passwordLocked

        onTextChanged: {
            if (!root.context.passwordLocked)
                root.context.currentText = text
        }
        onAccepted: {
            if (!root.context.passwordLocked)
                root.context.tryUnlock(root.ctrlHeld)
        }
        Keys.onPressed: event => {
            if (!root.context.passwordLocked)
                root.context.resetClearTimer()
        }

        Connections {
            target: root.context
            function onCurrentTextChanged() {
                if (passwordInput.text !== root.context.currentText)
                    passwordInput.text = root.context.currentText
            }
        }
    }

    // ── Input Pill (Zaphkiel minimal style) ──
    Rectangle {
        id: inputPill
        anchors.centerIn: parent
        z: 1
        height: 44 * Appearance.effectiveScale
        radius: height / 2
        clip: true
        color: root.context.showFailure ? Appearance.colors.colError : (root.context.unlockInProgress ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerHigh)

        readonly property color contentColor: root.context.showFailure ? Appearance.colors.colOnError : (root.context.unlockInProgress ? Appearance.colors.colOnPrimary : Appearance.m3colors.m3onSurface)

        Behavior on color {
            ColorAnimation { duration: 200 }
        }

        implicitWidth: inputRow.implicitWidth + 24 * Appearance.effectiveScale
        width: implicitWidth
        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuint
            }
        }

        MouseArea {
            id: pillMouseArea
            anchors.fill: parent
            hoverEnabled: true

            RowLayout {
                id: inputRow
                anchors.centerIn: parent
                height: parent.height
                spacing: 12 * Appearance.effectiveScale

                // 1. Suspend Button (Visible on hover)
                Item {
                    Layout.fillHeight: true
                    implicitWidth: parent.height - 8
                    visible: pillMouseArea.containsMouse && !root.context.unlockInProgress

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "bedtime"
                        iconSize: 18 * Appearance.effectiveScale
                        color: inputPill.contentColor
                        fill: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.context.stopFingerPam()
                            Quickshell.execDetached(["systemctl", "suspend"])
                        }
                    }
                }

                // 2. Lock Status Icon (Rotating when unlocking)
                Item {
                    id: lockIconContainer
                    Layout.fillHeight: true
                    implicitWidth: parent.height - 8

                    MaterialSymbol {
                        id: lockIcon
                        anchors.centerIn: parent
                        text: root.context.unlockInProgress ? "sync" : "lock"
                        iconSize: 18 * Appearance.effectiveScale
                        color: root.context.passwordLocked ? Appearance.colors.colError : inputPill.contentColor
                        fill: 1

                        RotationAnimator on rotation {
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: root.context.unlockInProgress
                        }
                    }

                    // Password attempt counter below lock icon
                    StyledText {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2 * Appearance.effectiveScale
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.context.passwordFailCount + "/5"
                        font.pixelSize: 8 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        color: root.context.passwordLocked ? Appearance.colors.colError : inputPill.contentColor
                        opacity: root.showPasswordCounter ? 0.7 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }

                // 3. Fingerprint Icon (Visible if fingerprints configured)
                Item {
                    Layout.fillHeight: true
                    implicitWidth: parent.height - 8
                    visible: root.context.fingerprintsConfigured && !root.context.unlockInProgress

                    MaterialSymbol {
                        id: fingerprintIcon
                        anchors.centerIn: parent
                        text: root.context.fingerLocked ? "block" : "fingerprint"
                        iconSize: 18 * Appearance.effectiveScale
                        color: (root.context.fingerFailed || root.context.fingerLocked)
                            ? Appearance.colors.colError
                            : inputPill.contentColor

                        Behavior on color { ColorAnimation { duration: 200 } }
                        
                        transformOrigin: Item.Bottom
                    }

                    // Shake Animation for Fingerprint Icon (windshield wiper style)
                    SequentialAnimation {
                        id: fingerShakeAnim
                        running: root.context.fingerFailed
                        loops: 2
                        NumberAnimation { target: fingerprintIcon; property: "rotation"; from: 0; to: -10; duration: 70; easing.type: Easing.InOutCubic }
                        NumberAnimation { target: fingerprintIcon; property: "rotation"; from: -10; to: 10; duration: 140; easing.type: Easing.InOutCubic }
                        NumberAnimation { target: fingerprintIcon; property: "rotation"; from: 10; to: 0; duration: 70; easing.type: Easing.InOutCubic }
                    }

                    // Fingerprint attempt counter below fingerprint icon
                    StyledText {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2 * Appearance.effectiveScale
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.context.fingerFailCount + "/5"
                        font.pixelSize: 8 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        color: (root.context.fingerFailed || root.context.fingerLocked)
                            ? Appearance.colors.colError
                            : inputPill.contentColor
                        opacity: root.showFingerCounter ? 0.7 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }

                // 4. Submit / Login Button (Visible on hover and when password entered)
                Item {
                    Layout.fillHeight: true
                    implicitWidth: parent.height - 8
                    visible: pillMouseArea.containsMouse && !root.context.unlockInProgress && root.context.currentText.length > 0

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "login"
                        iconSize: 18 * Appearance.effectiveScale
                        color: inputPill.contentColor
                        fill: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.context.tryUnlock()
                        }
                    }
                }
            }
        }
    }

    // Shake Animation for Input Pill (Password failure only)
    SequentialAnimation {
        id: shakeAnim
        running: root.context.showFailure
        loops: 2
        NumberAnimation { target: inputPill; property: "anchors.horizontalCenterOffset"; from: 0; to: -10 * Appearance.effectiveScale; duration: 75; easing.type: Easing.InOutSine }
        NumberAnimation { target: inputPill; property: "anchors.horizontalCenterOffset"; from: -10 * Appearance.effectiveScale; to: 10 * Appearance.effectiveScale; duration: 150; easing.type: Easing.InOutSine }
        NumberAnimation { target: inputPill; property: "anchors.horizontalCenterOffset"; from: 10 * Appearance.effectiveScale; to: 0; duration: 75; easing.type: Easing.InOutSine }
    }

    // Fingerprint / Password Lockout countdown and indicators
    StyledText {
        anchors.horizontalCenter: inputPill.horizontalCenter
        anchors.top: inputPill.bottom
        anchors.topMargin: 8 * Appearance.effectiveScale
        z: 1
        visible: root.context.passwordLocked || root.context.fingerLocked
        text: root.context.passwordLocked
            ? ("Try again in " + Math.floor(root.context.lockoutTimeRemaining / 60) + ":" + ("0" + root.context.lockoutTimeRemaining % 60).slice(-2))
            : (root.context.fingerLocked ? "Fingerprint disabled" : "")
        font.pixelSize: 11 * Appearance.effectiveScale
        font.weight: Font.Medium
        color: Appearance.colors.colError
        opacity: 0.85

        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // ── Lockscreen Status Bar (Matching System Style) ──
    Item {
        id: lockStatusBarContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Appearance.sizes.statusBarHeight
        z: 10

        readonly property bool isCentered: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
        readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth * Appearance.effectiveScale : 1200 * Appearance.effectiveScale
        readonly property real sidePadding: isCentered ? Math.round((parent.width - Math.min(centeredWidth, parent.width - 40 * Appearance.effectiveScale)) / 2) : 12 * Appearance.effectiveScale
        readonly property int cornerRadius: Math.round(((Config.ready && Config.options.statusBar?.backgroundCornerRadius) || 20) * Appearance.effectiveScale)

        // Adaptive background detection
        readonly property int bgStyle: (Config.ready && Config.options.statusBar) ? (Config.options.statusBar.backgroundStyle ?? 0) : 0
        readonly property int activeWorkspaceId: root.monitor?.activeWorkspace?.id ?? -1
        readonly property bool hasTiledWindows: {
            if (bgStyle !== 2 || activeWorkspaceId === -1) return false;
            return HyprlandData.windowList.some(w => 
                w.workspace.id === activeWorkspaceId && 
                !w.floating && 
                w.monitor === root.monitorIndex
            );
        }

        // Selection of the final color based on actual visibility
        property color contentColor: barBg.showBg ? Appearance.m3colors.m3onSurface : Appearance.colors.colStatusBarText
        property color subtextColor: barBg.showBg ? Appearance.m3colors.m3onSurfaceVariant : Appearance.colors.colStatusBarSubtext

        Behavior on contentColor { ColorAnimation { duration: 300 } }
        Behavior on subtextColor { ColorAnimation { duration: 300 } }

        // 1. Solid background (follows system config)
        Rectangle {
            id: barBg
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            
            readonly property bool showBg: (lockStatusBarContainer.bgStyle === 1) || (lockStatusBarContainer.bgStyle === 2 && lockStatusBarContainer.hasTiledWindows)
            
            width: (lockStatusBarContainer.isCentered && showBg) ? Math.min(lockStatusBarContainer.centeredWidth, parent.width - 40 * Appearance.effectiveScale) : parent.width
            height: parent.height + (lockStatusBarContainer.isCentered && showBg ? lockStatusBarContainer.cornerRadius : 0)
            anchors.topMargin: (lockStatusBarContainer.isCentered && showBg) ? -lockStatusBarContainer.cornerRadius : 0
            
            color: showBg ? Appearance.colors.colStatusBarSolid : "transparent"
            radius: (lockStatusBarContainer.isCentered && showBg) ? lockStatusBarContainer.cornerRadius : 0

            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

            // concanve corners
            // Standard Corners
            RoundCorner {
                anchors.left: parent.left
                anchors.top: parent.bottom
                implicitSize: lockStatusBarContainer.cornerRadius
                color: barBg.color
                corner: RoundCorner.CornerEnum.TopLeft
                visible: barBg.showBg && !lockStatusBarContainer.isCentered
            }
            RoundCorner {
                anchors.right: parent.right
                anchors.top: parent.bottom
                implicitSize: lockStatusBarContainer.cornerRadius
                color: barBg.color
                corner: RoundCorner.CornerEnum.TopRight
                visible: barBg.showBg && !lockStatusBarContainer.isCentered
            }

            // HUD Corners
            RoundCorner {
                anchors { right: parent.left; top: parent.top; topMargin: lockStatusBarContainer.cornerRadius }
                implicitSize: lockStatusBarContainer.cornerRadius
                color: barBg.color
                corner: RoundCorner.CornerEnum.TopRight 
                visible: barBg.showBg && lockStatusBarContainer.isCentered
            }
            RoundCorner {
                anchors { left: parent.right; top: parent.top; topMargin: lockStatusBarContainer.cornerRadius }
                implicitSize: lockStatusBarContainer.cornerRadius
                color: barBg.color
                corner: RoundCorner.CornerEnum.TopLeft
                visible: barBg.showBg && lockStatusBarContainer.isCentered
            }
        }

        // 2. Gradient overlay
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: parent.height
            color: "transparent"
            opacity: !barBg.showBg && (Config.ready && Config.options.statusBar ? (Config.options.statusBar.useGradient ?? true) : true) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            
            gradient: Gradient {
                GradientStop { position: 0.0; color: Appearance.colors.colStatusBarGradientStart }
                GradientStop { position: 1.0; color: Appearance.colors.colStatusBarGradientEnd }
            }
        }

        // 3. Center: Dynamic Island Wannabe (Locked Indicator)
        readonly property string islandStyle: Config.options.statusBar?.islandStyle ?? "pill"
        readonly property bool isWaterdrop: islandStyle === "waterdrop"

        Rectangle {
            id: lockIndicatorPill
            anchors.horizontalCenter: parent.horizontalCenter
            
            // Idle: y=6, height=28. Waterdrop: y=0, height=34.
            y: lockStatusBarContainer.isWaterdrop ? 0 : 6 * Appearance.effectiveScale
            height: lockStatusBarContainer.isWaterdrop ? 34 * Appearance.effectiveScale : 28 * Appearance.effectiveScale
            width: lockedContent.implicitWidth + (24 * Appearance.effectiveScale)
            color: "black"
            radius: height / 2

            // The "Flattener" - Square off the top part for Waterdrop
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                height: parent.radius
                color: "black"
                visible: lockStatusBarContainer.isWaterdrop
            }

            // Concave Corners for Waterdrop
            RoundCorner {
                anchors.right: parent.left; anchors.top: parent.top
                implicitSize: 12 * Appearance.effectiveScale; color: "black"; corner: RoundCorner.CornerEnum.TopRight
                visible: lockStatusBarContainer.isWaterdrop
            }

            RoundCorner {
                anchors.left: parent.right; anchors.top: parent.top
                implicitSize: 12 * Appearance.effectiveScale; color: "black"; corner: RoundCorner.CornerEnum.TopLeft
                visible: lockStatusBarContainer.isWaterdrop
            }

            Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

            RowLayout {
                id: lockedContent
                anchors.centerIn: parent
                spacing: 6 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "lock"
                    iconSize: 14 * Appearance.effectiveScale
                    color: Appearance.colors.colNotchText
                    fill: 1
                }
                StyledText {
                    text: "Locked"
                    font.pixelSize: 12 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colNotchText
                }
            }
        }

        // 4. Content
        Item {
            id: lockStatusBarContent
            anchors.fill: parent
            
            // Left: User + Network
            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: lockStatusBarContainer.sidePadding + (lockStatusBarContainer.isCentered ? 12 * Appearance.effectiveScale : 0)
                spacing: 8 * Appearance.effectiveScale
                StyledText {
                    text: SystemInfo.username + "  •  " + (Network.wifiEnabled ? (Network.networkName || "Offline") : "WiFi Off")
                    font.pixelSize: 14 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: lockStatusBarContainer.contentColor
                }
            }

            // Right: System Icons
            RowLayout {
                anchors.right: privacyIndicator.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 10 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                // Notifications
                Item {
                    visible: Notifications.unread > 0
                    width: 20 * Appearance.effectiveScale; height: 20 * Appearance.effectiveScale
                    MaterialSymbol {
                        id: lockBellIcon
                        anchors.centerIn: parent
                        text: "notifications_active"
                        iconSize: 16 * Appearance.effectiveScale
                        fill: 1
                        color: lockStatusBarContainer.contentColor
                    }
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: -2 * Appearance.effectiveScale
                        anchors.rightMargin: -2 * Appearance.effectiveScale
                        width: Math.max(12 * Appearance.effectiveScale, badgeText.implicitWidth + 4 * Appearance.effectiveScale)
                        height: 12 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: lockBellIcon.color
                        StyledText {
                            id: badgeText
                            anchors.centerIn: parent
                            text: Notifications.unread > 99 ? "99+" : Notifications.unread.toString()
                            font.pixelSize: 8 * Appearance.effectiveScale
                            font.weight: Font.DemiBold
                            color: barBg.showBg ? Appearance.m3colors.m3surface : Appearance.colors.colLayer0
                        }
                    }
                }

                // WiFi
                MaterialSymbol {
                    text: Network.materialSymbol
                    iconSize: 16 * Appearance.effectiveScale
                    fill: 1
                    color: lockStatusBarContainer.contentColor
                }

                // Bluetooth
                MaterialSymbol {
                    visible: BluetoothStatus.available
                    text: BluetoothStatus.materialSymbol
                    iconSize: 16 * Appearance.effectiveScale
                    fill: BluetoothStatus.connected ? 1 : 0
                    color: lockStatusBarContainer.contentColor
                }

                // Battery
                BatteryIndicator {
                    visible: Battery.available
                    Layout.alignment: Qt.AlignVCenter
                    color: lockStatusBarContainer.contentColor
                }

                // DND Indicator
                MaterialSymbol {
                    visible: Notifications.silent
                    text: "notifications_paused"
                    iconSize: 16 * Appearance.effectiveScale
                    fill: 1
                    color: lockStatusBarContainer.contentColor
                }
            }

            // Privacy Indicator
            PrivacyIndicator {
                id: privacyIndicator
                anchors.right: parent.right
                anchors.rightMargin: lockStatusBarContainer.sidePadding + (lockStatusBarContainer.isCentered ? 8 * Appearance.effectiveScale : -2 * Appearance.effectiveScale)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ── Screen Rounding (Matching system config) ──
    RoundCorner {
        anchors.top: parent.top; anchors.left: parent.left
        corner: RoundCorner.CornerEnum.TopLeft
        implicitSize: Math.round((Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20) * Appearance.effectiveScale)
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
    RoundCorner {
        anchors.top: parent.top; anchors.right: parent.right
        corner: RoundCorner.CornerEnum.TopRight
        implicitSize: Math.round((Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20) * Appearance.effectiveScale)
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
    RoundCorner {
        anchors.bottom: parent.bottom; anchors.left: parent.left
        corner: RoundCorner.CornerEnum.BottomLeft
        implicitSize: Math.round((Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20) * Appearance.effectiveScale)
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
    RoundCorner {
        anchors.bottom: parent.bottom; anchors.right: parent.right
        corner: RoundCorner.CornerEnum.BottomRight
        implicitSize: Math.round((Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20) * Appearance.effectiveScale)
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
}
