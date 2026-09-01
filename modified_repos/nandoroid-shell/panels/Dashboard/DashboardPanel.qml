import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Variants {
  model: Quickshell.screens

  PanelWindow {
    id: panelWindow
    required property var modelData
    screen: modelData

    readonly property bool isActive: GlobalStates.activeScreen === modelData
    readonly property bool isOpen: GlobalStates.dashboardOpen && isActive

    visible: isOpen || closeTimer.running

    exclusiveZone: 0
    WlrLayershell.namespace: "nandoroid:dashboard"
    WlrLayershell.layer: isOpen || closeTimer.running ? WlrLayer.Top : WlrLayer.Background
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    anchors.top: true
    anchors.left: true

    readonly property real shoulderRadius: Math.max(1, (Config.ready && Config.options.statusBar
      ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20) * Appearance.effectiveScale)
    readonly property real dashWidth: Appearance.sizes.dashboardWidth + 2 * panelWindow.shoulderRadius
    readonly property real dashHeight: Appearance.sizes.dashboardHeight
    readonly property real centeredX: Math.max(0, Math.round((modelData.width - panelWindow.dashWidth) / 2))

    readonly property bool showShoulders: {
      if (!Config.ready || !Config.options.statusBar) return false;
      let style = Config.options.statusBar.moduleStyle ?? "";
      if (style === "m3") return false;
      let bgStyle = Config.options.statusBar.backgroundStyle ?? 0;
      if (bgStyle === 1) return true;
      if (bgStyle === 2) {
        let activeWsId = HyprlandData.activeWorkspace ? HyprlandData.activeWorkspace.id : undefined;
        return activeWsId ? HyprlandData.windowList.some(w => w.workspace.id === activeWsId && !w.floating) : false;
      }
      return false;
    }

    margins.left: panelWindow.centeredX
    margins.top: panelWindow.showShoulders ? (-2 * Appearance.effectiveScale) : 0
    implicitWidth: panelWindow.dashWidth
    implicitHeight: panelWindow.dashHeight + (panelWindow.showShoulders ? 2 * Appearance.effectiveScale : 0)

    Timer { id: closeTimer; interval: 400 }

    onIsOpenChanged: {
      if (isOpen) {
        GlobalFocusGrab.addDismissable(panelWindow);
      } else {
        GlobalFocusGrab.removeDismissable(panelWindow);
        closeTimer.restart();
      }
    }

    Connections {
      target: GlobalFocusGrab
      function onDismissed() {
        GlobalStates.dashboardOpen = false;
      }
    }

    DashboardContent {
      onClosed: GlobalStates.dashboardOpen = false
    }
  }
}
