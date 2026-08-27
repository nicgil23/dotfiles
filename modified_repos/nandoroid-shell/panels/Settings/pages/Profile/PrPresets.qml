import "../../../../core"
import "../../../../core/functions" as Functions
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    SearchHandler {
        searchString: "Presets"
        aliases: ["Save Config", "Load Config", "Configuration Snapshots", "Backup Settings"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 4 * Appearance.effectiveScale
            MaterialSymbol {
                text: "wall_art"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Presets"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: saveRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: saveRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Save Current Config"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Save a snapshot of your current config."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.WordWrap
                    }
                }

                Item { Layout.fillWidth: true }

                StyledTextInput {
                    id: presetNameInput
                    placeholder: "Preset name"
                    onEditingFinished: savePreset()
                }

                RippleButton {
                    implicitWidth: 48 * Appearance.effectiveScale
                    implicitHeight: 48 * Appearance.effectiveScale
                    buttonRadius: 24 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3primaryContainer
                    enabled: presetNameInput.text.trim().replace(/\s/g, "_").length > 0

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "save"
                        iconSize: 22 * Appearance.effectiveScale
                        color: parent.enabled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colSubtext
                    }
                    onClicked: savePreset()
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 24 * Appearance.effectiveScale
            visible: presetsModel.count === 0
            horizontalAlignment: Text.AlignHCenter
            text: "No presets yet"
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.normal
        }

        Flow {
            id: presetsFlow
            Layout.fillWidth: true
            Layout.topMargin: 16 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale
            visible: presetsModel.count > 0

            property real cardWidth: 240 * Appearance.effectiveScale

            onWidthChanged: Qt.callLater(() => {
                const sp = presetsFlow.spacing
                const available = presetsFlow.width - 2 * sp
                if (available > 0) presetsFlow.cardWidth = Math.floor(available / 3)
            })
            Component.onCompleted: presetsFlow.widthChanged()

            Repeater {
                model: presetsModel

                delegate: Rectangle {
                    id: card
                    required property string fileName
                    required property string filePath
                    required property date fileModified

                    readonly property string fileBaseName: fileName.replace(".json", "")
                    readonly property string presetName: fileBaseName.replace(/_/g, " ")
                    property string presetWallpaper: ""

                    readonly property string cardDate: {
                        try {
                            const d = fileModified
                            const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                            return months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear()
                        } catch (e) {
                            return "Unknown date"
                        }
                    }

                    readonly property real cardRadius: 20 * Appearance.effectiveScale
                    readonly property real imgHeight: 120 * Appearance.effectiveScale

                    width: presetsFlow.cardWidth
                    radius: cardRadius
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: card.width
                            height: card.height
                            radius: card.radius
                        }
                    }

                    FileView {
                        path: filePath
                        onLoaded: {
                            try {
                                const data = JSON.parse(text())
                                presetWallpaper = data?.appearance?.background?.wallpaperPath ?? ""
                            } catch (e) {}
                        }
                    }

                    ColumnLayout {
                        id: cardColumn
                        width: parent.width
                        spacing: 0

                        Rectangle {
                            id: imgCard
                            Layout.fillWidth: true
                            Layout.preferredHeight: imgHeight
                            Layout.bottomMargin: 16 * Appearance.effectiveScale
                            radius: cardRadius
                            color: Appearance.m3colors.m3surfaceContainerLow

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: imgCard.width
                                    height: imgCard.height
                                    radius: imgCard.radius
                                }
                            }

                            Image {
                                id: presetThumb
                                anchors.fill: parent
                                source: presetWallpaper
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(480, 240)
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: presetThumb.status !== Image.Ready
                                text: "wallpaper"
                                iconSize: 40 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12 * Appearance.effectiveScale
                            Layout.rightMargin: 12 * Appearance.effectiveScale
                            Layout.bottomMargin: 10 * Appearance.effectiveScale
                            spacing: 4 * Appearance.effectiveScale

                            StyledText {
                                Layout.fillWidth: true
                                text: presetName
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.Normal
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: "Saved " + cardDate
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 8 * Appearance.effectiveScale
                                spacing: 8 * Appearance.effectiveScale

                                Item { Layout.fillWidth: true }

                                RippleButton {
                                    implicitHeight: 36 * Appearance.effectiveScale
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: "transparent"
                                    colBackgroundHover: Appearance.colors.colLayer2Hover
                                    onClicked: {
                                        deleteProc.command = ["bash", Directories.presetsScriptPath, "--remove", fileBaseName]
                                        deleteProc.running = true
                                    }
                                    contentItem: StyledText {
                                        text: "Delete"
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colError
                                    }
                                }

                                RippleButton {
                                    implicitHeight: 36 * Appearance.effectiveScale
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: "transparent"
                                    colBackgroundHover: Appearance.colors.colLayer2Hover
                                    onClicked: {
                                        GlobalStates.settingsOpen = false
                                        Quickshell.execDetached(["bash", Directories.presetsScriptPath, "--apply", fileBaseName])
                                    }
                                    contentItem: StyledText {
                                        text: "Apply"
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colPrimary
                                    }
                                }
                            }
                        }
                    }

                    height: cardColumn.implicitHeight
                }
            }
        }
    }

    function savePreset() {
        let name = presetNameInput.text.trim().replace(/\s/g, "_")
        if (name.length === 0) return

        saveProc.command = ["bash", Directories.presetsScriptPath, "--save", name]
        saveProc.running = true
        presetNameInput.text = ""
        refreshTimer.restart()
    }

    FolderListModel {
        id: presetsModel
        folder: "file://" + Directories.presetsPath
        showDirs: false
        nameFilters: ["*.json"]
    }

    Timer {
        id: refreshTimer
        interval: 500
        repeat: false
        onTriggered: {
            const current = presetsModel.folder
            presetsModel.folder = ""
            Qt.callLater(() => { presetsModel.folder = current })
        }
    }

    Process {
        id: saveProc
        onExited: refreshTimer.restart()
    }

    Process {
        id: deleteProc
        onExited: refreshTimer.restart()
    }
}
