import "../../../core"
import "../../../core/functions" as Functions
import "../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

/**
 * IPC Step page for Onboarding.
 * Curated list of primary NAnDoroid IPC commands with category filter counts (Borderless M3 design).
 */
ColumnLayout {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 14 * Appearance.effectiveScale

    property string activeCategory: "All"
    property string searchQuery: ""

    // Helper to pick appropriate icons for IPC commands
    function getIpcIcon(target, method) {
        if (target === "launcher") return "apps";
        if (target === "spotlight") return "search";
        if (target === "notifications") return "notifications";
        if (target === "quicksettings") return "tune";
        if (target === "systemmonitor" || target === "sysmon") return "monitoring";
        if (target === "overview") return "space_dashboard";
        if (target === "session") return "power_settings_new";
        if (target === "dashboard") return "dashboard";
        if (target === "quickactions") return "flash_on";
        if (target === "settings") return "settings";
        if (target === "lock") return "lock";
        if (target === "region") {
            if (method === "screenshot") return "crop";
            if (method === "search") return "saved_search";
            if (method === "ocr") return "document_scanner";
            if (method === "qrcode") return "qr_code_scanner";
            if (method.startsWith("record")) return "videocam";
        }
        if (target === "brightness") return "brightness_6";
        if (target === "pomodoro") return "timer";
        if (target === "wallpaper") return "wallpaper";
        return "terminal";
    }

    readonly property var allIpcItems: [
        // ── Sidebar & Panels ──
        { name: "App Launcher", category: "Sidebar & Panels", cmd: "quickshell -c nandoroid ipc call launcher toggle", target: "launcher", method: "toggle" },
        { name: "Spotlight Search", category: "Sidebar & Panels", cmd: "quickshell -c nandoroid ipc call spotlight toggle", target: "spotlight", method: "toggle" },
        { name: "Notification Center", category: "Sidebar & Panels", cmd: "quickshell -c nandoroid ipc call notifications toggle", target: "notifications", method: "toggle" },
        { name: "Quick Settings", category: "Sidebar & Panels", cmd: "quickshell -c nandoroid ipc call quicksettings toggle", target: "quicksettings", method: "toggle" },
        { name: "System Monitor", category: "Sidebar & Panels", cmd: "quickshell -c nandoroid ipc call systemmonitor toggle", target: "systemmonitor", method: "toggle" },
        { name: "Overview Panel", category: "Sidebar & Panels", cmd: "quickshell -c nandoroid ipc call overview toggle", target: "overview", method: "toggle" },
        { name: "Session Menu (Power)", category: "Sidebar & Panels", cmd: "quickshell -c nandoroid ipc call session toggle", target: "session", method: "toggle" },
        { name: "Dashboard", category: "Sidebar & Panels", cmd: "quickshell -c nandoroid ipc call dashboard toggle", target: "dashboard", method: "toggle" },
        { name: "Quick Actions", category: "Sidebar & Panels", cmd: "quickshell -c nandoroid ipc call quickactions toggle", target: "quickactions", method: "toggle" },
        { name: "Nandoroid Settings", category: "Sidebar & Panels", cmd: "quickshell -c nandoroid ipc call settings toggle", target: "settings", method: "toggle" },

        // ── Region Tools ──
        { name: "Region Screenshot", category: "Region Tools", cmd: "quickshell -c nandoroid ipc call region screenshot", target: "region", method: "screenshot" },
        { name: "Visual Search", category: "Region Tools", cmd: "quickshell -c nandoroid ipc call region search", target: "region", method: "search" },
        { name: "Text OCR", category: "Region Tools", cmd: "quickshell -c nandoroid ipc call region ocr", target: "region", method: "ocr" },
        { name: "QR Code Scan", category: "Region Tools", cmd: "quickshell -c nandoroid ipc call region qrcode", target: "region", method: "qrcode" },
        { name: "Record Region", category: "Region Tools", cmd: "quickshell -c nandoroid ipc call region record", target: "region", method: "record" },
        { name: "Record w/ Audio", category: "Region Tools", cmd: "quickshell -c nandoroid ipc call region recordWithSound", target: "region", method: "recordWithSound" },

        // ── Media & System ──
        { name: "Brightness +", category: "Media & System", cmd: "quickshell -c nandoroid ipc call brightness increment", target: "brightness", method: "increment" },
        { name: "Brightness -", category: "Media & System", cmd: "quickshell -c nandoroid ipc call brightness decrement", target: "brightness", method: "decrement" },
        { name: "Lock Screen", category: "Media & System", cmd: "quickshell -c nandoroid ipc call lock activate", target: "lock", method: "activate" },
        { name: "Start Pomodoro", category: "Media & System", cmd: "quickshell -c nandoroid ipc call pomodoro start", target: "pomodoro", method: "start" },
        { name: "Pause Pomodoro", category: "Media & System", cmd: "quickshell -c nandoroid ipc call pomodoro pause", target: "pomodoro", method: "pause" },
        { name: "Stop Pomodoro", category: "Media & System", cmd: "quickshell -c nandoroid ipc call pomodoro stop", target: "pomodoro", method: "stop" },
        { name: "Reset Pomodoro", category: "Media & System", cmd: "quickshell -c nandoroid ipc call pomodoro reset", target: "pomodoro", method: "reset" },
        { name: "Open Desktop Wallpaper", category: "Media & System", cmd: "quickshell -c nandoroid ipc call wallpaper openDesktop", target: "wallpaper", method: "openDesktop" },
        { name: "Open Lock Wallpaper", category: "Media & System", cmd: "quickshell -c nandoroid ipc call wallpaper openLock", target: "wallpaper", method: "openLock" }
    ]

    readonly property var filteredIpcItems: {
        let items = root.allIpcItems.slice();

        if (root.activeCategory !== "All") {
            items = items.filter(i => i.category === root.activeCategory);
        }

        if (root.searchQuery.trim() !== "") {
            const q = root.searchQuery.trim().toLowerCase();
            items = items.filter(i => {
                return (i.name && i.name.toLowerCase().includes(q)) ||
                       (i.cmd && i.cmd.toLowerCase().includes(q)) ||
                       (i.category && i.category.toLowerCase().includes(q));
            });
        }
        return items;
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        StyledText {
            text: "Step 4: Command Line & IPC Integration"
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            text: "NAnDoroid IPC allows instant binding in your Window Manager. Search and test commands in real time!"
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    function getCategoryCount(cat) {
        if (cat === "All") return root.allIpcItems.length;
        return root.allIpcItems.filter(i => i.category === cat).length;
    }

    function getCategoryLabel(cat) {
        const count = root.getCategoryCount(cat);
        return `${cat} (${count})`;
    }

    // ── Toolbar Header (SegmentedButtons + Search Input Pill) ──
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 6 * Appearance.effectiveScale
        spacing: 12 * Appearance.effectiveScale

        // Category Filter (Material 3 SegmentedButton Group)
        RowLayout {
            spacing: 2 * Appearance.effectiveScale
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 36 * Appearance.effectiveScale

            Repeater {
                model: ["All", "Sidebar & Panels", "Region Tools", "Media & System"]
                delegate: SegmentedButton {
                    required property string modelData
                    isHighlighted: root.activeCategory === modelData
                    implicitHeight: 36 * Appearance.effectiveScale
                    buttonText: root.getCategoryLabel(modelData)
                    leftPadding: 14 * Appearance.effectiveScale
                    rightPadding: 14 * Appearance.effectiveScale
                    colActive: Appearance.colors.colPrimary
                    colActiveText: Appearance.colors.colOnPrimary
                    colInactive: Appearance.m3colors.m3surfaceContainerHigh
                    colInactiveText: Appearance.colors.colOnLayer1
                    onClicked: root.activeCategory = modelData
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Search Input Pill
        Rectangle {
            Layout.preferredWidth: 230 * Appearance.effectiveScale
            Layout.preferredHeight: 36 * Appearance.effectiveScale
            radius: 18 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12 * Appearance.effectiveScale
                anchors.rightMargin: 12 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "search"
                    iconSize: 16 * Appearance.effectiveScale
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
                    font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                    placeholder: "Search IPC commands..."
                    placeholderColor: Appearance.colors.colSubtext
                    leftMargin: 0
                    rightMargin: 0
                    onTextChanged: root.searchQuery = text
                }

                MaterialSymbol {
                    visible: searchInput.text !== ""
                    text: "close"
                    iconSize: 14 * Appearance.effectiveScale
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

    // ── Code Bind Example Banner ──
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36 * Appearance.effectiveScale
        color: Appearance.m3colors.m3surfaceContainerHigh
        radius: 10 * Appearance.effectiveScale

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14 * Appearance.effectiveScale
            anchors.rightMargin: 14 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale

            MaterialSymbol {
                text: "terminal"
                iconSize: 16 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "WM Bind Example (Hyprland):"
                font.weight: Font.DemiBold
                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                color: Appearance.colors.colOnLayer0
            }
            StyledText {
                text: 'hl.bind("SUPER + I", hl.dsp.exec_cmd("quickshell -c nandoroid ipc call settings toggle"))'
                font.family: "monospace"
                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                color: Appearance.colors.colPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    // ── IPC Items List View ──
    ListView {
        id: ipcList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: root.filteredIpcItems
        clip: true
        spacing: 10 * Appearance.effectiveScale
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width
            implicitHeight: 52 * Appearance.effectiveScale
            radius: 12 * Appearance.effectiveScale
            color: itemHover.hovered ? Appearance.colors.colLayer2Hover : Appearance.m3colors.m3surfaceContainerHigh

            HoverHandler {
                id: itemHover
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16 * Appearance.effectiveScale
                anchors.rightMargin: 16 * Appearance.effectiveScale
                spacing: 14 * Appearance.effectiveScale

                // Action Icon
                Rectangle {
                    width: 34 * Appearance.effectiveScale
                    height: 34 * Appearance.effectiveScale
                    radius: 17 * Appearance.effectiveScale
                    color: Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.12)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.getIpcIcon(modelData.target, modelData.method)
                        iconSize: 18 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                }

                // Name & Command
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2 * Appearance.effectiveScale

                    RowLayout {
                        spacing: 8 * Appearance.effectiveScale
                        StyledText {
                            text: modelData.name
                            font.weight: Font.DemiBold
                            font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                            color: Appearance.colors.colOnLayer1
                        }
                        Rectangle {
                            implicitWidth: catLabel.implicitWidth + 10 * Appearance.effectiveScale
                            implicitHeight: 18 * Appearance.effectiveScale
                            radius: 9 * Appearance.effectiveScale
                            color: Appearance.colors.colLayer2
                            StyledText {
                                id: catLabel
                                anchors.centerIn: parent
                                text: modelData.category
                                font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    StyledText {
                        text: modelData.cmd
                        font.family: "monospace"
                        font.pixelSize: Math.round(10 * Appearance.effectiveScale)
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Copy Button
                Rectangle {
                    width: 32 * Appearance.effectiveScale
                    height: 32 * Appearance.effectiveScale
                    radius: 16 * Appearance.effectiveScale
                    color: copyMouse.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "content_copy"
                        iconSize: 14 * Appearance.effectiveScale
                        color: copyMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                    }
                    MouseArea {
                        id: copyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Quickshell.execDetached(["wl-copy", modelData.cmd]);
                            Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", "edit-copy", "Copied", "IPC Command copied to clipboard!"]);
                        }
                    }
                }

                // Run Button
                RippleButton {
                    implicitWidth: 68 * Appearance.effectiveScale
                    implicitHeight: 32 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: Appearance.colors.colPrimary
                    onClicked: {
                        Quickshell.execDetached(["quickshell", "-c", "nandoroid", "ipc", "call", modelData.target, modelData.method]);
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "play_arrow"
                            iconSize: 14 * Appearance.effectiveScale
                            color: Appearance.colors.colOnPrimary
                        }
                        StyledText {
                            text: "Run"
                            font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }
        }
    }
}
