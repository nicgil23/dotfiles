import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.SystemTray

ColumnLayout {
    id: rootColumn
    Layout.fillWidth: true
    spacing: 0

    // ── Global Module Pool & Layout Manager (on root for guaranteed scope) ────────────
    property bool leftMenuOpened: false
    property bool rightMenuOpened: false
    readonly property bool isCenteredMode: Config.ready && Config.options.statusBar && (Config.options.statusBar.layoutStyle === "centered") && ((Config.options.statusBar.moduleStyle ?? "base") !== "m3")
    readonly property int maxClusterPoints: isCenteredMode ? 4 : 5
    readonly property int poolMaxModules: 5

    function getModuleWeight(modId) {
        if (!isCenteredMode) return 1;
        if (modId === "systemMonitor" || modId === "activeWindow" || modId === "clock") return 2;
        return 1;
    }

    function getClusterPoints(modulesList) {
        if (!modulesList) return 0;
        return modulesList.reduce(function(sum, m) { return sum + getModuleWeight(m); }, 0);
    }

    function getModuleStatus(clusterModules, index) {
        if (!isCenteredMode) return { isConflict: false, isOverflow: false, labelSuffix: "", tooltipText: "" };
        let modId = clusterModules[index];
        let hasCollision = clusterModules.includes("activeWindow") && clusterModules.includes("systemMonitor");
        let isConflict = (modId === "activeWindow" && hasCollision);

        let currentPoints = 0;
        let isOverflow = false;

        for (let i = 0; i <= index; i++) {
            let m = clusterModules[i];
            if (m === "activeWindow" && hasCollision) continue;
            let w = getModuleWeight(m);
            if (i === index) {
                if (currentPoints + w > maxClusterPoints) {
                    isOverflow = true;
                }
            } else {
                currentPoints += w;
            }
        }

        let label = "";
        let tooltip = "";
        if (isConflict) {
            label = " (Hidden)";
            tooltip = "Active Window is automatically hidden in Centered mode when System Monitor is on the same side.";
        } else if (isOverflow) {
            label = " (Exceeds Limit)";
            tooltip = "This module will not display because it exceeds the capacity limit for Centered mode.";
        }

        return { isConflict: isConflict, isOverflow: isOverflow, labelSuffix: label, tooltipText: tooltip };
    }

    property var allModules: [
        { id: "distroIcon", name: "Distro Icon", icon: "computer" },
        { id: "activeWindow", name: "Active Window", icon: "subtitles" },
        { id: "systemMonitor", name: "System Monitor", icon: "memory" },
        { id: "clock", name: "Clock", icon: "schedule" },
        { id: "networkSpeed", name: "Network Speed", icon: "network_check" },
        { id: "sysTray", name: "System Tray", icon: "inbox" },
        { id: "statusIconsGroup", name: "Status Icons (WiFi/Volume)", icon: "info" },
        { id: "battery", name: "Battery", icon: "battery_full" }
    ]

    function getLeftModules() {
        return (Config.ready && Config.options.statusBar && Config.options.statusBar.leftModules) ? Array.from(Config.options.statusBar.leftModules) : ["distroIcon", "activeWindow", "systemMonitor"];
    }

    function getRightModules() {
        return (Config.ready && Config.options.statusBar && Config.options.statusBar.rightModules) ? Array.from(Config.options.statusBar.rightModules) : ["networkSpeed", "sysTray", "statusIconsGroup", "battery"];
    }

    function getCenterModule() {
        return (Config.ready && Config.options.statusBar) ? (Config.options.statusBar.centerModule ?? "clock") : "clock";
    }

    function isUsed(modId) {
        let lefts = getLeftModules();
        let rights = getRightModules();
        let center = getCenterModule();
        return lefts.includes(modId) || rights.includes(modId) || (center === modId);
    }

    function getModuleName(modId) {
        let item = allModules.find(m => m.id === modId);
        return item ? item.name : modId;
    }

    function getAvailableForCluster() {
        return allModules.filter(m => !isUsed(m.id));
    }

    function addToLeftCluster(moduleId) {
        var list = getLeftModules();
        if (list.length >= poolMaxModules) return;
        list.push(moduleId);
        if (moduleId === "clock") Config.options.statusBar.centerModule = "none";
        Config.options.statusBar.leftModules = list;
        if (list.length >= poolMaxModules || getAvailableForCluster().length <= 0) leftMenuOpened = false;
    }

    function addToRightCluster(moduleId) {
        var list = getRightModules();
        if (list.length >= poolMaxModules) return;
        list.push(moduleId);
        if (moduleId === "clock") Config.options.statusBar.centerModule = "none";
        Config.options.statusBar.rightModules = list;
        if (list.length >= poolMaxModules || getAvailableForCluster().length <= 0) rightMenuOpened = false;
    }

    function moveLeftModule(moduleId, direction) {
        var list = getLeftModules();
        var idx = list.indexOf(moduleId);
        var target = idx + direction;
        if (target < 0 || target >= list.length) return;
        var temp = list[idx];
        list[idx] = list[target];
        list[target] = temp;
        Config.options.statusBar.leftModules = list;
    }

    function removeLeftModule(moduleId) {
        Config.options.statusBar.leftModules = getLeftModules().filter(function(m) { return m !== moduleId; });
    }

    function moveRightModule(idx, direction) {
        var list = getRightModules();
        var target = idx + direction;
        if (target < 0 || target >= list.length) return;
        var temp = list[idx];
        list[idx] = list[target];
        list[target] = temp;
        Config.options.statusBar.rightModules = list;
    }

    function removeRightModule(moduleId) {
        Config.options.statusBar.rightModules = getRightModules().filter(function(m) { return m !== moduleId; });
    }

    function toggleLeftMenu() { leftMenuOpened = !leftMenuOpened; }
    function toggleRightMenu() { rightMenuOpened = !rightMenuOpened; }

    SearchHandler { 
        searchString: "Status Bar"
        aliases: ["Bar", "Top Bar", "Panel", "Statusbar", "Distro Icon", "Notification Counter", "Notification Position"]
    }

    // ── Status Bar Section ──

    ColumnLayout {
        id: mainSectionCol
        Layout.fillWidth: true
        Layout.topMargin: 12 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale
    
                readonly property bool isM3Style: Config.ready && Config.options.statusBar && (Config.options.statusBar.moduleStyle === "m3")

    
                // Computed: background is ALWAYS active (style == 1)
                readonly property bool sbAlwaysSolid: Config.ready && Config.options.statusBar
                    ? (Config.options.statusBar.backgroundStyle ?? 0) === 1
                    : false
                // Computed: any background style is selected (style > 0)
                readonly property bool sbAnyBgStyle: Config.ready && Config.options.statusBar
                    ? (Config.options.statusBar.backgroundStyle ?? 0) > 0
                    : false
                // Gradient is active: only when bg is not ALWAYS solid + useGradient = true
                readonly property bool sbGradientActive: !sbAlwaysSolid
                    && (Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true)
    
                // Section Header
                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 4 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "view_compact"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Status Bar"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }
    
                ColumnLayout {
                    id: sbSettingsCol
                    Layout.fillWidth: true
                    spacing: 16 * Appearance.effectiveScale
    
                    Row {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52 * Appearance.effectiveScale
                        spacing: 4 * Appearance.effectiveScale
                        
                        SegmentedButton {
                            width: (parent.width - (4 * Appearance.effectiveScale)) / 2
                            height: parent.height
                            isHighlighted: Config.ready && Config.options.statusBar && Config.options.statusBar.moduleStyle !== "m3"
                            buttonText: "Base Style"
                            onClicked: if (Config.ready && Config.options.statusBar) Config.options.statusBar.moduleStyle = "base"
                        }
        
                        SegmentedButton {
                            width: (parent.width - (4 * Appearance.effectiveScale)) / 2
                            height: parent.height
                            isHighlighted: Config.ready && Config.options.statusBar && Config.options.statusBar.moduleStyle === "m3"
                            buttonText: "M3 Style"
                            onClicked: if (Config.ready && Config.options.statusBar) Config.options.statusBar.moduleStyle = "m3"
                        }
                    }

                    // ── Layout & Appearance ─────────────────────────────
                    StyledText {
                        text: "Layout & Appearance"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.topMargin: 12 * Appearance.effectiveScale
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale

                    // ── Auto Hide ──────────────────────────────────────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: autoHideRow.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: autoHideRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "visibility_off"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Auto hide"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.autoHide ?? false) : false
                                onToggled: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.autoHide = !Config.options.statusBar.autoHide
                            }
                        }
                    }

                    // ── Text color mode (disabled when bg is active) ────────────
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: statusBarTextRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        opacity: parent.parent.sbAlwaysSolid ? 0.4 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        RowLayout {
                            id: statusBarTextRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Text color"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "adaptive", label: "Adaptive" },
                                        { id: "light",    label: "Light" },
                                        { id: "dark",     label: "Dark" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        enabled: !sbSettingsCol.parent.sbAlwaysSolid
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.textColorMode === modelData.id
                                            : modelData.id === "adaptive"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar && !sbSettingsCol.parent.sbAlwaysSolid)
                                            Config.options.statusBar.textColorMode = modelData.id
                                    }
                                }
                            }
                        }
                    }
    
                    // ── Use Gradient (disabled ONLY when background is ALWAYS active) ──────────────
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: statusBarGradientRow.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        opacity: sbSettingsCol.parent.sbAlwaysSolid ? 0.4 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        RowLayout {
                            id: statusBarGradientRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "gradient"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Use gradient"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true
                                onToggled: if (Config.ready && Config.options.statusBar && !sbSettingsCol.parent.sbAlwaysSolid)
                                    Config.options.statusBar.useGradient = !Config.options.statusBar.useGradient
                            }
                        }
                    }
    
                    // ── Background Style (None / Always / Adaptive) ────────────
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: statusBarBgRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: statusBarBgRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "rectangle"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Background"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { val: 0, label: "None" },
                                        { val: 1, label: "Always" },
                                        { val: 2, label: "Adaptive" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.backgroundStyle === modelData.val
                                            : modelData.val === 0
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.backgroundStyle = modelData.val
                                    }
                                }
                            }
                        }
                    }

                     // ── Corner radius (visible when ANY background style is active) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sbCornerRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: sbSettingsCol.parent.sbAnyBgStyle && !sbSettingsCol.parent.isM3Style
                        RowLayout {
                            id: sbCornerRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 20 * Appearance.effectiveScale

                            RowLayout {
                                spacing: 16 * Appearance.effectiveScale
                                Layout.preferredWidth: 70 * Appearance.effectiveScale
                                MaterialSymbol { text: "rounded_corner"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { 
                                    text: "Corner radius"
                                    Layout.fillWidth: true
                                    color: Appearance.colors.colOnLayer1 
                                }
                            }

                            StyledSlider {
                                Layout.fillWidth: true
                                from: 0; to: 20; stepSize: 1
                                value: Config.ready && Config.options.statusBar ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20
                                onMoved: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.backgroundCornerRadius = Math.round(value)
                            }
                            StyledText {
                                text: Math.round(Config.ready && Config.options.statusBar
                                    ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20).toString() + "px"
                                color: Appearance.colors.colOnLayer1
                                Layout.preferredWidth: 50
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    // ── Layout Style (Standard / Centered) ────────────
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: layoutStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: layoutStyleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "center_focus_strong"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Layout Style"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "standard", label: "Standard" },
                                        { id: "centered", label: "Centered (HUD)" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.layoutStyle === modelData.id
                                            : modelData.id === "standard"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.layoutStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }


                    } // End Layout & Appearance ColumnLayout

                    // ── Modules Positioning ──────────────────────────────────
                    StyledText {
                        text: "Modules Positioning"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.topMargin: 12 * Appearance.effectiveScale
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale

                    // ── Center Module (Clock / None) ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: centerModuleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: centerModuleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "view_agenda"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Center Module"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "clock", label: "Clock" },
                                        { id: "none",  label: "None" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? (Config.options.statusBar.centerModule ?? "clock") === modelData.id
                                            : modelData.id === "clock"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar) {
                                            let currentCenter = Config.options.statusBar.centerModule ?? "clock";
                                            let newCenter = modelData.id;
                                            if (currentCenter === newCenter) return;
                                            
                                            let lefts = Array.from(Config.options.statusBar.leftModules || []);
                                            let rights = Array.from(Config.options.statusBar.rightModules || []);
                                            
                                            if (newCenter === "clock") {
                                                // Remove clock from left and right clusters if moving to center
                                                lefts = lefts.filter(m => m !== "clock");
                                                rights = rights.filter(m => m !== "clock");
                                            } else if (newCenter === "none" && currentCenter === "clock") {
                                                // Default to adding clock to right cluster if removed from center
                                                if (!rights.includes("clock") && !lefts.includes("clock")) {
                                                    if (rights.length < poolMaxModules) {
                                                        rights.push("clock");
                                                    } else if (lefts.length < poolMaxModules) {
                                                        lefts.push("clock");
                                                    }
                                                }
                                            }
                                            
                                            Config.options.statusBar.leftModules = lefts;
                                            Config.options.statusBar.rightModules = rights;
                                            Config.options.statusBar.centerModule = newCenter;
                                        }
                                    }
                                }
                            }
                        }
                    }



                    // ── Left Cluster Modules (Dynamic Drag/Reorder & Add) ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: leftModsCol.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        ColumnLayout {
                            id: leftModsCol
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 12 * Appearance.effectiveScale

                            RowLayout {
                                spacing: 16 * Appearance.effectiveScale
                                MaterialSymbol { text: "align_horizontal_left"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { text: "Left Cluster Modules (" + getClusterPoints(getLeftModules()) + "/" + maxClusterPoints + ")"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1; font.weight: Font.Medium }
                                
                                // Add Module Dropdown Button
                                Rectangle {
                                    implicitWidth: 28 * Appearance.effectiveScale
                                    implicitHeight: 28 * Appearance.effectiveScale
                                    radius: 14 * Appearance.effectiveScale
                                    color: Appearance.m3colors.m3primary
                                    visible: getAvailableForCluster().length > 0 && getLeftModules().length < poolMaxModules

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: leftMenuOpened ? "close" : "add"
                                        iconSize: 18 * Appearance.effectiveScale
                                        color: Appearance.m3colors.m3onPrimary
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: leftMenuOpened = !leftMenuOpened
                                    }
                                }
                            }

                            // Active List Flow
                            Flow {
                                Layout.fillWidth: true
                                spacing: 6 * Appearance.effectiveScale

                                Repeater {
                                    model: getLeftModules()
                                    delegate: Rectangle {
                                        required property string modelData
                                        required property int index

                                        readonly property var status: rootColumn.getModuleStatus(getLeftModules(), index)
                                        readonly property bool hasWarning: status.isConflict || status.isOverflow

                                        implicitWidth: modRow.implicitWidth + (16 * Appearance.effectiveScale)
                                        implicitHeight: 32 * Appearance.effectiveScale
                                        radius: 16 * Appearance.effectiveScale
                                        color: hasWarning ? Appearance.m3colors.m3errorContainer : Appearance.m3colors.m3secondaryContainer

                                        MouseArea {
                                            id: pillHoverAreaLeft
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.NoButton
                                        }

                                        StyledToolTip {
                                            text: status.tooltipText
                                            alternativeVisibleCondition: hasWarning && pillHoverAreaLeft.containsMouse
                                        }

                                        RowLayout {
                                            id: modRow
                                            anchors.centerIn: parent
                                            spacing: 6 * Appearance.effectiveScale

                                            MaterialSymbol {
                                                visible: hasWarning
                                                text: "warning"
                                                iconSize: 14 * Appearance.effectiveScale
                                                color: Appearance.m3colors.m3onErrorContainer
                                            }

                                            StyledText {
                                                text: getModuleName(modelData) + status.labelSuffix
                                                color: hasWarning ? Appearance.m3colors.m3onErrorContainer : Appearance.m3colors.m3onSecondaryContainer
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                font.weight: Font.Medium
                                            }

                                            // Move Left
                                            MaterialSymbol {
                                                visible: index > 0
                                                text: "arrow_back"
                                                iconSize: 14 * Appearance.effectiveScale
                                                color: hasWarning ? Appearance.m3colors.m3onErrorContainer : Appearance.m3colors.m3onSecondaryContainer
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        let list = getLeftModules();
                                                        let realIdx = list.indexOf(modelData);
                                                        if (realIdx > 0) {
                                                            let temp = list[realIdx];
                                                            list[realIdx] = list[realIdx - 1];
                                                            list[realIdx - 1] = temp;
                                                            Config.options.statusBar.leftModules = list;
                                                        }
                                                    }
                                                }
                                            }

                                            // Move Right
                                            MaterialSymbol {
                                                visible: index < (getLeftModules().length - 1)
                                                text: "arrow_forward"
                                                iconSize: 14 * Appearance.effectiveScale
                                                color: hasWarning ? Appearance.m3colors.m3onErrorContainer : Appearance.m3colors.m3onSecondaryContainer
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        let list = getLeftModules();
                                                        let realIdx = list.indexOf(modelData);
                                                        if (realIdx < list.length - 1) {
                                                            let temp = list[realIdx];
                                                            list[realIdx] = list[realIdx + 1];
                                                            list[realIdx + 1] = temp;
                                                            Config.options.statusBar.leftModules = list;
                                                        }
                                                    }
                                                }
                                            }

                                            // Remove
                                            MaterialSymbol {
                                                text: "close"
                                                iconSize: 14 * Appearance.effectiveScale
                                                color: hasWarning ? Appearance.m3colors.m3onErrorContainer : Appearance.m3colors.m3onSecondaryContainer
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        let list = getLeftModules().filter(m => m !== modelData);
                                                        Config.options.statusBar.leftModules = list;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Add Dropdown Menu
                            ColumnLayout {
                                id: leftAddMenu
                                visible: leftMenuOpened && getAvailableForCluster().length > 0
                                Layout.fillWidth: true
                                spacing: 4 * Appearance.effectiveScale

                                StyledText {
                                    text: "Available modules to add:"
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 4 * Appearance.effectiveScale
                                    Repeater {
                                        model: getAvailableForCluster()
                                        delegate: Rectangle {
                                            required property var modelData
                                            implicitWidth: addRow.implicitWidth + (12 * Appearance.effectiveScale)
                                            implicitHeight: 28 * Appearance.effectiveScale
                                            radius: 14 * Appearance.effectiveScale
                                            color: Appearance.m3colors.m3surfaceContainerLow

                                            RowLayout {
                                                id: addRow
                                                anchors.centerIn: parent
                                                spacing: 4 * Appearance.effectiveScale
                                                MaterialSymbol { text: modelData.icon; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                                StyledText { text: modelData.name; font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colOnLayer1 }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: addToLeftCluster(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Right Cluster Modules (Dynamic Drag/Reorder & Add) ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: rightModsCol.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        ColumnLayout {
                            id: rightModsCol
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 12 * Appearance.effectiveScale

                            RowLayout {
                                spacing: 16 * Appearance.effectiveScale
                                MaterialSymbol { text: "align_horizontal_right"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { text: "Right Cluster Modules (" + getClusterPoints(getRightModules()) + "/" + maxClusterPoints + ")"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1; font.weight: Font.Medium }

                                // Add Module Dropdown Button
                                Rectangle {
                                    implicitWidth: 28 * Appearance.effectiveScale
                                    implicitHeight: 28 * Appearance.effectiveScale
                                    radius: 14 * Appearance.effectiveScale
                                    color: Appearance.m3colors.m3primary
                                    visible: getAvailableForCluster().length > 0 && getRightModules().length < poolMaxModules

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: rightMenuOpened ? "close" : "add"
                                        iconSize: 18 * Appearance.effectiveScale
                                        color: Appearance.m3colors.m3onPrimary
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: rightMenuOpened = !rightMenuOpened
                                    }
                                }
                            }

                            // Active List Flow
                            Flow {
                                Layout.fillWidth: true
                                spacing: 6 * Appearance.effectiveScale

                                Repeater {
                                    model: getRightModules()
                                    delegate: Rectangle {
                                        required property string modelData
                                        required property int index

                                        readonly property var status: rootColumn.getModuleStatus(getRightModules(), index)
                                        readonly property bool hasWarning: status.isConflict || status.isOverflow

                                        implicitWidth: modRowRight.implicitWidth + (16 * Appearance.effectiveScale)
                                        implicitHeight: 32 * Appearance.effectiveScale
                                        radius: 16 * Appearance.effectiveScale
                                        color: hasWarning ? Appearance.m3colors.m3errorContainer : Appearance.m3colors.m3tertiaryContainer

                                        MouseArea {
                                            id: pillHoverAreaRight
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.NoButton
                                        }

                                        StyledToolTip {
                                            text: status.tooltipText
                                            alternativeVisibleCondition: hasWarning && pillHoverAreaRight.containsMouse
                                        }

                                        RowLayout {
                                            id: modRowRight
                                            anchors.centerIn: parent
                                            spacing: 6 * Appearance.effectiveScale

                                            MaterialSymbol {
                                                visible: hasWarning
                                                text: "warning"
                                                iconSize: 14 * Appearance.effectiveScale
                                                color: Appearance.m3colors.m3onErrorContainer
                                            }

                                            StyledText {
                                                text: getModuleName(modelData) + status.labelSuffix
                                                color: hasWarning ? Appearance.m3colors.m3onErrorContainer : Appearance.m3colors.m3onTertiaryContainer
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                font.weight: Font.Medium
                                            }

                                            // Move Left
                                            MaterialSymbol {
                                                visible: index > 0
                                                text: "arrow_back"
                                                iconSize: 14 * Appearance.effectiveScale
                                                color: hasWarning ? Appearance.m3colors.m3onErrorContainer : Appearance.m3colors.m3onTertiaryContainer
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        let list = getRightModules();
                                                        let temp = list[index];
                                                        list[index] = list[index - 1];
                                                        list[index - 1] = temp;
                                                        Config.options.statusBar.rightModules = list;
                                                    }
                                                }
                                            }

                                            // Move Right
                                            MaterialSymbol {
                                                visible: index < (getRightModules().length - 1)
                                                text: "arrow_forward"
                                                iconSize: 14 * Appearance.effectiveScale
                                                color: hasWarning ? Appearance.m3colors.m3onErrorContainer : Appearance.m3colors.m3onTertiaryContainer
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        let list = getRightModules();
                                                        let temp = list[index];
                                                        list[index] = list[index + 1];
                                                        list[index + 1] = temp;
                                                        Config.options.statusBar.rightModules = list;
                                                    }
                                                }
                                            }

                                            // Remove
                                            MaterialSymbol {
                                                text: "close"
                                                iconSize: 14 * Appearance.effectiveScale
                                                color: hasWarning ? Appearance.m3colors.m3onErrorContainer : Appearance.m3colors.m3onTertiaryContainer
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        let list = getRightModules().filter(m => m !== modelData);
                                                        Config.options.statusBar.rightModules = list;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Add Dropdown Menu
                            ColumnLayout {
                                id: rightAddMenu
                                visible: rightMenuOpened && getAvailableForCluster().length > 0
                                Layout.fillWidth: true
                                spacing: 4 * Appearance.effectiveScale

                                StyledText {
                                    text: "Available modules to add:"
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 4 * Appearance.effectiveScale
                                    Repeater {
                                        model: getAvailableForCluster()
                                        delegate: Rectangle {
                                            required property var modelData
                                            implicitWidth: addRowRight.implicitWidth + (12 * Appearance.effectiveScale)
                                            implicitHeight: 28 * Appearance.effectiveScale
                                            radius: 14 * Appearance.effectiveScale
                                            color: Appearance.m3colors.m3surfaceContainerLow

                                            RowLayout {
                                                id: addRowRight
                                                anchors.centerIn: parent
                                                spacing: 4 * Appearance.effectiveScale
                                                MaterialSymbol { text: modelData.icon; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                                StyledText { text: modelData.name; font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colOnLayer1 }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: addToRightCluster(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }


                    // ── Notification Unread Attachment (Distro Icon vs Status Icons) ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: notifPositionRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: notifPositionRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "notifications"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Notification Unread Badge Host"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "distroIcon", label: "Distro Icon" },
                                        { id: "statusIconsGroup", label: "Status Icons" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.notifications
                                            ? (Config.options.notifications.hostModule ?? "distroIcon") === modelData.id
                                            : modelData.id === "distroIcon"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.notifications)
                                            Config.options.notifications.hostModule = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Notification Counter Style ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: notifCounterStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: notifCounterStyleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "mark_chat_unread"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Notification Counter"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "counter", label: "Counter" },
                                        { id: "simple", label: "Simple" },
                                        { id: "hidden", label: "Hidden" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.notifications
                                            ? Config.options.notifications.counterStyle === modelData.id
                                            : modelData.id === "counter"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.notifications)
                                            Config.options.notifications.counterStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── System Monitor Options ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sysMonRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: Config.ready && Config.options.statusBar && (
                            (Config.options.statusBar.leftModules && Config.options.statusBar.leftModules.includes("systemMonitor")) ||
                            (Config.options.statusBar.rightModules && Config.options.statusBar.rightModules.includes("systemMonitor"))
                        )
                        RowLayout {
                            id: sysMonRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "memory"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "System Monitor Options"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            
                            RowLayout {
                                spacing: 10 * Appearance.effectiveScale
                                
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorCpu ?? true) : true
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorCpu = !Config.options.statusBar.showSystemMonitorCpu
                                    }
                                    StyledText { text: "CPU"; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorRam ?? true) : true
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorRam = !Config.options.statusBar.showSystemMonitorRam
                                    }
                                    StyledText { text: "RAM"; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorSwap ?? false) : false
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorSwap = !Config.options.statusBar.showSystemMonitorSwap
                                    }
                                    StyledText { text: "Swap"; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorTemp ?? true) : true
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorTemp = !Config.options.statusBar.showSystemMonitorTemp
                                    }
                                    StyledText { text: "Temp"; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorText ?? false) : false
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorText = !Config.options.statusBar.showSystemMonitorText
                                    }
                                    StyledText { text: "Text"; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                            }
                        }
                    }

                    // ── System Monitor Style ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sysMonStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: Config.ready && Config.options.statusBar && (
                            (Config.options.statusBar.leftModules && Config.options.statusBar.leftModules.includes("systemMonitor")) ||
                            (Config.options.statusBar.rightModules && Config.options.statusBar.rightModules.includes("systemMonitor"))
                        )
                        RowLayout {
                            id: sysMonStyleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "style"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "System Monitor Style"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "outline", label: "Outline" },
                                        { id: "filled", label: "Filled" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? (Config.options.statusBar.systemMonitorStyle ?? "outline") === modelData.id
                                            : modelData.id === "outline"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.systemMonitorStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Centered Width (only visible when centered is active) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: centeredWidthRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: Config.ready && Config.options.statusBar && Config.options.statusBar.layoutStyle === "centered" && !sbSettingsCol.parent.isM3Style
                        RowLayout {
                            id: centeredWidthRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 20 * Appearance.effectiveScale

                            RowLayout {
                                spacing: 16 * Appearance.effectiveScale
                                Layout.preferredWidth: 70 * Appearance.effectiveScale // Ramped down to give maximum space to slider
                                MaterialSymbol { text: "width_full"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { 
                                    text: "Centered width"
                                    Layout.fillWidth: true
                                    color: Appearance.colors.colOnLayer1 
                                }
                            }

                            StyledSlider {
                                Layout.fillWidth: true
                                from: 800; to: 2000; stepSize: 50
                                value: Config.ready && Config.options.statusBar ? (Config.options.statusBar.centeredWidth ?? 1200) : 1200
                                onMoved: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.centeredWidth = Math.round(value)
                            }
                            StyledText {
                                text: Math.round(Config.ready && Config.options.statusBar
                                    ? (Config.options.statusBar.centeredWidth ?? 1200) : 1200).toString() + "px"
                                color: Appearance.colors.colOnLayer1
                                Layout.preferredWidth: 50 * Appearance.effectiveScale
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    } // End Modules Positioning ColumnLayout

                    // ── Modules Styling ──────────────────────────────────────
                    StyledText {
                        text: "Modules Styling"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.topMargin: 12 * Appearance.effectiveScale
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale

                    // ── Workspace Style (Shape) ──
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: wsStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: wsStyleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "layers"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Indicator Shape"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "pill", label: "Pill" },
                                        { id: "unified", label: "Unified" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.workspaces
                                            ? Config.options.workspaces.indicatorStyle === modelData.id
                                            : modelData.id === "pill"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.workspaces)
                                            Config.options.workspaces.indicatorStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Workspace Style (Label) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: wsLabelRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: wsLabelRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "format_list_numbered"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Indicator Label"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "none", label: "None" },
                                        { id: "numeric", label: "Numeric" },
                                        { id: "japanese", label: "Japanese" },
                                        { id: "roman", label: "Roman" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.workspaces
                                            ? (Config.options.workspaces.indicatorLabel ?? "none") === modelData.id
                                            : modelData.id === "none"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.workspaces)
                                            Config.options.workspaces.indicatorLabel = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Island Style ──
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: islandStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: islandStyleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "animation"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Island Style"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "pill", label: "Pill" },
                                        { id: "waterdrop", label: "Waterdrop" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.islandStyle === modelData.id
                                            : modelData.id === "pill"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.islandStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Tray Style ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: trayStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: trayStyleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "apps"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Tray Style"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "all", label: "All" },
                                        { id: "adaptive", label: "Adaptive" },
                                        { id: "hide", label: "Hide" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? (Config.options.statusBar.trayStyle ?? "adaptive") === modelData.id
                                            : modelData.id === "adaptive"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.trayStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Volume Indicator ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: volumeIndicatorCol.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        ColumnLayout {
                            id: volumeIndicatorCol
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 12 * Appearance.effectiveScale

                            RowLayout {
                                id: volumeIndicatorRow
                                Layout.fillWidth: true
                                spacing: 16 * Appearance.effectiveScale
                                MaterialSymbol { text: "volume_up"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { text: "Volume Indicator"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                                AndroidToggle {
                                    checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showVolumeIndicator ?? true) : true
                                    onToggled: if (Config.ready && Config.options.statusBar)
                                        Config.options.statusBar.showVolumeIndicator = !Config.options.statusBar.showVolumeIndicator
                                }
                            }

                            RowLayout {
                                visible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showVolumeIndicator ?? true) : true
                                Layout.fillWidth: true
                                spacing: 16 * Appearance.effectiveScale

                                MaterialSymbol { text: "tune"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { text: "Display Mode"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }

                                RowLayout {
                                    spacing: 2 * Appearance.effectiveScale
                                    Repeater {
                                        model: [
                                            { id: "always", label: "Always" },
                                            { id: "mutedOnly", label: "Only Muted" }
                                        ]
                                        delegate: SegmentedButton {
                                            required property var modelData
                                            buttonText: modelData.label
                                            isHighlighted: Config.ready && Config.options.statusBar
                                                ? (Config.options.statusBar.volumeIndicatorMode ?? "mutedOnly") === modelData.id
                                                : modelData.id === "mutedOnly"
                                            colActive: Appearance.m3colors.m3primary
                                            colActiveText: Appearance.m3colors.m3onPrimary
                                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                                            onClicked: if (Config.ready && Config.options.statusBar)
                                                Config.options.statusBar.volumeIndicatorMode = modelData.id
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Workspace count ──────────────────────────────────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sbWorkspaceRow.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: sbWorkspaceRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "grid_view"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Workspace count"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 8 * Appearance.effectiveScale
                                M3IconButton {
                                    iconName: "remove"
                                    iconSize: 18 * Appearance.effectiveScale
                                    implicitWidth: 32 * Appearance.effectiveScale; implicitHeight: 32 * Appearance.effectiveScale
                                    buttonRadius: 16 * Appearance.effectiveScale
                                    colBackground: Appearance.m3colors.m3surfaceContainerLow
                                    color: Appearance.m3colors.m3primary
                                    onClicked: {
                                        if (Config.ready && Config.options.workspaces) {
                                            let val = Config.options.workspaces.max_shown ?? 5
                                            if (val > 1) Config.options.workspaces.max_shown = val - 1
                                        }
                                    }
                                }
                                StyledText {
                                    text: (Config.ready && Config.options.workspaces ? (Config.options.workspaces.max_shown ?? 5) : 5).toString()
                                    color: Appearance.colors.colOnLayer1
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    Layout.preferredWidth: 30 * Appearance.effectiveScale
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                M3IconButton {
                                    iconName: "add"
                                    iconSize: 18 * Appearance.effectiveScale
                                    implicitWidth: 32 * Appearance.effectiveScale; implicitHeight: 32 * Appearance.effectiveScale
                                    buttonRadius: 16 * Appearance.effectiveScale
                                    colBackground: Appearance.m3colors.m3surfaceContainerLow
                                    color: Appearance.m3colors.m3primary
                                    onClicked: {
                                        if (Config.ready && Config.options.workspaces) {
                                            let val = Config.options.workspaces.max_shown ?? 5
                                            if (val < 20) Config.options.workspaces.max_shown = val + 1
                                        }
                                    }
                                }
                            }
                        }
                    }

                    } // End Modules Styling ColumnLayout
                }
            }
    

}
