pragma ComponentBehavior: Bound

import "../../core"
import "../../core/functions" as Functions
import "../../services"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

/**
 * Background panel.
 * Draws the wallpaper on the bottommost layer (WlrLayer.Background).
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: bgRoot
        required property var modelData

        // Basic positioning
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell:background"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Window level transparency is ALWAYS ON for stability.
        color: "transparent"

        // Base background color (only visible when live wallpaper is OFF)
        Rectangle {
            id: baseColor
            anchors.fill: parent
            color: Appearance.colors.colLayer0
            z: -1
            visible: !WallpaperEngineService.active
        }

        property string currentPath: (Config.ready && Config.options.appearance && Config.options.appearance.background && Config.options.appearance.background.wallpaperPath) ? Config.options.appearance.background.wallpaperPath : ""
        property string transitionType: (Config.ready && Config.options.appearance && Config.options.appearance.background && Config.options.appearance.background.transition) ? Config.options.appearance.background.transition : "random"
        
        property string currentTransitionMode: "fade"
        readonly property var transitionModes: ["fade", "zoomIn", "zoomOut", "slideUp", "slideDown", "slideLeft", "slideRight"]

        onCurrentPathChanged: {
            if (currentPath === "" || currentPath === undefined) return;
            
            let tType = transitionType;
            if (tType === "random") {
                const r = Math.random();
                if (r < 0.33) tType = "sweep";
                else if (r < 0.66) tType = "expand";
                else tType = "dynamic";
            }
            
            if (tType === "sweep") {
                zaphWallpaper.source = currentPath;
                if (zaphWallpaper.status === Image.Ready) zaphAnim.restart();
                else {
                    const conn = (status) => {
                        if (zaphWallpaper.status === Image.Ready) {
                            zaphAnim.restart();
                            zaphWallpaper.statusChanged.disconnect(conn);
                        }
                    }
                    zaphWallpaper.statusChanged.connect(conn);
                }
            } else if (tType === "expand") {
                centerExpandWallpaper.source = currentPath;
                if (centerExpandWallpaper.status === Image.Ready) centerExpandAnim.restart();
                else {
                    const conn = (status) => {
                        if (centerExpandWallpaper.status === Image.Ready) {
                            centerExpandAnim.restart();
                            centerExpandWallpaper.statusChanged.disconnect(conn);
                        }
                    }
                    centerExpandWallpaper.statusChanged.connect(conn);
                }
            } else {
                currentTransitionMode = transitionModes[Math.floor(Math.random() * transitionModes.length)];

                if (wallpaper1.visible) {
                    wallpaper2.source = currentPath;
                    if (wallpaper2.status === Image.Ready) transAnim2.restart();
                    else {
                        const conn = (status) => {
                            if (wallpaper2.status === Image.Ready) {
                                transAnim2.restart();
                                wallpaper2.statusChanged.disconnect(conn);
                            }
                        }
                        wallpaper2.statusChanged.connect(conn);
                    }
                } else {
                    wallpaper1.source = currentPath;
                    if (wallpaper1.status === Image.Ready) transAnim1.restart();
                    else {
                        const conn = (status) => {
                            if (wallpaper1.status === Image.Ready) {
                                transAnim1.restart();
                                wallpaper1.statusChanged.disconnect(conn);
                            }
                        }
                        wallpaper1.statusChanged.connect(conn);
                    }
                }
            }
        }

        // --- Container for Static Wallpapers ---
        Item {
            id: staticWallpaperContainer
            anchors.fill: parent
            z: 1
            opacity: WallpaperEngineService.active ? 0 : 1
            visible: opacity > 0
            
            Image {
                id: wallpaper1
                anchors.fill: parent
                source: bgRoot.currentPath
                fillMode: Image.PreserveAspectCrop
                visible: true
                z: 1
                opacity: 1
                scale: 1.0
                transformOrigin: Item.Center
            }

            Image {
                id: wallpaper2
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                visible: false
                z: 1
                opacity: 0
                scale: 1.0
                transformOrigin: Item.Center
            }

            Rectangle {
                id: zaphAnimRect
                anchors.right: parent.right
                height: parent.height
                width: 0
                clip: true
                color: "transparent"
                z: 3
                
                Image {
                    id: zaphWallpaper
                    anchors.right: parent.right
                    height: bgRoot.height
                    width: bgRoot.width
                    fillMode: Image.PreserveAspectCrop
                    source: ""
                }
            }

            Item {
                id: centerExpandContainer
                anchors.fill: parent
                z: 3
                visible: centerExpandRect.width > 0
                
                Image {
                    id: centerExpandWallpaper
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: ""
                    visible: false
                }
                
                Item {
                    id: maskContainer
                    anchors.fill: parent
                    visible: false
                    
                    Rectangle {
                        id: centerExpandRect
                        anchors.centerIn: parent
                        width: 0
                        height: 0
                        radius: width / 2
                        color: "black"
                    }
                }
                
                OpacityMask {
                    anchors.fill: centerExpandWallpaper
                    source: centerExpandWallpaper
                    maskSource: maskContainer
                }
            }
        }

        // --- Transitions ---
        SequentialAnimation {
            id: zaphAnim
            ScriptAction {
                script: {
                    wallpaper1.visible = true;
                    wallpaper1.z = 1;
                    wallpaper2.visible = false;
                    zaphAnimRect.z = 2;
                }
            }
            NumberAnimation {
                target: zaphAnimRect
                property: "width"
                from: 0
                to: bgRoot.width
                duration: 500
                easing.bezierCurve: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
            }
            ScriptAction {
                script: {
                    wallpaper1.source = bgRoot.currentPath;
                    wallpaper1.visible = true;
                    wallpaper1.opacity = 1;
                    wallpaper1.scale = 1.0;
                    wallpaper1.x = 0;
                    wallpaper1.y = 0;
                    zaphAnimRect.width = 0;
                }
            }
        }

        SequentialAnimation {
            id: centerExpandAnim
            ScriptAction {
                script: {
                    wallpaper1.visible = true;
                    wallpaper1.z = 1;
                    wallpaper2.visible = false;
                    centerExpandContainer.z = 2;
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: centerExpandRect
                    property: "width"
                    from: 0
                    to: Math.max(bgRoot.width, bgRoot.height) * 1.5
                    duration: 600
                    easing.type: Easing.InOutCubic
                }
                NumberAnimation {
                    target: centerExpandRect
                    property: "height"
                    from: 0
                    to: Math.max(bgRoot.width, bgRoot.height) * 1.5
                    duration: 600
                    easing.type: Easing.InOutCubic
                }
            }
            ScriptAction {
                script: {
                    wallpaper1.source = bgRoot.currentPath;
                    wallpaper1.visible = true;
                    wallpaper1.opacity = 1;
                    wallpaper1.scale = 1.0;
                    wallpaper1.x = 0;
                    wallpaper1.y = 0;
                    centerExpandRect.width = 0;
                    centerExpandRect.height = 0;
                }
            }
        }
        SequentialAnimation {
            id: transAnim1
            ScriptAction { 
                script: { 
                    wallpaper1.visible = true; wallpaper1.z = 2; wallpaper2.z = 1; 
                    wallpaper1.x = 0; wallpaper1.y = 0;
                } 
            }
            ParallelAnimation {
                NumberAnimation { target: wallpaper1; property: "opacity"; from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic }
                NumberAnimation { 
                    target: wallpaper1; property: "scale"
                    from: currentTransitionMode === "zoomIn" ? 0.9 : (currentTransitionMode === "zoomOut" ? 1.1 : 1.0)
                    to: 1.0; duration: 700; easing.type: Easing.OutExpo 
                }
                NumberAnimation { 
                    target: wallpaper1; property: "y"
                    from: currentTransitionMode === "slideUp" ? (bgRoot.height * 0.15) : (currentTransitionMode === "slideDown" ? -(bgRoot.height * 0.15) : 0)
                    to: 0; duration: 700; easing.type: Easing.OutExpo 
                }
                NumberAnimation { 
                    target: wallpaper1; property: "x"
                    from: currentTransitionMode === "slideLeft" ? (bgRoot.width * 0.15) : (currentTransitionMode === "slideRight" ? -(bgRoot.width * 0.15) : 0)
                    to: 0; duration: 700; easing.type: Easing.OutExpo 
                }
            }
            ScriptAction { script: { wallpaper2.visible = false; wallpaper2.opacity = 0; wallpaper2.scale = 1.0; wallpaper2.x = 0; wallpaper2.y = 0; } }
        }

        SequentialAnimation {
            id: transAnim2
            ScriptAction { 
                script: { 
                    wallpaper2.visible = true; wallpaper2.z = 2; wallpaper1.z = 1; 
                    wallpaper2.x = 0; wallpaper2.y = 0;
                } 
            }
            ParallelAnimation {
                NumberAnimation { target: wallpaper2; property: "opacity"; from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic }
                NumberAnimation { 
                    target: wallpaper2; property: "scale"
                    from: currentTransitionMode === "zoomIn" ? 0.9 : (currentTransitionMode === "zoomOut" ? 1.1 : 1.0)
                    to: 1.0; duration: 700; easing.type: Easing.OutExpo 
                }
                NumberAnimation { 
                    target: wallpaper2; property: "y"
                    from: currentTransitionMode === "slideUp" ? (bgRoot.height * 0.15) : (currentTransitionMode === "slideDown" ? -(bgRoot.height * 0.15) : 0)
                    to: 0; duration: 700; easing.type: Easing.OutExpo 
                }
                NumberAnimation { 
                    target: wallpaper2; property: "x"
                    from: currentTransitionMode === "slideLeft" ? (bgRoot.width * 0.15) : (currentTransitionMode === "slideRight" ? -(bgRoot.width * 0.15) : 0)
                    to: 0; duration: 700; easing.type: Easing.OutExpo 
                }
            }
            ScriptAction { script: { wallpaper1.visible = false; wallpaper1.opacity = 0; wallpaper1.scale = 1.0; wallpaper1.x = 0; wallpaper1.y = 0; } }
        }

        Rectangle {
            id: overlay
            anchors.fill: parent
            color: "black"
            opacity: GlobalStates.screenLocked ? 0.3 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
    }
}
