import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../services"
import "../../../widgets"
import ".."

/**
 * Memory detail page for System Monitor.
 */
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20 * Appearance.effectiveScale
        spacing: 20 * Appearance.effectiveScale

        StyledText {
            text: "Memory Performance"
            font.pixelSize: Appearance.font.pixelSize.huge
            font.weight: Font.DemiBold
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.colors.colLayer2
            radius: 16 * Appearance.effectiveScale
            border.width: 0
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2 * Appearance.effectiveScale
                        StyledText { text: "Total RAM: " + (SystemData.totalMemoryMB / 1024).toFixed(1) + " GB"; font.pixelSize: Appearance.font.pixelSize.normal; font.weight: Font.Medium; color: Appearance.m3colors.m3onSurface }
                        StyledText { text: "Used: " + (SystemData.usedMemoryMB / 1024).toFixed(1) + " GB"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                    }
                    Item { Layout.fillWidth: true }
                    StyledText { 
                        text: Math.round(SystemData.memUsage * 100) + "%"
                        font.pixelSize: Math.round(32 * Appearance.effectiveScale)
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colSecondary
                    }
                }
                
                PerformanceGraph {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    history: SystemData.memHistory
                    lineColor: Appearance.colors.colSecondary
                    fillColor: Appearance.colors.colSecondary
                    maxValue: 100
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { text: "Swap Usage: " + Math.round(SystemData.swapUsage * 100) + "%"; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
