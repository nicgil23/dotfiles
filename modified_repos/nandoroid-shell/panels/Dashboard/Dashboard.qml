import qs.core
import qs.services
import qs.widgets
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
        id: backdropWindow
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData

        // Same visibility logic as the main window
        visible: (GlobalStates.dashboardOpen && isActive)
                 || (content && content.active && isActive)

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "nandoroid:dashboard-backdrop"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"

        anchors { top: true; bottom: true; left: true; right: true }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: GlobalStates.dashboardOpen ? 0.40 : 0
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            
            MouseArea { 
                anchors.fill: parent
                onClicked: GlobalStates.dashboardOpen = false 
            }
        }
    }

    PanelWindow {
        id: panelWindow
        required property var modelData
        screen: modelData

        readonly property int monitorIndex: index
        readonly property int bgStyle: Config.ready && Config.options.statusBar ? (Config.options.statusBar.backgroundStyle ?? 0) : 0
        readonly property bool hasTiledWindows: {
            if (bgStyle !== 2) return false;
            const ws = Hyprland.monitorFor(modelData)?.activeWorkspace;
            if (!ws) return false;
            const wsId = ws.id;
            return HyprlandData.windowList.some(w => 
                w.workspace.id === wsId && !w.floating && w.monitor === monitorIndex
            );
        }
        readonly property bool barBgVisible: bgStyle === 1 || (bgStyle === 2 && hasTiledWindows)

        readonly property bool isActive: GlobalStates.activeScreen === modelData

        // Keep visible while panel is animating out (opacity > 0 check is done inside content)
        visible: (GlobalStates.dashboardOpen && isActive)
                 || (content && content.active && isActive)

        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
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
            barBgVisible: panelWindow.barBgVisible
            onClosed: { GlobalStates.dashboardOpen = false }
        }
    }
}
