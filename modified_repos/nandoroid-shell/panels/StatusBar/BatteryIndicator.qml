import qs.core
import qs.widgets
import qs.services
import qs.core.functions
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property color color: Appearance.colors.colStatusBarText
    visible: Battery.available
    
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= (Config.options.battery?.low ?? 20) / 100

    implicitWidth: batteryProgress.implicitWidth + (4 * Appearance.effectiveScale)
    implicitHeight: 24 * Appearance.effectiveScale

    RowLayout {
        anchors.centerIn: parent
        spacing: 1 * Appearance.effectiveScale

        ClippedProgressBar {
            id: batteryProgress
            valueBarWidth: 26 * Appearance.effectiveScale
            valueBarHeight: 14 * Appearance.effectiveScale
            Layout.alignment: Qt.AlignVCenter
            
            radius: 4.5 * Appearance.effectiveScale // Soft squircle shape from reference
            
            value: percentage
            highlightColor: {
                 if (isCharging) return Appearance.colors.colBatteryCharging
                 if (isLow) return Appearance.colors.colBatteryLow
                 return root.color
            }
            trackColor: {
                if (isLow && !isCharging) return Appearance.colors.colBatteryLowTrack
                return Appearance.colors.colBatteryTrack
            }
            
            // Custom text mask to include the bolt icon
            textMask: Item {
                width: batteryProgress.valueBarWidth
                height: batteryProgress.valueBarHeight

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    MaterialSymbol {
                        id: boltIcon
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: -2 * Appearance.effectiveScale
                        Layout.rightMargin: -2 * Appearance.effectiveScale
                        fill: 1
                        text: "bolt"
                        iconSize: 8 * Appearance.effectiveScale
                        visible: isCharging
                        color: (isLow && !isCharging) ? "#FFFFFF" : root.color
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        font.pixelSize: 10 * Appearance.effectiveScale
                        Layout.topMargin: 3 * Appearance.effectiveScale
                        font.weight: Font.DemiBold
                        text: batteryProgress.text
                        color: (isLow && !isCharging) ? "#FFFFFF" : root.color
                    }
                }
            }
        }

        // Battery Tip
        Rectangle {
            Layout.preferredWidth: 2 * Appearance.effectiveScale
            Layout.preferredHeight: 6 * Appearance.effectiveScale
            Layout.alignment: Qt.AlignVCenter
            radius: 1 * Appearance.effectiveScale
            color: (percentage >= 0.98) ? batteryProgress.highlightColor : batteryProgress.trackColor
        }
    }
}
