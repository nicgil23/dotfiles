import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    focus: true

    readonly property real baseScale: (Appearance.sizes.screen.height / 1080) * Appearance.effectiveScale

    readonly property var actions: [
        { icon: "lock",                text: "Lock",     exec: function() { Session.lock(); GlobalStates.sessionOpen = false; } },
        { icon: "bedtime",             text: "Sleep",    exec: function() { Session.suspend(); GlobalStates.sessionOpen = false; } },
        { icon: "developer_board",     text: "UEFI",     exec: function() { Session.rebootToFirmware(); GlobalStates.sessionOpen = false; } },
        { icon: "power_settings_new",  text: "Shutdown", exec: function() { Session.poweroff(); GlobalStates.sessionOpen = false; } },
        { icon: "restart_alt",         text: "Reboot",   exec: function() { Session.reboot(); GlobalStates.sessionOpen = false; } }
    ]

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.sessionOpen = false;
        } else if (event.key === Qt.Key_Left) {
            sessionCarousel.hoveredIndex = -1;
            sessionCarousel.currentIndex = (sessionCarousel.currentIndex - 1 + actions.length) % actions.length;
        } else if (event.key === Qt.Key_Right) {
            sessionCarousel.hoveredIndex = -1;
            sessionCarousel.currentIndex = (sessionCarousel.currentIndex + 1) % actions.length;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            actions[sessionCarousel.currentIndex].exec();
        }
    }

    readonly property real itemH: 185 * root.baseScale
    readonly property real baseItemW: 135 * root.baseScale
    readonly property real activeBonusW: 18 * root.baseScale
    readonly property real itemSp: 8 * root.baseScale
    readonly property real contentW: actions.length * baseItemW + activeBonusW + (actions.length - 1) * itemSp

    Rectangle {
        anchors.centerIn: parent
        width: contentW + 2 * 14 * root.baseScale
        height: itemH + 2 * 14 * root.baseScale
        radius: Appearance.rounding.panel
        color: Appearance.colors.colLayer0

        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)

        Carousel {
            id: sessionCarousel
            anchors.fill: parent
            anchors.margins: 14 * root.baseScale
            model: root.actions
            fitMode: true
            baseItemWidth: root.baseItemW
            activeBonusWidth: root.activeBonusW
            itemSpacing: root.itemSp
            hoverSelectsIndex: true
            wheelEnabled: false
            dragEnabled: false
            showCurrentIndicator: false
            showFooter: false
            isOpen: false
            clipRadius: Appearance.rounding.large

            delegate: Component {
                Item {
                    id: delegateRoot
                    readonly property bool isFocused: index === sessionCarousel.focusedIndex

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(Appearance.rounding.large, width / 4)
                        color: isFocused ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHighest

                        Behavior on color { ColorAnimation { duration: 150 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8 * root.baseScale

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData ? modelData.icon : ""
                                iconSize: 32 * root.baseScale
                                fill: 1
                                color: isFocused ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.maximumWidth: delegateRoot.width - 6 * root.baseScale
                                text: modelData ? modelData.text : ""
                                font.pixelSize: Math.max(11, Math.round(13 * root.baseScale))
                                font.weight: Font.Medium
                                color: isFocused ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
            }

            onItemSelected: index => root.actions[index].exec()
        }
    }

    states: State {
        when: GlobalStates.sessionOpen
        PropertyChanges { target: sessionCarousel; isOpen: true }
    }
}
