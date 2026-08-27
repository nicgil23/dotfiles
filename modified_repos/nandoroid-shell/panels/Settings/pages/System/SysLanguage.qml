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
                text: I18nService.tr("Language & Localization")
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Language Info Card
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: wrapperLayout.implicitHeight + (32 * Appearance.effectiveScale)
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            ColumnLayout {
                id: wrapperLayout
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16 * Appearance.effectiveScale

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
                            text: I18nService.tr("Localization Service")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: I18nService.tr("I18n backend is available, but full UI string translation is currently unmaintained.")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    // Native SegmentedButton (Always Active)
                    SegmentedButton {
                        isHighlighted: true
                        buttonText: "English (US)"
                    }
                }
            }
        }
    }
}
