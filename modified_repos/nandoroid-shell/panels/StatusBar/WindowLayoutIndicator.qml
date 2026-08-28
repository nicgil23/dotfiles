import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../services"
import "../../widgets"

Item {
    id: root
    property color color: Appearance.colors.colStatusBarText
    property color subtextColor: Appearance.colors.colStatusBarSubtext

    readonly property string currentLayout: GlobalStates.hyprlandLayout || "dwindle"

    readonly property string layoutIcon: {
        switch (currentLayout) {
            case "dwindle": return "view_quilt"
            case "master": return "splitscreen"
            case "scrolling": return "view_column"
            default: return "grid_view"
        }
    }

    readonly property real iconSizePx: 20 * Appearance.effectiveScale
    implicitWidth: iconSizePx + (10 * Appearance.effectiveScale)
    implicitHeight: iconSizePx + (6 * Appearance.effectiveScale)
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        anchors.fill: parent
        radius: 8 * Appearance.effectiveScale
        color: mouseArea.containsMouse ? Qt.rgba(root.color.r, root.color.g, root.color.b, 0.12) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MaterialSymbol {
        id: layoutIconSymbol
        anchors.centerIn: parent
        text: root.layoutIcon
        iconSize: root.iconSizePx
        color: root.color
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            HyprlandData.cycleLayout(true);
        }
    }
}
