import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../widgets"

/**
 * Base button for dock items.
 * Inherits RippleButton for consistent Material 3 styling.
 */
RippleButton {
    id: root
    Layout.alignment: Qt.AlignVCenter
    
    // Default compact size for dock buttons
    implicitHeight: 42 * Appearance.effectiveScale
    implicitWidth: 42 * Appearance.effectiveScale
    buttonRadius: Appearance.rounding.normal
    
    // Ensure the background is transparent by default if not toggled
    colBackground: toggled ? Appearance.colors.colPrimary : "transparent"
    
    property real dockTopInset: 0
    property real dockBottomInset: 0
    
    background: Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: root.buttonRadius
        color: root.baseColor
        
        Behavior on color { 
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(bgRect)
        }
    }
}
