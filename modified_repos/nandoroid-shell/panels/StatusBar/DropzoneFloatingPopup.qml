import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"
import "../../widgets"

/**
 * Floating Dropzone HUD window for M3 status bar style.
 * Displays stashed files and actions in a floating panel below the bar with expressive spring animations.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelWindow
        required property var modelData
        screen: modelData

        readonly property bool isM3: Config.ready && Config.options.statusBar ? (Config.options.statusBar.moduleStyle === "m3" || Config.options.statusBar.islandStyle === "m3") : false

        visible: isM3 && (GlobalStates.dropzoneNotchOpen || contentCard.opacity > 0)

        WlrLayershell.namespace: "nandoroid:dropzone-hud"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            onPressed: GlobalStates.dropzoneNotchOpen = false
        }

        Item {
            id: container
            anchors.horizontalCenter: parent.horizontalCenter
            y: GlobalStates.dropzoneNotchOpen ? 52 * Appearance.effectiveScale : 38 * Appearance.effectiveScale
            width: contentCard.width
            height: contentCard.height

            Behavior on y {
                NumberAnimation {
                    duration: GlobalStates.dropzoneNotchOpen ? 300 : 200
                    easing.type: GlobalStates.dropzoneNotchOpen ? Easing.OutBack : Easing.OutQuad
                    easing.overshoot: 1.1
                }
            }

            // Drop shadow for floating card elevation
            DropShadow {
                anchors.fill: contentCard
                horizontalOffset: 0
                verticalOffset: 6 * Appearance.effectiveScale
                radius: 20 * Appearance.effectiveScale
                samples: 25
                color: Functions.ColorUtils.applyAlpha("#000000", 0.45)
                source: contentCard
                opacity: contentCard.opacity
            }

            Rectangle {
                id: contentCard
                width: Math.min(520 * Appearance.effectiveScale, panelWindow.width * 0.92)
                height: Math.min(500 * Appearance.effectiveScale, dropzoneContent.implicitHeight + (24 * Appearance.effectiveScale))
                radius: 16 * Appearance.effectiveScale
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.14)
                clip: true

                transformOrigin: Item.Top

                opacity: GlobalStates.dropzoneNotchOpen ? 1 : 0
                scale: GlobalStates.dropzoneNotchOpen ? 1 : 0.90

                Behavior on opacity {
                    NumberAnimation {
                        duration: GlobalStates.dropzoneNotchOpen ? 250 : 180
                        easing.type: Easing.OutQuint
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: GlobalStates.dropzoneNotchOpen ? 320 : 200
                        easing.type: GlobalStates.dropzoneNotchOpen ? Easing.OutBack : Easing.OutQuart
                        easing.overshoot: 1.15
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuint
                    }
                }

                // Prevent clicks inside card from closing HUD
                MouseArea {
                    anchors.fill: parent
                    onPressed: (mouse) => mouse.accepted = true
                }

                // Accept drag and drop files directly onto HUD
                DropArea {
                    anchors.fill: parent
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

                DropzoneNotchPopup {
                    id: dropzoneContent
                    anchors.fill: parent
                    anchors.margins: 12 * Appearance.effectiveScale
                    spacing: 8 * Appearance.effectiveScale
                    opacity: GlobalStates.dropzoneNotchOpen ? 1 : 0
                    scale: GlobalStates.dropzoneNotchOpen ? 1 : 0.96
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                    Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
                }
            }
        }
    }
}
