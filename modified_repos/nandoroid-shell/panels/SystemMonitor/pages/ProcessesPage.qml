import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../.."
import "../../../core"
import "../../../core/functions" as Functions
import "../../../services"
import "../../../widgets"
import ".."
import Quickshell
import Quickshell.Io

/**
 * Processes page for the System Monitor.
 * Designed with clean, native NANDoroid Material 3 aesthetics.
 */
Item {
    id: root

    property string sortField: "cpu"
    property bool sortAscending: false
    property string searchQuery: ""
    property int activeContextPid: -1

    // Helper to map process command names to appropriate icons
    function getProcessIcon(cmd) {
        if (!cmd) return "memory";
        const c = cmd.toLowerCase();
        if (c.includes("firefox")) return "language";
        if (c.includes("chrome") || c.includes("chromium") || c.includes("brave")) return "public";
        if (c.includes("code") || c.includes("vsc")) return "code";
        if (c.includes("vesktop") || c.includes("discord")) return "chat";
        if (c.includes("steam") || c.includes("game")) return "sports_esports";
        if (c.includes("spotify") || c.includes("mpv") || c.includes("vlc") || c.includes("music")) return "music_note";
        if (c.includes("bash") || c.includes("zsh") || c.includes("fish") || c.includes("sh") || c.includes("kitty") || c.includes("alacritty") || c.includes("foot") || c.includes("terminal")) return "terminal";
        if (c.includes("quickshell") || c.includes("waybar") || c.includes("hyprland") || c.includes("swww") || c.includes("dunst")) return "desktop_windows";
        if (c.includes("python") || c.includes("node") || c.includes("ruby") || c.includes("java") || c.includes("rust")) return "developer_board";
        if (c.includes("pipewire") || c.includes("wireplumber") || c.includes("pulseaudio")) return "graphic_eq";
        if (c.includes("dgop") || c.includes("top") || c.includes("htop")) return "monitoring";
        return "memory";
    }

    readonly property var filteredProcesses: {
        let procs = SystemData.allProcesses.slice();

        // Filter by search query
        if (root.searchQuery.trim() !== "") {
            const q = root.searchQuery.trim().toLowerCase();
            procs = procs.filter(p => {
                return (p.command && p.command.toLowerCase().includes(q)) ||
                       (p.username && p.username.toLowerCase().includes(q)) ||
                       (p.pid && p.pid.toString().includes(q));
            });
        }

        // Sort
        procs.sort((a, b) => {
            let valA = a[sortField];
            let valB = b[sortField];
            if (typeof valA === "string") {
                valA = valA.toLowerCase();
                valB = valB.toLowerCase();
            }
            if (valA < valB) return sortAscending ? -1 : 1;
            if (valA > valB) return sortAscending ? 1 : -1;
            return 0;
        });
        return procs;
    }

    Process {
        id: actionProc
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale

        // ── Toolbar Header (Matching NANDoroid Settings Page Style) ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 16 * Appearance.effectiveScale

            ColumnLayout {
                spacing: 4 * Appearance.effectiveScale
                StyledText {
                    text: "Processes"
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: root.searchQuery.trim() !== "" 
                        ? root.filteredProcesses.length + " of " + (SystemData.processCount > 0 ? SystemData.processCount : root.filteredProcesses.length) + " processes"
                        : (SystemData.processCount > 0 ? SystemData.processCount : root.filteredProcesses.length) + " running processes"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }

            Item { Layout.fillWidth: true }

            // Search Box (matching NANDoroid Settings search pill, 100% vertically aligned)
            Rectangle {
                Layout.preferredWidth: 260 * Appearance.effectiveScale
                Layout.preferredHeight: 40 * Appearance.effectiveScale
                radius: 20 * Appearance.effectiveScale
                color: Appearance.colors.colLayer2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14 * Appearance.effectiveScale
                    anchors.rightMargin: 14 * Appearance.effectiveScale
                    spacing: 10 * Appearance.effectiveScale

                    MaterialSymbol {
                        text: "search"
                        iconSize: 20 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                        Layout.alignment: Qt.AlignVCenter
                    }

                    StyledTextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        inputRadius: 0
                        backgroundColor: "transparent"
                        borderInactiveWidth: 0
                        showActiveBorder: false
                        font.pixelSize: Appearance.font.pixelSize.normal
                        placeholder: "Search process..."
                        placeholderColor: Appearance.colors.colSubtext
                        leftMargin: 0
                        rightMargin: 0
                        onTextChanged: root.searchQuery = text
                    }

                    MaterialSymbol {
                        visible: searchInput.text !== ""
                        text: "close"
                        iconSize: 18 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                        Layout.alignment: Qt.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                root.searchQuery = "";
                            }
                        }
                    }
                }
            }
        }

        // Notice banner if dgop is not installed (Automatic Native Fallback Active)
        Rectangle {
            visible: !SystemData.isDgopAvailable
            Layout.fillWidth: true
            implicitHeight: 36 * Appearance.effectiveScale
            color: Functions.ColorUtils.applyAlpha(Appearance.colors.colWarning, 0.1)
            radius: 10 * Appearance.effectiveScale
            border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colWarning, 0.3)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12 * Appearance.effectiveScale
                anchors.rightMargin: 12 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "info"
                    iconSize: 18 * Appearance.effectiveScale
                    color: Appearance.colors.colWarning
                }
                StyledText {
                    text: "Using native Linux 'ps' fallback. Install 'dgop' for enhanced real-time 1-second CPU deltas."
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }
        }

        // ── Table Header (Clean, pixel-aligned with data rows) ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32 * Appearance.effectiveScale
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16 * Appearance.effectiveScale
                anchors.rightMargin: 16 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale

                HeaderItem { text: "PID"; field: "pid"; Layout.preferredWidth: 65 * Appearance.effectiveScale; alignment: Text.AlignLeft }
                HeaderItem { text: "Name"; field: "command"; Layout.fillWidth: true; alignment: Text.AlignLeft }
                HeaderItem { text: "CPU"; field: "cpu"; Layout.preferredWidth: 80 * Appearance.effectiveScale; alignment: Text.AlignRight }
                HeaderItem { text: "Memory"; field: "memoryKB"; Layout.preferredWidth: 95 * Appearance.effectiveScale; alignment: Text.AlignRight }
                HeaderItem { text: "User"; field: "username"; Layout.preferredWidth: 95 * Appearance.effectiveScale; alignment: Text.AlignRight }
            }
        }

        // ── Process List View ──
        ListView {
            id: processList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: ScriptModel {
                values: root.filteredProcesses
                objectProp: "pid"
            }
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 0
            spacing: 4 * Appearance.effectiveScale

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                implicitHeight: 40 * Appearance.effectiveScale
                radius: 10 * Appearance.effectiveScale

                readonly property bool isMenuOpen: processMenu.visible && root.activeContextPid === modelData.pid
                readonly property bool isHovered: mouseArea.containsMouse && !processMenu.visible

                color: isMenuOpen 
                    ? Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.15) 
                    : (isHovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)

                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16 * Appearance.effectiveScale
                    anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 12 * Appearance.effectiveScale

                    // PID Column
                    StyledText {
                        text: modelData.pid
                        Layout.preferredWidth: 65 * Appearance.effectiveScale
                        color: isMenuOpen ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }

                    // Process Icon + Name Column
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: root.getProcessIcon(modelData.command)
                            iconSize: 18 * Appearance.effectiveScale
                            color: isMenuOpen ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: (modelData.command === "dgop" || modelData.command === "/usr/bin/dgop" || (modelData.command && modelData.command.includes("dgop"))) ? "nandoroid-monitor" : modelData.command
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.weight: Font.Normal
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: isMenuOpen ? Appearance.colors.colPrimary : Appearance.m3colors.m3onSurface
                        }
                    }

                    // CPU Usage Column
                    StyledText {
                        text: modelData.cpu.toFixed(1) + "%"
                        Layout.preferredWidth: 80 * Appearance.effectiveScale
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Normal
                        color: modelData.cpu > 20 
                            ? Appearance.colors.colWarning 
                            : (modelData.cpu > 5 ? Appearance.colors.colPrimary : Appearance.m3colors.m3onSurface)
                    }

                    // Memory Column
                    StyledText {
                        readonly property real memMB: modelData.memoryKB / 1024
                        text: memMB >= 1024 ? (memMB / 1024).toFixed(2) + " GB" : memMB.toFixed(1) + " MB"
                        Layout.preferredWidth: 95 * Appearance.effectiveScale
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Normal
                        color: isMenuOpen ? Appearance.colors.colPrimary : Appearance.m3colors.m3onSurface
                    }

                    // User Column
                    StyledText {
                        text: modelData.username
                        Layout.preferredWidth: 95 * Appearance.effectiveScale
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            const displayName = (modelData.command === "dgop" || modelData.command === "/usr/bin/dgop" || (modelData.command && modelData.command.includes("dgop"))) ? "nandoroid-monitor" : modelData.command;
                            root.activeContextPid = modelData.pid;
                            processMenu.targetPid = modelData.pid;
                            processMenu.targetName = displayName;
                            processMenu.popup();
                        }
                    }
                }
            }
        }
    }

    // HeaderItem Component (Clean, perfectly aligned with data cells)
    component HeaderItem: MouseArea {
        property string text
        property string field
        property int alignment: Text.AlignLeft
        
        Layout.fillHeight: true
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        readonly property bool isActive: root.sortField === field
        
        onClicked: {
            if (root.sortField === field) {
                root.sortAscending = !root.sortAscending;
            } else {
                root.sortField = field;
                root.sortAscending = false;
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 4 * Appearance.effectiveScale
            
            // For Right-Aligned columns: Spacer first, then Arrow (if active), then Text
            Item {
                visible: parent.parent.alignment === Text.AlignRight
                Layout.fillWidth: true
            }

            MaterialSymbol {
                visible: parent.parent.alignment === Text.AlignRight && isActive
                text: root.sortAscending ? "arrow_upward" : "arrow_downward"
                iconSize: 12 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }

            StyledText {
                text: parent.parent.text
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: isActive ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                horizontalAlignment: parent.parent.alignment
            }

            // For Left-Aligned columns: Text first, then Arrow (if active), then Spacer
            MaterialSymbol {
                visible: parent.parent.alignment === Text.AlignLeft && isActive
                text: root.sortAscending ? "arrow_upward" : "arrow_downward"
                iconSize: 12 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }

            Item {
                visible: parent.parent.alignment === Text.AlignLeft
                Layout.fillWidth: true
            }
        }
    }

    // Context Menu (Compact design matching DockContextMenu)
    Menu {
        id: processMenu
        property int targetPid: 0
        property string targetName: ""

        onClosed: {
            root.activeContextPid = -1;
        }

        background: Rectangle {
            implicitWidth: 180 * Appearance.effectiveScale
            color: Appearance.colors.colLayer0
            opacity: 0.98
            radius: Appearance.rounding.small
            border.color: Appearance.colors.colOutlineVariant
            border.width: Math.max(1, 1 * Appearance.effectiveScale)
        }

        padding: 4 * Appearance.effectiveScale

        component StyledMenuItem: MenuItem {
            id: menuItem
            
            implicitHeight: 32 * Appearance.effectiveScale

            readonly property bool isHovered: itemHover.hovered

            HoverHandler {
                id: itemHover
            }
            
            contentItem: RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8 * Appearance.effectiveScale
                anchors.rightMargin: 8 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                MaterialSymbol {
                    text: {
                        if (menuItem.text.includes("Kill")) return "delete_forever";
                        if (menuItem.text.includes("Stop")) return "pause";
                        if (menuItem.text.includes("Continue")) return "play_arrow";
                        if (menuItem.text.includes("Close")) return "close";
                        if (menuItem.text.includes("Copy")) return "content_copy";
                        return "info";
                    }
                    iconSize: 18 * Appearance.effectiveScale
                    color: menuItem.text.includes("Kill (Force)")
                        ? Appearance.colors.colError 
                        : Appearance.colors.colOnLayer0
                }
                StyledText {
                    text: menuItem.text
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Normal
                    color: menuItem.text.includes("Kill (Force)")
                        ? Appearance.colors.colError 
                        : Appearance.colors.colOnLayer0
                    Layout.fillWidth: true
                }
            }
            
            background: Rectangle {
                anchors.fill: parent
                color: menuItem.isHovered 
                    ? (menuItem.text.includes("Kill (Force)")
                        ? Functions.ColorUtils.applyAlpha(Appearance.colors.colError, 0.15)
                        : Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.15))
                    : "transparent"
                radius: Appearance.rounding.verysmall
            }
        }
        
        StyledMenuItem {
            text: "Stop (Pause)"
            onTriggered: { actionProc.command = ["kill", "-STOP", processMenu.targetPid.toString()]; actionProc.running = true; }
        }
        StyledMenuItem {
            text: "Continue"
            onTriggered: { actionProc.command = ["kill", "-CONT", processMenu.targetPid.toString()]; actionProc.running = true; }
        }
        
        MenuSeparator {
            contentItem: Rectangle { 
                implicitHeight: Math.max(1, 1 * Appearance.effectiveScale) 
                color: Appearance.colors.colOutlineVariant 
                opacity: 0.1
                Layout.margins: 4 * Appearance.effectiveScale
            }
        }

        StyledMenuItem {
            text: "Close (Graceful)"
            onTriggered: { actionProc.command = ["kill", processMenu.targetPid.toString()]; actionProc.running = true; }
        }
        StyledMenuItem {
            text: "Kill (Force)"
            onTriggered: { actionProc.command = ["kill", "-9", processMenu.targetPid.toString()]; actionProc.running = true; }
        }

        MenuSeparator {
            contentItem: Rectangle { 
                implicitHeight: Math.max(1, 1 * Appearance.effectiveScale) 
                color: Appearance.colors.colOutlineVariant 
                opacity: 0.1
                Layout.margins: 4 * Appearance.effectiveScale
            }
        }

        StyledMenuItem {
            text: "Copy PID"
            onTriggered: Quickshell.clipboardText = processMenu.targetPid.toString()
        }
    }
}
