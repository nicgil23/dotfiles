import "../../core"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

/**
 * Android 16 Style Session Action Button
 */
RippleButton {
    id: root
    
    property string iconName
    property string actionText
    
    readonly property real baseScale: (Appearance.sizes.screen.height / 1080) * Appearance.effectiveScale
    readonly property real buttonSize: 128 * baseScale
    
    width: buttonSize
    height: buttonSize
    
    Layout.preferredWidth: buttonSize
    Layout.preferredHeight: buttonSize
    Layout.minimumWidth: buttonSize
    Layout.minimumHeight: buttonSize
    Layout.maximumWidth: buttonSize
    Layout.maximumHeight: buttonSize
    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
    
    onHoveredChanged: if (root.hovered) root.forceActiveFocus()

    buttonRadius: (root.activeFocus || root.down) ? (buttonSize / 2) : (28 * baseScale)

    colBackground: root.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHighest
    colBackgroundHover: Appearance.m3colors.m3primary
    colRipple: Appearance.m3colors.m3onPrimary

    property color contentColor: (root.down || root.activeFocus) ?
                                Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12 * baseScale

        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: root.iconName
            iconSize: 32 * baseScale
            color: root.contentColor
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: buttonSize - (16 * baseScale)
            text: root.actionText
            font.pixelSize: Math.max(10, 12 * baseScale)
            font.weight: Font.Medium
            color: root.contentColor
            opacity: 0.9
            elide: Text.ElideRight
            
            horizontalAlignment: Text.AlignHCenter
            renderType: Text.NativeRendering
        }
    }
    
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_H) { if (KeyNavigation.left) KeyNavigation.left.forceActiveFocus(); event.accepted = true; }
        if (event.key === Qt.Key_J) { if (KeyNavigation.down) KeyNavigation.down.forceActiveFocus(); event.accepted = true; }
        if (event.key === Qt.Key_K) { if (KeyNavigation.up) KeyNavigation.up.forceActiveFocus(); event.accepted = true; }
        if (event.key === Qt.Key_L) { if (KeyNavigation.right) KeyNavigation.right.forceActiveFocus(); event.accepted = true; }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked()
            event.accepted = true
        }
    }

    Behavior on buttonRadius {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuart }
    }
}
