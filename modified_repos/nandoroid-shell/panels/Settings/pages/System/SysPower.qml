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
        searchString: "Power Management"
        aliases: ["Power Profile", "Battery", "Custom Power", "Ryzen", "Power Mode"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 4 * Appearance.effectiveScale
            MaterialSymbol {
                text: "bolt"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Power Profile"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // 1. Enable Toggle Card
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: powerEnableRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            forceLast: false
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: powerEnableRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Custom Power Profile"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Enable overriding system power modes via a local file."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                AndroidToggle {
                        checked: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled)
                        onToggled: {
                            if (Config.ready && Config.options.powerProfile) {
                                Config.options.powerProfile.enabled = !Config.options.powerProfile.enabled;
                    }
                    }
                }
            }
        }

        // 2. Custom Path Card
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: powerPathRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            forceFirst: false
            forceLast: true
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh
            opacity: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled) ? 1.0 : 0.4
            enabled: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled)
            Behavior on opacity { NumberAnimation { duration: 200 } }

            RowLayout {
                id: powerPathRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    Layout.maximumWidth: 400 * Appearance.effectiveScale
                    StyledText {
                        text: "Custom Profile Path"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "The exact path to write custom profile strings."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                Item { Layout.fillWidth: true }

                StyledTextInput {
                    id: powerPathInput
                    Layout.preferredWidth: 250 * Appearance.effectiveScale
                    Layout.preferredHeight: 48 * Appearance.effectiveScale
                    text: (Config.ready && Config.options.powerProfile) ? Functions.FileUtils.shortenHomePath(Config.options.powerProfile.customPath) : "/tmp/ryzen_mode"
                    placeholder: "Enter path (e.g., /tmp/ryzen_mode)"
                    onEditingFinished: { 
                        if (Config.ready && Config.options.powerProfile) {
                            Config.options.powerProfile.customPath = Functions.FileUtils.expandHomePath(text);
                        }
                    }
                }
            }
        }
    }
}

