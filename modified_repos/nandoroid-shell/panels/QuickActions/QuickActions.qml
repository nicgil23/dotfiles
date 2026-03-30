import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Quick Actions panel — floating HUD at the bottom.
 * Uses a full-screen PanelWindow for reliable centering and slide animation.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelWindow
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData
        visible: (GlobalStates.quickActionsOpen && isActive) || content.opacity > 0
        
        // Fill the screen
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        WlrLayershell.namespace: "nandoroid:quickactions"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.quickActionsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        // Handle focus
        HyprlandFocusGrab {
            id: focusGrab
            active: GlobalStates.quickActionsOpen && isActive
            windows: [panelWindow]
            onCleared: {
                GlobalStates.quickActionsOpen = false;
            }
        }

        // Close on click outside
        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.quickActionsOpen = false
        }

        QuickActionsContent {
            id: content
            anchors.horizontalCenter: parent.horizontalCenter
            position: "bottom"
            
            // Animation logic similar to launcher
            y: (GlobalStates.quickActionsOpen && isActive) 
                ? parent.height - height 
                : parent.height
            opacity: (GlobalStates.quickActionsOpen && isActive) ? 1 : 0
            
            Behavior on y {
                NumberAnimation {
                    duration: 300
                    easing.bezierCurve: (GlobalStates.quickActionsOpen && isActive) 
                        ? Appearance.animationCurves.emphasizedDecel 
                        : Appearance.animationCurves.emphasized
                }
            }
            
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            onClosed: {
                GlobalStates.quickActionsOpen = false;
            }
            
            Connections {
                target: GlobalStates
                function onQuickActionsOpenChanged() {
                    if (GlobalStates.quickActionsOpen && isActive) {
                        content.reset();
                        content.forceActiveFocus();
                    }
                }
            }
        }
    }
}
