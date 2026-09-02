import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 0
    
    SearchHandler { 
        searchString: "Dock"
        aliases: ["Taskbar", "App Dock", "Pinned Apps"]
    }

    // ── Dock Section ──
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale
        
        // Section Header
        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 4 * Appearance.effectiveScale
            MaterialSymbol {
                text: "bottom_panel_open"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Dock"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale // STANDAR GAP 4px

            // ── Enable Dock ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: enableRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: enableRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "visibility"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Enable Dock"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? Config.options.dock.enable : false
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.enable = !Config.options.dock.enable
                    }
                }
            }

            // ── Show only in Desktop ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: showDesktopRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: showDesktopRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "desktop_windows"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Only in Desktop"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? Config.options.dock.showOnlyInDesktop : false
                        onToggled: {
                            if (Config.ready && Config.options.dock) {
                                const newState = !Config.options.dock.showOnlyInDesktop;
                                Config.options.dock.showOnlyInDesktop = newState;
                                if (newState && Config.options.dock.autoHide && Config.options.dock.autoHideMode === 0) {
                                    Config.options.dock.autoHideMode = 1;
                                }
                            }
                        }
                    }
                }
            }

            // ── Auto Hide Mode ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: autoHideRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: autoHideRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "visibility_off"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Auto Hide"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: {
                                const onlyDesktop = Config.ready && Config.options.dock && Config.options.dock.showOnlyInDesktop;
                                if (onlyDesktop) return [{ val: -1, label: "Off" }, { val: 1,  label: "Always" }];
                                return [{ val: -1, label: "Off" }, { val: 0,  label: "Adaptive" }, { val: 1,  label: "Always" }];
                            }
                            delegate: SegmentedButton {
                                required property var modelData
                                buttonText: modelData.label
                                isHighlighted: {
                                    if (modelData.val === -1) return !Config.options.dock.autoHide;
                                    return Config.options.dock.autoHide && Config.options.dock.autoHideMode === modelData.val;
                                }
                                colActive: Appearance.m3colors.m3primary; colActiveText: Appearance.m3colors.m3onPrimary; colInactive: Appearance.m3colors.m3surfaceContainerLow
                                onClicked: {
                                    if (modelData.val === -1) Config.options.dock.autoHide = false;
                                    else { Config.options.dock.autoHide = true; Config.options.dock.autoHideMode = modelData.val; }
                                }
                            }
                        }
                    }
                }
            }

            // ── Background Style ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: bgStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: bgStyleRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "layers"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Background"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: [{ val: 0, label: "None" }, { val: 1, label: "Floating" }, { val: 2, label: "Attached" }]
                            delegate: SegmentedButton {
                                required property var modelData
                                buttonText: modelData.label
                                isHighlighted: Config.options.dock.backgroundStyle === modelData.val
                                colActive: Appearance.m3colors.m3primary; colActiveText: Appearance.m3colors.m3onPrimary; colInactive: Appearance.m3colors.m3surfaceContainerLow
                                onClicked: Config.options.dock.backgroundStyle = modelData.val
                            }
                        }
                    }
                }
            }

            // ── Themed Icons ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: monoRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: monoRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Themed Icons"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? Config.options.dock.monochromeIcons : false
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.monochromeIcons = !Config.options.dock.monochromeIcons
                    }
                }
            }

            // ── Dock Scale ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: scaleRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: scaleRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 20 * Appearance.effectiveScale

                    RowLayout {
                        spacing: 16 * Appearance.effectiveScale
                        Layout.preferredWidth: 70 * Appearance.effectiveScale
                        MaterialSymbol { text: "open_in_full"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                        StyledText { text: "Scale"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1; elide: Text.ElideRight }
                    }

                    StyledSlider {
                        Layout.fillWidth: true; from: 0.5; to: 1.5; stepSize: 0.05
                        value: Config.ready && Config.options.dock ? Config.options.dock.scale : 1.0
                        onMoved: if (Config.ready && Config.options.dock) Config.options.dock.scale = value
                    }
                    
                    StyledText {
                        text: Math.round((Config.ready && Config.options.dock ? Config.options.dock.scale : 1.0) * 100).toString() + "%"
                        color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 50 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // ── Background Opacity ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: bgOpacityRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: bgOpacityRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 20 * Appearance.effectiveScale

                    RowLayout {
                        spacing: 16 * Appearance.effectiveScale
                        Layout.preferredWidth: 140 * Appearance.effectiveScale
                        MaterialSymbol { text: "opacity"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                        StyledText { text: "Background Opacity"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1; elide: Text.ElideRight }
                    }

                    StyledSlider {
                        Layout.fillWidth: true; from: 0.0; to: 1.0; stepSize: 0.05
                        value: Config.ready && Config.options.dock ? (Config.options.dock.bgOpacity ?? 1.0) : 1.0
                        onMoved: if (Config.ready && Config.options.dock) Config.options.dock.bgOpacity = value
                    }
                    
                    StyledText {
                        text: Math.round((Config.ready && Config.options.dock ? (Config.options.dock.bgOpacity ?? 1.0) : 1.0) * 100).toString() + "%"
                        color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 50 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // ── Corner Radius ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: cornerRadiusRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: cornerRadiusRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 20 * Appearance.effectiveScale

                    RowLayout {
                        spacing: 16 * Appearance.effectiveScale
                        Layout.preferredWidth: 140 * Appearance.effectiveScale
                        MaterialSymbol { text: "rounded_corner"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                        StyledText { text: "Corner Radius"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1; elide: Text.ElideRight }
                    }

                    StyledSlider {
                        Layout.fillWidth: true; from: 0; to: 32; stepSize: 1
                        value: Config.ready && Config.options.dock && (Config.options.dock.cornerRadius ?? -1) >= 0 ? Config.options.dock.cornerRadius : (Appearance.rounding.normal + 6)
                        onMoved: if (Config.ready && Config.options.dock) Config.options.dock.cornerRadius = Math.round(value)
                    }
                    
                    StyledText {
                        text: (Config.ready && Config.options.dock && (Config.options.dock.cornerRadius ?? -1) >= 0 ? Math.round(Config.options.dock.cornerRadius) : Math.round(Appearance.rounding.normal + 6)).toString() + "px"
                        color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 50 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // ── Show Shadow ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: shadowRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: shadowRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "drop_shadow"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Shadow"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? (Config.options.dock.showShadow ?? false) : false
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.showShadow = !Config.options.dock.showShadow
                    }
                }
            }

            // ── Show Pin Button ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: pinBtnRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: pinBtnRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "keep"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Pin Button"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? (Config.options.dock.showPinButton ?? true) : true
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.showPinButton = !Config.options.dock.showPinButton
                    }
                }
            }

            // ── Pin Dock on Startup ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: pinStartupRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: pinStartupRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "push_pin"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Pin Dock on Startup"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? (Config.options.dock.pinnedOnStartup ?? false) : false
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.pinnedOnStartup = !Config.options.dock.pinnedOnStartup
                    }
                }
            }

            // ── Show Media Card ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: mediaCardRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: mediaCardRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "music_note"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Media Card"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? (Config.options.dock.showMedia ?? true) : true
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.showMedia = !Config.options.dock.showMedia
                    }
                }
            }

            // ── Show App Launcher ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: launcherRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: launcherRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "apps"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show App Launcher"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? (Config.options.dock.showLauncher ?? true) : true
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.showLauncher = !Config.options.dock.showLauncher
                    }
                }
            }

            // ── Show Overview Button ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: overviewRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: overviewRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "grid_view"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Overview Button"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? (Config.options.dock.showOverview ?? true) : true
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.showOverview = !Config.options.dock.showOverview
                    }
                }
            }
        }
    }
}
