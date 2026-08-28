import "core"
import "core/functions" as Functions
import "widgets"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * Navigation sidebar for the Settings panel.
 * Uses a NavigationRail style common in modern Android apps.
 */
Rectangle {
    id: root
    implicitWidth: expanded ? 220 * Appearance.effectiveScale : 72 * Appearance.effectiveScale
    color: Appearance.colors.colLayer0
    
    property bool expanded: true
    property int currentIndex: 0
    signal pageSelected(int index)

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    onCurrentIndexChanged: {
        tabHighlight.idx1 = currentIndex
        Qt.callLater(() => { tabHighlight.idx2 = currentIndex })
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 48 * Appearance.effectiveScale
            buttonRadius: 16 * Appearance.effectiveScale
            colBackground: Appearance.colors.colPrimary
            colBackgroundHover: Appearance.colors.colPrimaryHover
            colRipple: Functions.ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.88)
            visible: root.expanded
            
            onClicked: {
                let path = Directories.shellConfigPath;
                if (!Qt.openUrlExternally("file://" + path)) {
                    Quickshell.execDetached(["xdg-open", path]);
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "edit"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colOnPrimary
                }
                StyledText {
                    text: "Config file"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
        
        // Gap below config button
        Item { Layout.preferredHeight: 12 * Appearance.effectiveScale }
        
        // Icon for collapsed state
        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: "settings"
            iconSize: 24 * Appearance.effectiveScale
            color: Appearance.colors.colPrimary
            visible: !root.expanded
        }

        // Navigation Items
        Item {
            id: navItemsWrapper
            Layout.fillWidth: true
            implicitHeight: navItemsColumn.implicitHeight

            // Animated stretch-highlight pill (Ambxst style)
            Rectangle {
                id: tabHighlight
                x: 0
                width: parent.width
                radius: 16 * Appearance.effectiveScale
                color: Appearance.colors.colPrimaryContainer

                property int idx1: root.currentIndex
                property int idx2: root.currentIndex

                function getYForIndex(i) {
                    return i * (48 * Appearance.effectiveScale + 8 * Appearance.effectiveScale)
                }

                property real targetY1: getYForIndex(idx1)
                property real targetY2: getYForIndex(idx2)
                property real animY1: targetY1
                property real animY2: targetY2

                y: Math.min(animY1, animY2)
                height: Math.abs(animY2 - animY1) + (48 * Appearance.effectiveScale)

                Behavior on animY1 {
                    NumberAnimation { duration: 120; easing.type: Easing.OutSine }
                }
                Behavior on animY2 {
                    NumberAnimation { duration: 380; easing.type: Easing.OutCubic }
                }

                onTargetY1Changed: animY1 = targetY1
                onTargetY2Changed: animY2 = targetY2

                onIdx1Changed: { targetY1 = getYForIndex(idx1) }
                onIdx2Changed: { targetY2 = getYForIndex(idx2) }
            }

            ColumnLayout {
                id: navItemsColumn
                anchors.fill: parent
                spacing: 8 * Appearance.effectiveScale

                Repeater {
                    model: [
                        { name: "Network", icon: "wifi" },
                        { name: "Bluetooth", icon: "bluetooth" },
                        { name: "Audio", icon: "volume_up" },
                        { name: "Display", icon: "monitor" },
                        { name: "Style", icon: "palette" },
                        { name: "Widgets", icon: "widgets" },
                        { name: "System", icon: "settings_applications" },
                        { name: "Services", icon: "cloud" },
                        { name: "Profile", icon: "person" },
                        { name: "About", icon: "info" }
                    ]

                    delegate: RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 48 * Appearance.effectiveScale
                        buttonRadius: 16 * Appearance.effectiveScale
                        colBackground: "transparent"
                        colBackgroundHover: root.currentIndex === index 
                            ? "transparent"
                            : Appearance.colors.colLayer0Hover
                        
                        onClicked: {
                            root.pageSelected(index)
                        }


                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: root.expanded ? 16 * Appearance.effectiveScale : 0
                            spacing: 16 * Appearance.effectiveScale

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignCenter
                                text: modelData.icon
                                iconSize: 24 * Appearance.effectiveScale
                                color: root.currentIndex === index 
                                    ? Appearance.colors.colOnPrimaryContainer 
                                    : Appearance.colors.colSubtext
                            }

                            StyledText {
                                visible: root.expanded
                                Layout.fillWidth: true
                                text: modelData.name
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: root.currentIndex === index ? Font.Medium : Font.Normal
                                color: root.currentIndex === index 
                                    ? Appearance.colors.colOnPrimaryContainer 
                                    : Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
