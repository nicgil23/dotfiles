import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import qs.widgets

/**
 * Refined Performance monitor island for the Quick Settings panel.
 * Displays real-time CPU, Temperature, RAM, Swap, and Multiple Disk usage via SystemData.
 */
Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + (24 * Appearance.effectiveScale)
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    ColumnLayout {
        id: mainLayout
        anchors {
            fill: parent
            margins: 12 * Appearance.effectiveScale
        }
        spacing: 12 * Appearance.effectiveScale

        // Top Row: 4 key metrics with background pills
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale

            StatItem {
                statIcon: "monitoring"
                label: "CPU"
                value: SystemData.cpuUsage
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 1;
                    GlobalStates.activateSystemMonitor();
                }
            }

            StatItem {
                statIcon: "thermostat"
                label: "TEMP"
                value: SystemData.cpuTemperature
                isTemperature: true
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 1;
                    GlobalStates.activateSystemMonitor();
                }
            }

            StatItem {
                statIcon: "memory"
                label: "RAM"
                value: SystemData.memUsage
                valText: (SystemData.usedMemoryMB / 1024).toFixed(1) + "GB"
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 3;
                    GlobalStates.activateSystemMonitor();
                }
            }

            StatItem {
                statIcon: "swap_horiz"
                label: "SWAP"
                value: SystemData.swapUsage
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 3;
                    GlobalStates.activateSystemMonitor();
                }
            }
        }

    }

    // StatItem: Icon, Label, and Value inside a stylized pill container
    component StatItem: RippleButton {
        id: statItem
        property string statIcon
        property string label
        property real value: 0
        property string valText: ""
        property bool isTemperature: false
        
        implicitHeight: 64 * Appearance.effectiveScale
        buttonRadius: 16 * Appearance.effectiveScale
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer2
        
        contentItem: ColumnLayout {
            spacing: 6 * Appearance.effectiveScale

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4 * Appearance.effectiveScale
                MaterialSymbol {
                    text: statItem.statIcon
                    iconSize: 14 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3primary
                }
                StyledText {
                    text: statItem.label
                    font.pixelSize: 10 * Appearance.effectiveScale
                    font.weight: Font.Bold
                    color: Appearance.m3colors.m3outline
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 20 * Appearance.effectiveScale
                radius: 10 * Appearance.effectiveScale
                color: Appearance.colors.colLayer2

                StyledText {
                    anchors.centerIn: parent
                    text: {
                        if (statItem.valText !== "") return statItem.valText;
                        if (statItem.isTemperature) return (statItem.value > 0 ? `${Math.round(statItem.value)}°C` : "--");
                        return `${Math.round(statItem.value * 100)}%`;
                    }
                    font.pixelSize: 10 * Appearance.effectiveScale
                    font.weight: Font.Black
                    color: Appearance.m3colors.m3onSurface
                }
            }
        }
    }
}
