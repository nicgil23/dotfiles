import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Dashboard panel – anchored to top/left/right so the sheet can
 * slide down from the status bar and the backdrop covers the screen.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelWindow
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData

        // Keep visible while panel is animating out (opacity > 0 check is done inside content)
        visible: (GlobalStates.dashboardOpen && isActive)
                 || (content && content.active && isActive)

        exclusiveZone: 0
        WlrLayershell.namespace: "nandoroid:dashboard"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: (GlobalStates.dashboardOpen && isActive)
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None
        color: "transparent"

        // Cover the whole screen so the backdrop dims everything
        anchors { top: true; bottom: true; left: true; right: true }

        HyprlandFocusGrab {
            id: focusGrab
            active: GlobalStates.dashboardOpen && isActive
            windows: [panelWindow]
            onCleared: { GlobalStates.dashboardOpen = false }
        }

        DashboardContent {
            id: content
            anchors.fill: parent
            visible: isActive
            onClosed: { GlobalStates.dashboardOpen = false }
        }
    }
}
