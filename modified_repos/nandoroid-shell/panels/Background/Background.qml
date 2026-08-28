pragma ComponentBehavior: Bound

import "../../core"
import "../../core/functions" as Functions
import "../../services"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Background panel.
 * Draws the wallpaper on the bottommost layer (WlrLayer.Background).
 * Moves to Overlay during session lock to serve as backdrop for transparent LockSurface.
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
        WlrLayershell.layer: GlobalStates.screenLocked ? WlrLayer.Overlay : WlrLayer.Background
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

        readonly property string desktopPath: (Config.ready && Config.options.appearance && Config.options.appearance.background && Config.options.appearance.background.wallpaperPath) ? Config.options.appearance.background.wallpaperPath : ""
        readonly property string lockPath: Config.options.lock.useSeparateWallpaper && Config.options.lock.wallpaperPath ? Config.options.lock.wallpaperPath : ""
        property string currentPath: GlobalStates.screenLocked && lockPath ? lockPath : desktopPath
        
        readonly property string selectedTransition: (Config.ready && Config.options && Config.options.appearance && Config.options.appearance.background && Config.options.appearance.background.transition) ? Config.options.appearance.background.transition : "random"
        property var shaderList: ["circlePit", "circleSelect", "magic", "Doom", "Peel", "transition", "pixelate", "stripes", "circle"]
        property string currentShader: "pixelate"
        property real transitionProgress: 1.0

        onCurrentPathChanged: {
            if (currentPath === "" || currentPath === undefined) return;
            
            // Avoid transition on first load
            if (wallpaper.source.toString() === "") {
                wallpaper.source = currentPath;
                previousWallpaper.source = "";
                return;
            }

            // Don't transition if paths are the same
            var effectivePrev = wallpaper.source.toString().replace("file://", "");
            if (effectivePrev === currentPath.replace("file://", "")) return;

            // Assign previous source DIRECTLY (not via binding) so the image
            // is available when the shader starts rendering on next frame
            previousWallpaper.source = wallpaper.source;
            wallpaper.source = currentPath;

            var sel = bgRoot.selectedTransition;
            var validKeys = ["Doom", "Peel", "circle", "circlePit", "circleSelect", "magic", "pixelate", "stripes", "transition", "sweep", "expand"];
            
            if (validKeys.includes(sel)) {
                currentShader = sel;
            } else {
                var rawPool = (Config.ready && Config.options && Config.options.appearance && Config.options.appearance.background)
                    ? Config.options.appearance.background.randomTransitionPool
                    : null;
                var poolArr = (rawPool && rawPool.length > 0) ? Array.from(rawPool) : validKeys;
                var validPool = poolArr.filter(function(k) { return validKeys.includes(k); });
                if (validPool.length === 0) validPool = validKeys;
                currentShader = validPool[Math.floor(Math.random() * validPool.length)];
            }

            transitionProgress = 0.0;
            transitionAnim.restart();
        }

        NumberAnimation {
            id: transitionAnim
            target: bgRoot
            property: "transitionProgress"
            from: 0.0
            to: 1.0
            duration: 1200
            easing.type: Easing.InOutCubic
            onFinished: {
                previousWallpaper.source = "";
                bgRoot.transitionProgress = 1.0;
            }
        }

        // --- Container for Static Wallpapers ---
        Item {
            id: staticWallpaperContainer
            anchors.fill: parent
            z: 1
            opacity: WallpaperEngineService.active ? 0 : 1
            visible: opacity > 0
            
            // Previous Wallpaper Image (Must be visible during transition so texture is captured)
            Image {
                id: previousWallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                visible: bgRoot.transitionProgress < 1.0
                cache: true
                smooth: true
                asynchronous: false
                layer.enabled: true
            }

            // Target New Wallpaper Image (Shown when transition ends)
            Image {
                id: wallpaper
                anchors.fill: parent
                source: bgRoot.currentPath
                fillMode: Image.PreserveAspectCrop
                cache: true
                smooth: true
                asynchronous: true
                layer.enabled: true
                visible: bgRoot.transitionProgress >= 1.0
            }
            
            // Shader Effect (Active for shader-based transitions)
            ShaderEffect {
                id: transitionEffect
                anchors.fill: parent
                visible: (bgRoot.currentShader !== "sweep" && bgRoot.currentShader !== "expand") && (bgRoot.transitionProgress < 1.0)
                property var fromImage: previousWallpaper
                property var toImage: wallpaper
                property real progress: bgRoot.transitionProgress
                property real aspectX: width / height
                property real aspectY: 1.0
                property vector2d aspectRatio: Qt.vector2d(aspectX, aspectY)
                property vector2d origin: Qt.vector2d(0.5, 0.5)
                fragmentShader: Qt.resolvedUrl(`shaders/${bgRoot.currentShader}.frag.qsb`)
            }

            // Real Horizontal Sweep (Left-to-Right Wipe)
            Item {
                id: sweepWipe
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.width * bgRoot.transitionProgress
                clip: true
                visible: bgRoot.currentShader === "sweep" && bgRoot.transitionProgress < 1.0

                Image {
                    width: staticWallpaperContainer.width
                    height: staticWallpaperContainer.height
                    source: bgRoot.currentPath
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    smooth: true
                }
            }

            // Real Center Expand (Radial Expansion)
            Item {
                id: expandWipe
                anchors.fill: parent
                visible: bgRoot.currentShader === "expand" && bgRoot.transitionProgress < 1.0

                Image {
                    anchors.centerIn: parent
                    width: staticWallpaperContainer.width * bgRoot.transitionProgress
                    height: staticWallpaperContainer.height * bgRoot.transitionProgress
                    source: bgRoot.currentPath
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    smooth: true
                    opacity: bgRoot.transitionProgress
                }
            }
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
