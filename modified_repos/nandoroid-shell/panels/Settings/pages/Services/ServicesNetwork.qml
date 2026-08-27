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
    id: root
    Layout.fillWidth: true
    spacing: 0
    
    SearchHandler { 
        searchString: "Network Status"
        aliases: ["Speed Meter", "Bandwidth", "Internet", "Ethernet"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "network_check"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Network Status"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: netSpeedRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            RowLayout {
                id: netSpeedRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Show Network Speed"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Display real-time upload and download speeds in the status bar."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                AndroidToggle {
                    checked: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
                    onToggled: {
                        if (Config.ready && Config.options.bar) {
                            Config.options.bar.show_network_speed = !Config.options.bar.show_network_speed;
                        }
                    }
                }
            }
        }

        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: netUnitRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            opacity: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed) ? 1.0 : 0.4
            enabled: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
            Behavior on opacity { NumberAnimation { duration: 200 } }

            RowLayout {
                id: netUnitRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Starting Unit"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Select the default unit for speed measurements."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 4 * Appearance.effectiveScale
                    Layout.preferredHeight: 40 * Appearance.effectiveScale
                    
                    Repeater {
                        model: ["B", "KB", "MB"]
                        delegate: SegmentedButton {
                            isHighlighted: (Config.ready && Config.options.bar) ? Config.options.bar.network_speed_unit === modelData : false
                            Layout.fillHeight: true
                            
                            buttonText: modelData
                            leftPadding: 32 * Appearance.effectiveScale
                            rightPadding: 32 * Appearance.effectiveScale
                            
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            
                            onClicked: {
                                if (Config.ready && Config.options.bar) {
                                    Config.options.bar.network_speed_unit = modelData;
                                }
                            }
                        }
                    }
                }
            }
        }

        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: netIntervalRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            opacity: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed) ? 1.0 : 0.4
            enabled: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
            Behavior on opacity { NumberAnimation { duration: 200 } }

            RowLayout {
                id: netIntervalRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Update Interval"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "How often to poll network speeds."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                Item { Layout.fillWidth: true }

                StyledSlider {
                    id: intervalSlider
                    Layout.preferredWidth: 200 * Appearance.effectiveScale
                    Layout.maximumWidth: 200 * Appearance.effectiveScale
                    value: Config.ready ? Config.options.bar.networkSpeedInterval : 3000
                    defaultValue: 3000
                    from: 1000; to: 10000; stepSize: 500
                    onMoved: if (Config.ready) Config.options.bar.networkSpeedInterval = Math.round(value)
                }

                StyledText {
                    text: {
                        let ms = Config.ready ? Config.options.bar.networkSpeedInterval : 3000;
                        if (ms < 2000) return ms + "ms";
                        return (ms / 1000).toFixed(ms % 1000 === 0 ? 0 : 1) + "s";
                    }
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    Layout.preferredWidth: 48 * Appearance.effectiveScale
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
