import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    SearchHandler {
        searchString: "Language"
        aliases: ["Translation", "Translate", "trans", "Bahasa", "Language Settings"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 4 * Appearance.effectiveScale
            MaterialSymbol {
                text: "translate"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Language"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Coming Soon Card
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: langComingRow.implicitHeight + (48 * Appearance.effectiveScale)
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: langComingRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                // Icon indicator
                MaterialSymbol {
                    text: "language"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    Layout.fillWidth: true

                    StyledText {
                        text: "Language & Translation"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Shell language and translate-shell service settings."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                Item { Layout.fillWidth: true }

                // Coming Soon badge
                Rectangle {
                    implicitHeight: 28 * Appearance.effectiveScale
                    implicitWidth: comingSoonLabel.implicitWidth + (20 * Appearance.effectiveScale)
                    radius: 14 * Appearance.effectiveScale
                    color: Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)

                    StyledText {
                        id: comingSoonLabel
                        anchors.centerIn: parent
                        text: "Coming Soon"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colPrimary
                    }
                }
            }
        }
    }
}
