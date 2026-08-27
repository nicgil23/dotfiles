import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"

import "pages"

/**
 * PerformancePage manages sub-navigation for system metrics.
 * Designed with clean, compact 1-row card buttons in native NANDoroid style.
 */
Item {
    id: root
    property int subIndex: 0

    // Reset to Overview (0) when System Monitor closes
    Connections {
        target: GlobalStates
        function onSystemMonitorOpenChanged() {
            if (!GlobalStates.systemMonitorOpen) {
                root.subIndex = 0;
                GlobalStates.performanceSubIndex = 0;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale
        
        // Horizontal Tab Bar (Compact 1-row Card Buttons)
        RowLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            Repeater {
                model: [
                    { name: "Overview", icon: "dashboard" },
                    { name: "CPU", icon: "monitoring" },
                    { name: "GPU", icon: "videogame_asset" },
                    { name: "Memory", icon: "memory" },
                    { name: "Network", icon: "public" },
                    { name: "Disk", icon: "storage" }
                ]

                delegate: RippleButton {
                    id: tabBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38 * Appearance.effectiveScale
                    
                    readonly property bool isSelected: GlobalStates.performanceSubIndex === index
                    buttonRadius: isSelected ? 19 * Appearance.effectiveScale : 12 * Appearance.effectiveScale
                    Behavior on buttonRadius { NumberAnimation { duration: 150 } }

                    colBackground: isSelected 
                        ? Appearance.colors.colPrimary 
                        : Appearance.m3colors.m3surfaceContainerHigh
                    colRipple: Appearance.colors.colPrimary

                    onClicked: GlobalStates.performanceSubIndex = index

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: modelData.icon
                            iconSize: 18 * Appearance.effectiveScale
                            color: tabBtn.isSelected 
                                ? Appearance.colors.colOnPrimary 
                                : Appearance.colors.colOnLayer1
                            Layout.alignment: Qt.AlignVCenter
                        }

                        StyledText {
                            text: modelData.name
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: tabBtn.isSelected 
                                ? Appearance.colors.colOnPrimary 
                                : Appearance.colors.colOnLayer1
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }
        }
        
        // Content Area
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: GlobalStates.performanceSubIndex
            
            OverviewPage {}
            CpuPage {}
            GpuPage {}
            MemoryPage {}
            NetworkPage {}
            DiskPage {}
        }
    }
}
