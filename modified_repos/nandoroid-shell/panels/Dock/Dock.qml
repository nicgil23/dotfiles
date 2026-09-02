import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * NAnDoroid Ported Dock
 * Masterpiece version: Optimized, Stable, and Correct Layering.
 */
Scope {
    id: root
    property bool pinned: Config.ready ? (Config.options.dock.pinnedOnStartup ?? false) : false

    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: screenScope
            required property var modelData
            readonly property int monitorIndex: modelData.index ?? 0

            PanelWindow {
                id: dockWindow
                screen: modelData

                Component.onCompleted: GlobalFocusGrab.addPersistent(dockWindow)
                Component.onDestruction: GlobalFocusGrab.removePersistent(dockWindow)
                
                // --- LAYER FIX: Sits at 'Top' layer so 'Overlay' panels stay in front ---
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "nandoroid:dock"
                
                exclusiveZone: {
                    if (!Config.ready || !visible) return 0;
                    // Reserve exact visual height of dock so window gap equals standard Hyprland gaps
                    if (!Config.options.dock.showOnlyInDesktop && !Config.options.dock.autoHide) {
                        const bMargin = (dockWindow.bgStyle === 2 ? 0 : Appearance.sizes.elevationMargin / 2);
                        const visualTop = dockWindow.dockHeight * (dockWindow.dockScale / Appearance.effectiveScale) + bMargin;
                        return Math.ceil(visualTop);
                    }
                    return 0;
                }
                
                anchors { left: true; right: true; bottom: true }
                color: "transparent"
                
                // Define the clickable area to allow click-through on the sides
                mask: Region {
                    // Back to a single item mask, but the item's height will be smart
                    item: dockMouseArea
                }
                
                // SIMPLIFIED VISIBILITY: Toggle the whole window for 'Show Only In Desktop' and force hidden in Game Mode
                visible: {
                    if (!Config.ready || GlobalStates.screenLocked || !Config.options.dock.enable || GameMode.active) return false;
                    
                    // If 'Show Only In Desktop' is ON, only show if no active windows on this monitor
                    if (Config.options.dock.showOnlyInDesktop) {
                        if (GlobalStates.launcherOpen || GlobalStates.dockMenuOpen || root.pinned) return true;
                        return !hasActiveWindows;
                    }
                    
                    return true;
                }

                // Removed restrictive mask to allow shadow to spread
                
                readonly property real dockHeight: 56 * Appearance.effectiveScale
                readonly property real dockScale: (Config.ready && Config.options.dock ? Config.options.dock.scale : 1.0) * Appearance.effectiveScale
                readonly property int bgStyle: Config.ready && Config.options.dock ? Config.options.dock.backgroundStyle : 1
                implicitWidth: modelData.width
                // Provide exact height for the dock container and its shadow margin
                implicitHeight: Math.ceil((dockHeight * (dockScale / Appearance.effectiveScale)) + 24 * Appearance.effectiveScale)
                readonly property real screenY: modelData.height - height

                readonly property bool hasActiveWindows: {
                    if (!Config.ready || !HyprlandData.activeWorkspace) return false;
                    
                    // Get windows for THIS specific monitor on the active workspace
                    const wsId = HyprlandData.activeWorkspace.id;
                    const windows = HyprlandData.hyprlandClientsForWorkspace(wsId);
                    
                    for (let i = 0; i < windows.length; i++) {
                        const w = windows[i];
                        if (w.monitor === screenScope.monitorIndex && !w.floating && w.mapped && !w.hidden) return true;
                    }
                    return false;
                }

                property bool reveal: {
                    if (!Config.ready) return true;
                    
                    // Standard reveal logic (Menus, Hovers, Pinned)
                    if (root.pinned || GlobalStates.dockMenuOpen || dockPreview.visible || dockPreview.hovered || dockApps.buttonHovered || dockMouseArea.containsMouse) return true;
                    
                    // Auto-hide logic
                    if (Config.options.dock.autoHide) {
                        if (Config.options.dock.autoHideMode === 1) return false; // Always hide mode
                        return !hasActiveWindows; // Intelligent mode
                    }
                    
                    return true;
                }

                Timer {
                    id: hoverGuardTimer
                    interval: Appearance.animation.elementMoveFast.duration + 50
                    repeat: false
                    onTriggered: {
                        if (dockApps.buttonHovered && dockWindow.reveal) {
                            dockPreview.show(dockApps.lastHoveredButton, dockApps.lastHoveredAppData);
                        }
                    }
                }

                onRevealChanged: {
                    if (reveal) hoverGuardTimer.restart();
                    else dockPreview.requestHide();
                }

                MouseArea {
                    id: dockMouseArea
                    // Width is now always tied to the visual dock width (considering scale)
                    width: Math.max(200 * Appearance.effectiveScale, visualContainer.width * (dockWindow.dockScale / Appearance.effectiveScale))
                    anchors.horizontalCenter: parent.horizontalCenter
                    hoverEnabled: true
                    height: {
                        if (!Config.ready) return visualContainer.height;
                        // If preview is out, we NEED the full height to interact with it
                        if (dockPreview.visible || dockPreview.hovered) return parent.height;
                        
                        // Otherwise, only be as high as the dock or the trigger zone
                        if (dockWindow.reveal) return visualContainer.height * (dockWindow.dockScale / Appearance.effectiveScale) + (10 * Appearance.effectiveScale);
                        return 10 * Appearance.effectiveScale; // Trigger zone at bottom
                    }
                    anchors.bottom: parent.bottom

                    Item {
                        id: visualContainer
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.max(100 * Appearance.effectiveScale, mainRowContainer.implicitWidth + 20 * Appearance.effectiveScale)
                        height: dockWindow.dockHeight
                        scale: dockWindow.dockScale / Appearance.effectiveScale
                        transformOrigin: Item.Bottom
                        
                        readonly property real bMargin: (dockWindow.bgStyle === 2) ? -2 * Appearance.effectiveScale : Appearance.sizes.elevationMargin / 2
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: dockWindow.reveal ? bMargin : (-height * scale) - 20 * Appearance.effectiveScale
                        opacity: dockWindow.reveal ? 1 : 0

                        Behavior on anchors.bottomMargin {
                            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type }
                        }
                        Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }

                        // --- Visual Content Container ---
                        Rectangle {
                            id: dockVisualRect
                            anchors.fill: parent
                            readonly property real customRadius: Config.ready && Config.options.dock && (Config.options.dock.cornerRadius ?? -1) >= 0 ? Config.options.dock.cornerRadius * Appearance.effectiveScale : (Appearance.rounding.normal + 6)
                            radius: dockWindow.bgStyle === 1 ? customRadius : (dockWindow.bgStyle === 2 ? 0 : height / 2)
                            topLeftRadius: (dockWindow.bgStyle === 2) ? (Config.ready && Config.options.dock && (Config.options.dock.cornerRadius ?? -1) >= 0 ? Config.options.dock.cornerRadius * Appearance.effectiveScale : 24 * Appearance.effectiveScale) : radius
                            topRightRadius: (dockWindow.bgStyle === 2) ? (Config.ready && Config.options.dock && (Config.options.dock.cornerRadius ?? -1) >= 0 ? Config.options.dock.cornerRadius * Appearance.effectiveScale : 24 * Appearance.effectiveScale) : radius
                            bottomLeftRadius: (dockWindow.bgStyle === 2) ? 0 : radius
                            bottomRightRadius: (dockWindow.bgStyle === 2) ? 0 : radius
                            color: Functions.ColorUtils.applyAlpha(Appearance.colors.colLayer0, Config.ready && Config.options.dock ? (Config.options.dock.bgOpacity ?? 1.0) : 1.0)
                            opacity: dockWindow.bgStyle === 0 ? 0 : 1.0

                            // MD3 Outline Style
                            border.width: dockWindow.bgStyle !== 0 ? Math.max(1, 1 * Appearance.effectiveScale) : 0
                            border.color: Appearance.colors.colLayer0Border ?? Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.12)

                            StyledRectangularShadow {
                                target: dockVisualRect
                                visible: Config.ready && Config.options.dock ? (Config.options.dock.showShadow ?? false) : false
                                opacity: 0.3
                                z: -1
                            }

                            RowLayout {
                                id: mainRowContainer
                                anchors.fill: parent
                                anchors.leftMargin: 8 * Appearance.effectiveScale
                                anchors.rightMargin: 8 * Appearance.effectiveScale
                                anchors.topMargin: 4 * Appearance.effectiveScale
                                anchors.bottomMargin: 4 * Appearance.effectiveScale
                                spacing: 6 * Appearance.effectiveScale
                                
                                // Pin/Keep Button (Leftmost, end4-style)
                                DockButton {
                                    id: pinButton
                                    visible: Config.ready && (Config.options.dock.showPinButton ?? true)
                                    pointingHandCursor: true
                                    onClicked: {
                                        if (Config.ready && Config.options.dock) {
                                            Config.options.dock.pinnedOnStartup = !root.pinned;
                                        } else {
                                            root.pinned = !root.pinned;
                                        }
                                    }
                                    toggled: root.pinned
                                    colBackgroundToggled: Appearance.colors.colPrimary
                                    contentItem: Item {
                                        anchors.fill: parent
                                        scale: pinButton.down ? 0.92 : (pinButton.hovered ? 1.05 : 1.0)
                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "keep"
                                            iconSize: 20 * Appearance.effectiveScale
                                            color: root.pinned ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                                        }
                                    }
                                }

                                DockSeparator {
                                    visible: pinButton.visible
                                }

                                DockApps {
                                    id: dockApps; buttonPadding: 2 * Appearance.effectiveScale; spacing: 6 * Appearance.effectiveScale; height: parent.height
                                    backgroundStyle: dockWindow.bgStyle
                                    onRequestContextMenu: (appData, x, y) => {
                                        dockContextMenu.openAt(x, (dockWindow.screenY + (y * (dockWindow.dockScale / Appearance.effectiveScale))), appData);
                                    }
                                    onButtonHoverChanged: (button, appData, hovered) => {
                                        if (hovered) {
                                            dockApps.lastHoveredAppData = appData;
                                            if (!hoverGuardTimer.running && dockWindow.reveal) {
                                                dockPreview.show(button, appData);
                                            }
                                        } else {
                                            dockPreview.requestHide();
                                        }
                                    }
                                }

                                DockSeparator {
                                    visible: dockMedia.visible
                                }

                                DockMedia {
                                    id: dockMedia
                                    height: parent.height
                                }

                                DockSeparator {
                                    visible: overviewButton.visible || launcherButton.visible
                                }

                                DockButton {
                                    id: overviewButton
                                    visible: Config.ready && (Config.options.dock.showOverview ?? true)
                                    pointingHandCursor: true
                                    onClicked: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
                                    toggled: GlobalStates.overviewOpen
                                    colBackgroundToggled: "transparent"
                                    colBackgroundToggledHover: "transparent"
                                    background: Item {
                                        anchors.fill: parent
                                        Rectangle { anchors.fill: parent; radius: Appearance.rounding.button; color: overviewButton.baseColor; visible: !(Config.ready && Config.options.dock.monochromeIcons) }
                                        MaterialShape { anchors.fill: parent; anchors.margins: 2 * Appearance.effectiveScale; visible: Config.ready && Config.options.dock.monochromeIcons; shapeString: Config.ready && Config.options.search ? Config.options.search.iconShape : "Circle"; color: overviewButton.down ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer }
                                    }
                                    contentItem: Item {
                                        anchors.fill: parent
                                        scale: overviewButton.down ? 0.92 : (overviewButton.hovered ? 1.05 : 1.0)
                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                        MaterialSymbol { id: overviewIcon; anchors.centerIn: parent; text: "grid_view"; iconSize: (Config.ready && Config.options.dock.monochromeIcons ? 22 : 26) * Appearance.effectiveScale; color: overviewButton.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0; visible: !(Config.ready && Config.options.dock.monochromeIcons) }
                                        ColorOverlay { anchors.fill: overviewIcon; source: overviewIcon; color: Appearance.colors.colOnPrimaryContainer; visible: Config.ready && Config.options.dock.monochromeIcons }
                                    }
                                }

                                DockButton {
                                    id: launcherButton
                                    visible: Config.ready && (Config.options.dock.showLauncher ?? true)
                                    pointingHandCursor: true
                                    onClicked: GlobalStates.launcherOpen = !GlobalStates.launcherOpen
                                    toggled: GlobalStates.launcherOpen
                                    colBackgroundToggled: "transparent"
                                    colBackgroundToggledHover: "transparent"
                                    altAction: (event) => {
                                        const pos = launcherButton.mapToItem(null, event.x, event.y);
                                        dockContextMenu.openAt(pos.x, dockWindow.screenY + pos.y);
                                    }
                                    background: Item {
                                        anchors.fill: parent
                                        Rectangle { anchors.fill: parent; radius: Appearance.rounding.button; color: launcherButton.baseColor; visible: !(Config.ready && Config.options.dock.monochromeIcons) }
                                        MaterialShape { anchors.fill: parent; anchors.margins: 2 * Appearance.effectiveScale; visible: Config.ready && Config.options.dock.monochromeIcons; shapeString: Config.ready && Config.options.search ? Config.options.search.iconShape : "Circle"; color: launcherButton.down ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer }
                                    }
                                    contentItem: Item {
                                        anchors.fill: parent
                                        scale: launcherButton.down ? 0.92 : (launcherButton.hovered ? 1.05 : 1.0)
                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                        MaterialSymbol { id: launcherIcon; anchors.centerIn: parent; text: "apps"; iconSize: (Config.ready && Config.options.dock.monochromeIcons ? 22 : 26) * Appearance.effectiveScale; color: launcherButton.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0; visible: !(Config.ready && Config.options.dock.monochromeIcons) }
                                        ColorOverlay { anchors.fill: launcherIcon; source: launcherIcon; color: Appearance.colors.colOnPrimaryContainer; visible: Config.ready && Config.options.dock.monochromeIcons }
                                    }
                                }
                            }
                        }
                    }
                }

                DockContextMenu { id: dockContextMenu; screen: modelData }
                DockPreview { id: dockPreview; parentWindow: dockWindow }
            }
        }
    }
}
