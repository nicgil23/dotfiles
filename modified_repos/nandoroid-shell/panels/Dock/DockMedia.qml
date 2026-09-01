pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"

/**
 * DockMedia component ported from end4-pC for nandoroid-shell.
 * Compact media player card embedded inside the dock.
 */
Item {
    id: root

    property real cardWidth: 230 * Appearance.effectiveScale
    property real buttonPadding: 5 * Appearance.effectiveScale
    property real artMargin: 5 * Appearance.effectiveScale

    property var player: MprisController.activePlayer

    property var    artUrl:      MprisController.trackArtUrl
    property string trackTitle:  MprisController.trackTitle
    property string trackArtist: MprisController.trackArtist
    property bool   isPlaying:   MprisController.isPlaying
    property bool   hasTrack:    MprisController.hasMedia

    visible:        (Config.ready && Config.options.dock ? (Config.options.dock.showMedia ?? true) : true) && root.hasTrack
    implicitWidth:  root.hasTrack ? root.cardWidth : 0
    implicitHeight: parent?.height ?? (48 * Appearance.effectiveScale)

    Behavior on implicitWidth {
        NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic }
    }

    StyledRectangularShadow {
        target: card
    }

    Rectangle {
        id: card
        anchors.fill:         parent
        anchors.topMargin:    4 * Appearance.effectiveScale
        anchors.bottomMargin: 4 * Appearance.effectiveScale
        anchors.leftMargin:   4 * Appearance.effectiveScale
        anchors.rightMargin:  4 * Appearance.effectiveScale
        radius: Appearance.rounding.normal
        color:  "transparent"

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width:  card.width
                height: card.height
                radius: card.radius
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Functions.ColorUtils.applyAlpha(MprisController.dynLayer0, 0.85)
            z: 0
        }

        // Blurred art background
        Image {
            id: blurredArt
            anchors.fill: parent
            source: MprisController.displayedArtFilePath
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true
            asynchronous: true
            z: 1
            visible: MprisController._artDownloaded && source !== ""
        }

        FastBlur {
            anchors.fill: blurredArt
            source: blurredArt
            radius: 32
            z: 1
            visible: blurredArt.visible
        }

        // Tint overlay
        Rectangle {
            anchors.fill: parent
            color: Functions.ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.45)
            z: 2
        }

        RowLayout {
            anchors.fill: parent
            clip: true
            spacing: 6 * Appearance.effectiveScale
            z: 3

            // Album Art Thumbnail
            Rectangle {
                id: artRect
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 6 * Appearance.effectiveScale
                implicitWidth: 34 * Appearance.effectiveScale
                implicitHeight: 34 * Appearance.effectiveScale
                color: Functions.ColorUtils.applyAlpha(Appearance.colors.colLayer1, 0.5)
                radius: Appearance.rounding.small

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width:  artRect.width
                        height: artRect.height
                        radius: artRect.radius
                    }
                }

                StyledImage {
                    anchors.fill: parent
                    source: MprisController.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    sourceSize.width:  artRect.width
                    sourceSize.height: artRect.height
                    visible: source !== ""
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "music_note"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colOnLayer0
                    visible: !MprisController._artDownloaded || MprisController.displayedArtFilePath === ""
                }
            }

            // Artist + Title
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: -2

                Item { Layout.fillHeight: true }

                StyledText {
                    Layout.fillWidth: true
                    text: root.trackArtist !== "" ? root.trackArtist : "Music"
                    font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Functions.StringUtils.cleanMusicTitle(root.trackTitle) || "Untitled"
                    font.pixelSize: Math.round(13 * Appearance.effectiveScale)
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    opacity: 0.9
                }

                Item { Layout.fillHeight: true }
            }

            // Media Control Buttons
            RowLayout {
                Layout.rightMargin: 6 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                spacing: 3 * Appearance.effectiveScale

                // Play / Pause
                RippleButton {
                    implicitWidth: 28 * Appearance.effectiveScale
                    implicitHeight: 28 * Appearance.effectiveScale
                    buttonRadius: root.isPlaying ? Appearance.rounding.small : implicitWidth / 2
                    colBackground: root.isPlaying ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                    colBackgroundHover: root.isPlaying ? Appearance.colors.colPrimaryHover : Appearance.colors.colSecondaryContainerHover
                    colRipple: root.isPlaying ? Appearance.colors.colPrimaryActive : Appearance.colors.colSecondaryContainerActive
                    onClicked: MprisController.togglePlaying()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: root.isPlaying ? "pause" : "play_arrow"
                        iconSize: 18 * Appearance.effectiveScale
                        color: root.isPlaying ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnSecondaryContainer
                    }
                }

                // Next
                RippleButton {
                    implicitWidth: 26 * Appearance.effectiveScale
                    implicitHeight: 26 * Appearance.effectiveScale
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    onClicked: MprisController.next()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: "skip_next"
                        iconSize: 18 * Appearance.effectiveScale
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }
        }
    }
}
