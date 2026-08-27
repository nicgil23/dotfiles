import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

/**
 * Dependency Check component.
 * Refactored with 2-column M3 card design and System Settings style section headers.
 */
ColumnLayout {
    id: dependencyRoot
    spacing: 20 * Appearance.effectiveScale

    readonly property bool isScanning: SysCheckService.isChecking

    function scanDependencies() {
        SysCheckService.check();
    }

    // ── Dependency Scanner Banner (SegmentedWrapper matching SysLanguage.qml) ──
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: scannerLayout.implicitHeight + (32 * Appearance.effectiveScale)
        orientation: Qt.Vertical
        maxRadius: 20 * Appearance.effectiveScale
        color: Appearance.m3colors.m3surfaceContainerHigh

        ColumnLayout {
            id: scannerLayout
            anchors.fill: parent
            anchors.margins: 16 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale

            RowLayout {
                Layout.fillWidth: true
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "account_tree"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    Layout.fillWidth: true

                    StyledText {
                        text: "Dependency Scanner"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: SysCheckService.missingCount > 0 
                            ? `${SysCheckService.missingCount} critical components are missing.` 
                            : "All critical components are installed and ready."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: SysCheckService.missingCount > 0 ? Appearance.colors.colError : Appearance.colors.colSubtext
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                RippleButton {
                    implicitWidth: 130 * Appearance.effectiveScale
                    implicitHeight: 38 * Appearance.effectiveScale
                    buttonRadius: 19 * Appearance.effectiveScale
                    colBackground: Appearance.colors.colPrimary
                    onClicked: {
                        dependencyRoot.scanDependencies();
                    }
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6 * Appearance.effectiveScale
                        MaterialSymbol {
                            text: "sync"
                            iconSize: 18 * Appearance.effectiveScale
                            color: Appearance.colors.colOnPrimary
                            RotationAnimation on rotation {
                                running: SysCheckService.isChecking
                                from: 0; to: 360
                                duration: 1000
                                loops: Animation.Infinite
                            }
                        }
                        StyledText {
                            text: SysCheckService.isChecking ? "Scanning..." : "Scan Now"
                            color: Appearance.colors.colOnPrimary
                            font.weight: Font.Medium
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                    }
                }
            }
        }
    }

    // ── Categorized List (2-Column Grid with System Settings style headers) ──
    Repeater {
        model: [
            { id: "core", name: "Core Components (Required)", icon: "widgets" },
            { id: "services", name: "System Services", icon: "dns" },
            { id: "utilities", name: "Utility Tools", icon: "build" },
            { id: "theming", name: "Theming & Appearance", icon: "palette" },
            { id: "fonts", name: "Required Fonts", icon: "font_download" },
            { id: "livewallpaper", name: "Live Wallpaper Support", icon: "movie" },
            { id: "optional", name: "Optional Addons", icon: "extension" }
        ]

        delegate: ColumnLayout {
            required property var modelData
            readonly property var catItems: SysCheckService.dependencyData.filter(d => d.category === modelData.id)

            visible: catItems.length > 0
            Layout.fillWidth: true
            spacing: 10 * Appearance.effectiveScale

            // Section Header (System Settings Style)
            RowLayout {
                spacing: 10 * Appearance.effectiveScale
                Layout.topMargin: 4 * Appearance.effectiveScale

                MaterialSymbol {
                    text: modelData.icon
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: modelData.name
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            // 2-Column Grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10 * Appearance.effectiveScale
                columnSpacing: 10 * Appearance.effectiveScale

                Repeater {
                    model: catItems

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 52 * Appearance.effectiveScale
                        radius: 12 * Appearance.effectiveScale
                        color: itemHover.hovered ? Appearance.colors.colLayer2Hover : Appearance.m3colors.m3surfaceContainerHigh
                        border.width: 1 * Appearance.effectiveScale
                        border.color: modelData.installed 
                            ? Functions.ColorUtils.applyAlpha("#81C995", 0.4) 
                            : Functions.ColorUtils.applyAlpha(Appearance.colors.colError, 0.6)

                        HoverHandler {
                            id: itemHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: !modelData.installed ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (!modelData.installed) {
                                    Quickshell.execDetached(["kitty", "--hold", "-e", "paru", "-S", "--needed", modelData.name]);
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12 * Appearance.effectiveScale
                                anchors.rightMargin: 12 * Appearance.effectiveScale
                                spacing: 10 * Appearance.effectiveScale

                                MaterialSymbol {
                                    text: modelData.installed ? "check_circle" : "cancel"
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: modelData.installed ? "#81C995" : Appearance.colors.colError
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1 * Appearance.effectiveScale

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.description || "System dependency"
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        color: Appearance.colors.colSubtext
                                        elide: Text.ElideRight
                                    }
                                }

                                StyledText {
                                    visible: modelData.installed
                                    text: "Installed"
                                    color: "#81C995"
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    font.weight: Font.Medium
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                }

                                RippleButton {
                                    visible: !modelData.installed
                                    implicitWidth: 70 * Appearance.effectiveScale
                                    implicitHeight: 28 * Appearance.effectiveScale
                                    buttonRadius: 14 * Appearance.effectiveScale
                                    colBackground: Functions.ColorUtils.applyAlpha(Appearance.colors.colError, 0.15)
                                    onClicked: {
                                        Quickshell.execDetached(["kitty", "--hold", "-e", "paru", "-S", "--needed", modelData.name]);
                                    }

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: "Install"
                                        font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colError
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
