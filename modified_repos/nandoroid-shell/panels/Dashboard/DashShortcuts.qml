import "../../core"
import "../../widgets"
import "../../services"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

/**
 * Dashboard Tab: Shortcuts — Dynamic Hyprland & Shell Keybindings
 */
Rectangle {
    id: root
    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.large
    border.width: Math.max(1, 1 * Appearance.effectiveScale)
    border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.05)

    property var rawBinds: []
    property var parsedBinds: []
    property string searchQuery: ""
    property string selectedCategory: "super" // Default to SUPER keys

    function refresh() {
        if (!bindProc.running) {
            bindProc.running = true
        }
    }

    Component.onCompleted: refresh()

    Process {
        id: bindProc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector { id: bindOut }
        running: false
        onExited: {
            try {
                const text = bindOut.text.trim();
                if (text) {
                    const parsed = JSON.parse(text);
                    root.rawBinds = Array.isArray(parsed) ? parsed : [];
                    root.processBinds();
                }
            } catch (e) {
                console.error("[DashShortcuts] Error parsing hyprctl binds output:", e);
            }
        }
    }

    function processBinds() {
        const list = [];
        for (let i = 0; i < rawBinds.length; i++) {
            const b = rawBinds[i];
            const mod = b.modmask ?? 0;

            const mods = [];
            if (mod & 64) mods.push("SUPER");
            if (mod & 1) mods.push("SHIFT");
            if (mod & 4) mods.push("CTRL");
            if (mod & 8) mods.push("ALT");

            let keyStr = (b.key || "").toString().trim();
            if (keyStr === "comma") keyStr = ",";
            else if (keyStr === "period") keyStr = ".";
            else if (keyStr === "slash") keyStr = "/";
            else if (keyStr === "space") keyStr = "Space";
            else if (keyStr === "return" || keyStr === "enter") keyStr = "Enter";
            else if (keyStr === "mouse:272") keyStr = "Left Click";
            else if (keyStr === "mouse:273") keyStr = "Right Click";
            else if (keyStr.startsWith("mouse_")) keyStr = keyStr.replace("mouse_", "Scroll ");

            if (mods.length === 0 && !keyStr) continue;

            const keys = mods.concat(keyStr ? [keyStr] : []);

            const disp = b.dispatcher || "";
            const arg = b.arg || "";
            let desc = b.description || "";
            let category = "system";
            const isSuper = (mod & 64) !== 0;

            if (!desc) {
                if (disp === "global") {
                    category = "quickshell";
                    if (arg.includes("quickshell:settings")) desc = "Toggle Settings Panel";
                    else if (arg.includes("quickshell:wallpaperSelector")) desc = "Toggle Wallpaper Selector";
                    else if (arg.includes("quickshell:carouselWallpaperPicker")) desc = "Toggle Carousel Wallpaper Picker";
                    else if (arg.includes("quickshell:wallpaperRandomFavorite")) desc = "Random Favorite Wallpaper";
                    else if (arg.includes("quickshell:spotlightClipboard")) desc = "Open Spotlight Clipboard";
                    else if (arg.includes("quickshell:spotlightEmoji")) desc = "Open Spotlight Emoji";
                    else if (arg.includes("quickshell:spotlightFiles")) desc = "Open Spotlight File Search";
                    else if (arg.includes("quickshell:spotlightCommand")) desc = "Open Spotlight Command Launcher";
                    else if (arg.includes("quickshell:spotlightTools")) desc = "Open Spotlight Tools";
                    else if (arg.includes("quickshell:regionScreenshot")) desc = "Region Screenshot";
                    else if (arg.includes("quickshell:regionOcr")) desc = "Region OCR (Text Recognition)";
                    else if (arg.includes("quickshell:regionRecord")) desc = "Region Screen Recording";
                    else if (arg.includes("quickshell:quickActions")) desc = "Toggle Quick Actions Panel";
                    else if (arg.includes("quickshell:brightnessIncrease")) desc = "Increase Brightness";
                    else if (arg.includes("quickshell:brightnessDecrease")) desc = "Decrease Brightness";
                    else desc = arg || "Quickshell Action";
                } else if (disp === "exec") {
                    category = "system";
                    if (arg.includes("kitty")) desc = "Launch Terminal (Kitty)";
                    else if (arg.includes("helium-browser")) desc = "Launch Browser (Helium)";
                    else if (arg.includes("restartshell.sh")) desc = "Restart Nandoroid Shell";
                    else if (arg.includes("playerctl")) desc = "Media Control (" + arg + ")";
                    else if (arg.includes("wpctl")) desc = "Volume Control (" + arg + ")";
                    else desc = "Run: " + arg;
                } else if (disp === "workspace" || disp === "movetoworkspace" || disp === "togglespecialworkspace") {
                    category = "workspace";
                    if (disp === "workspace") desc = "Switch to Workspace " + arg;
                    else if (disp === "movetoworkspace") desc = "Move Window to Workspace " + arg;
                    else if (disp === "togglespecialworkspace") desc = "Toggle Special Workspace (" + (arg || "magic") + ")";
                } else if (disp === "killactive") {
                    category = "window";
                    desc = "Close Active Window";
                } else if (disp === "togglefloating") {
                    category = "window";
                    desc = "Toggle Floating Window";
                } else if (disp === "pseudo") {
                    category = "window";
                    desc = "Toggle Pseudo Tiled Mode";
                } else if (disp === "fullscreen") {
                    category = "window";
                    desc = "Toggle Fullscreen";
                } else if (disp === "movefocus") {
                    category = "window";
                    desc = "Move Focus (" + (arg === "l" ? "Left" : arg === "r" ? "Right" : arg === "u" ? "Up" : arg === "d" ? "Down" : arg) + ")";
                } else if (disp === "swapwindow") {
                    category = "window";
                    desc = "Swap Window (" + (arg === "l" ? "Left" : arg === "r" ? "Right" : arg === "u" ? "Up" : arg === "d" ? "Down" : arg) + ")";
                } else if (disp === "swapnext") {
                    category = "window";
                    desc = "Swap Window with Next";
                } else if (disp === "resizeactive") {
                    category = "window";
                    desc = "Resize Active Window (" + arg + ")";
                } else {
                    desc = disp + (arg ? " " + arg : "");
                }
            } else {
                if (disp === "global") category = "quickshell";
                else if (disp.includes("workspace")) category = "workspace";
                else category = "system";
            }

            list.push({
                keys: keys,
                keysString: keys.join(" + "),
                isSuper: isSuper,
                category: category,
                dispatcher: disp,
                arg: arg,
                description: desc
            });
        }
        root.parsedBinds = list;
    }

    readonly property var filteredBinds: {
        let list = root.parsedBinds;

        if (root.selectedCategory === "super") {
            list = list.filter(b => b.isSuper);
        } else if (root.selectedCategory === "quickshell") {
            list = list.filter(b => b.category === "quickshell");
        } else if (root.selectedCategory === "system") {
            list = list.filter(b => b.category === "system");
        } else if (root.selectedCategory === "workspace") {
            list = list.filter(b => b.category === "workspace" || b.category === "window");
        }

        const q = root.searchQuery.trim().toLowerCase();
        if (q) {
            list = list.filter(b =>
                b.keysString.toLowerCase().includes(q) ||
                b.description.toLowerCase().includes(q) ||
                b.dispatcher.toLowerCase().includes(q) ||
                b.arg.toLowerCase().includes(q)
            );
        }

        return list;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20 * Appearance.effectiveScale
        spacing: 14 * Appearance.effectiveScale

        // ── Top Header Row ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale

            MaterialSymbol {
                text: "keyboard"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }

            ColumnLayout {
                spacing: 2 * Appearance.effectiveScale

                StyledText {
                    text: "Keybindings & Shortcuts"
                    font.pixelSize: Math.round(16 * Appearance.effectiveScale)
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                }

                StyledText {
                    text: root.filteredBinds.length + " dynamic shortcuts loaded from Hyprland"
                    font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                    color: Appearance.colors.colSubtext
                }
            }

            Item { Layout.fillWidth: true }

            // Search input box
            StyledTextInput {
                id: searchInput
                Layout.preferredWidth: 180 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                inputRadius: Appearance.rounding.small / Appearance.effectiveScale
                backgroundColor: Appearance.colors.colLayer2
                placeholder: "Search shortcuts..."
                onTextChanged: root.searchQuery = text
            }

            // Refresh Button
            RippleButton {
                implicitWidth: 36 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: Appearance.colors.colLayer2
                onClicked: root.refresh()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                    RotationAnimation on rotation {
                        from: 0; to: 360; duration: 800
                        running: bindProc.running
                        loops: Animation.Infinite
                    }
                }
                StyledToolTip { text: "Refresh from Hyprland" }
            }
        }

        // ── Category Filter Bar ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale

            Repeater {
                model: [
                    { id: "super",      label: "SUPER Keys",  icon: "key" },
                    { id: "all",        label: "All Keys",    icon: "keyboard" },
                    { id: "quickshell", label: "Quickshell",  icon: "widgets" },
                    { id: "system",     label: "System/Apps", icon: "apps" },
                    { id: "workspace",  label: "Workspaces",  icon: "grid_view" }
                ]

                delegate: RippleButton {
                    required property var modelData
                    implicitWidth: catRow.implicitWidth + 24 * Appearance.effectiveScale
                    implicitHeight: 32 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: root.selectedCategory === modelData.id
                        ? Appearance.colors.colPrimaryContainer
                        : Appearance.colors.colLayer2

                    onClicked: root.selectedCategory = modelData.id

                    RowLayout {
                        id: catRow
                        anchors.centerIn: parent
                        spacing: 6 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: modelData.icon
                            iconSize: 16 * Appearance.effectiveScale
                            color: root.selectedCategory === modelData.id
                                ? Appearance.colors.colOnPrimaryContainer
                                : Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: modelData.label
                            font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                            font.weight: root.selectedCategory === modelData.id ? Font.DemiBold : Font.Normal
                            color: root.selectedCategory === modelData.id
                                ? Appearance.colors.colOnPrimaryContainer
                                : Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }

        // ── Main List ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.colors.colLayer2
            radius: Appearance.rounding.medium
            clip: true

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 10 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale
                model: root.filteredBinds

                ScrollBar.vertical: StyledScrollBar {}

                delegate: Rectangle {
                    required property var modelData
                    width: listView.width - 12 * Appearance.effectiveScale
                    implicitHeight: Math.max(50 * Appearance.effectiveScale, delegateContent.implicitHeight + 16 * Appearance.effectiveScale)
                    radius: Appearance.rounding.small
                    color: itemMouse.containsMouse ? Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.08) : Appearance.colors.colLayer1
                    border.width: Math.max(1, 1 * Appearance.effectiveScale)
                    border.color: modelData.isSuper ? Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.2) : Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.04)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    RowLayout {
                        id: delegateContent
                        anchors.fill: parent
                        anchors.leftMargin: 14 * Appearance.effectiveScale
                        anchors.rightMargin: 14 * Appearance.effectiveScale
                        anchors.topMargin: 8 * Appearance.effectiveScale
                        anchors.bottomMargin: 8 * Appearance.effectiveScale
                        spacing: 12 * Appearance.effectiveScale

                        // Left: Key badge pills
                        Row {
                            spacing: 4 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: modelData.keys
                                delegate: Rectangle {
                                    required property string modelData
                                    required property int index

                                    implicitWidth: keyText.implicitWidth + 14 * Appearance.effectiveScale
                                    implicitHeight: 28 * Appearance.effectiveScale
                                    radius: 6 * Appearance.effectiveScale
                                    color: modelData === "SUPER"
                                        ? Appearance.colors.colPrimary
                                        : Appearance.colors.colLayer2
                                    border.width: modelData === "SUPER" ? 0 : Math.max(1, 1 * Appearance.effectiveScale)
                                    border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.15)

                                    StyledText {
                                        id: keyText
                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                                        font.weight: Font.Bold
                                        font.family: Appearance.font.family.monospace
                                        color: parent.modelData === "SUPER"
                                            ? Appearance.colors.colOnPrimary
                                            : Appearance.colors.colOnLayer1
                                    }
                                }
                            }
                        }

                        // Arrow icon
                        MaterialSymbol {
                            text: "arrow_forward"
                            iconSize: 14 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                            opacity: 0.5
                        }

                        // Right: Description & Action detail
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * Appearance.effectiveScale

                            StyledText {
                                text: modelData.description
                                font.pixelSize: Math.round(13 * Appearance.effectiveScale)
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: modelData.dispatcher + (modelData.arg ? ": " + modelData.arg : "")
                                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                                font.family: Appearance.font.family.monospace
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8 * Appearance.effectiveScale
                visible: root.filteredBinds.length === 0

                MaterialSymbol {
                    text: "search_off"
                    iconSize: 36 * Appearance.effectiveScale
                    color: Appearance.colors.colSubtext
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledText {
                    text: "No shortcuts match your filter"
                    font.pixelSize: Math.round(14 * Appearance.effectiveScale)
                    color: Appearance.colors.colSubtext
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
