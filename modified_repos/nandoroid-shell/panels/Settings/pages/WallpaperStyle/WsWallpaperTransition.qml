import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    Layout.fillWidth: true
    spacing: 4 * Appearance.effectiveScale

    SearchHandler { 
        searchString: "Wallpaper Transition"
        aliases: ["Transition", "Animation", "Zaphkiel"]
    }

    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: transitionRow.implicitHeight + (36 * Appearance.effectiveScale)
        orientation: Qt.Vertical
        maxRadius: 20 * Appearance.effectiveScale
        color: Appearance.m3colors.m3surfaceContainerHigh
        
        RowLayout {
            id: transitionRow
            anchors.fill: parent
            anchors.margins: 16 * Appearance.effectiveScale
            spacing: 20 * Appearance.effectiveScale
            
            MaterialSymbol { text: "animation"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
            
            StyledText { text: "Wallpaper Transition"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
            
            StyledComboBox {
                Layout.preferredWidth: 240 * Appearance.effectiveScale
                searchable: false
                model: [
                    "Random",
                    "Doom Melt",
                    "Page Peel",
                    "Circle Expansion",
                    "Circle Pit",
                    "Circle Spin",
                    "Magic Blend",
                    "Pixelate",
                    "Stripes",
                    "Smooth Dissolve",
                    "Horizontal Sweep",
                    "Zoom Expand"
                ]
                text: {
                    if (!Config.ready) return "Random";
                    const t = Config.options.appearance.background.transition;
                    if (t === "Doom") return "Doom Melt";
                    if (t === "Peel") return "Page Peel";
                    if (t === "circle") return "Circle Expansion";
                    if (t === "circlePit") return "Circle Pit";
                    if (t === "circleSelect") return "Circle Spin";
                    if (t === "magic") return "Magic Blend";
                    if (t === "pixelate") return "Pixelate";
                    if (t === "stripes") return "Stripes";
                    if (t === "transition") return "Smooth Dissolve";
                    if (t === "sweep") return "Horizontal Sweep";
                    if (t === "expand") return "Zoom Expand";
                    return "Random";
                }
                onAccepted: function(value) {
                    if (!Config.ready) return;
                    text = value; // Update the UI immediately
                    
                    if (value === "Doom Melt") {
                        Config.options.appearance.background.transition = "Doom";
                    } else if (value === "Page Peel") {
                        Config.options.appearance.background.transition = "Peel";
                    } else if (value === "Circle Expansion") {
                        Config.options.appearance.background.transition = "circle";
                    } else if (value === "Circle Pit") {
                        Config.options.appearance.background.transition = "circlePit";
                    } else if (value === "Circle Spin") {
                        Config.options.appearance.background.transition = "circleSelect";
                    } else if (value === "Magic Blend") {
                        Config.options.appearance.background.transition = "magic";
                    } else if (value === "Pixelate") {
                        Config.options.appearance.background.transition = "pixelate";
                    } else if (value === "Stripes") {
                        Config.options.appearance.background.transition = "stripes";
                    } else if (value === "Smooth Dissolve") {
                        Config.options.appearance.background.transition = "transition";
                    } else if (value === "Horizontal Sweep") {
                        Config.options.appearance.background.transition = "sweep";
                    } else if (value === "Zoom Expand") {
                        Config.options.appearance.background.transition = "expand";
                    } else {
                        Config.options.appearance.background.transition = "random";
                    }
                }
            }
        }
    }

    // --- Selectable Random Transition Pool Panel ---
    SegmentedWrapper {
        visible: Config.ready && Config.options.appearance.background.transition === "random"
        Layout.fillWidth: true
        implicitHeight: randomPoolCol.implicitHeight + (32 * Appearance.effectiveScale)
        orientation: Qt.Vertical
        maxRadius: 20 * Appearance.effectiveScale
        color: Appearance.m3colors.m3surfaceContainerHigh

        ColumnLayout {
            id: randomPoolCol
            anchors.fill: parent
            anchors.margins: 16 * Appearance.effectiveScale
            spacing: 14 * Appearance.effectiveScale

            RowLayout {
                Layout.fillWidth: true
                MaterialSymbol { text: "checklist"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                StyledText {
                    text: "Random Mode Pool"
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
                StyledText {
                    text: "Select active transitions for random mode"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer2
                }
            }

            GridLayout {
                columns: 2
                columnSpacing: 20 * Appearance.effectiveScale
                rowSpacing: 10 * Appearance.effectiveScale
                Layout.fillWidth: true

                Repeater {
                    model: [
                        { id: "Doom",           name: "Doom Melt" },
                        { id: "Peel",           name: "Page Peel" },
                        { id: "circle",         name: "Circle Expansion" },
                        { id: "circlePit",      name: "Circle Pit" },
                        { id: "circleSelect",   name: "Circle Spin" },
                        { id: "magic",          name: "Magic Blend" },
                        { id: "pixelate",       name: "Pixelate" },
                        { id: "stripes",        name: "Stripes" },
                        { id: "transition",     name: "Smooth Dissolve" },
                        { id: "sweep",          name: "Horizontal Sweep" },
                        { id: "expand",         name: "Zoom Expand" }
                    ]

                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8 * Appearance.effectiveScale

                        StyledText {
                            text: parent.modelData.name
                            Layout.fillWidth: true
                            color: Appearance.colors.colOnLayer2
                            font.pixelSize: Appearance.font.pixelSize.small
                        }

                        AndroidToggle {
                            readonly property string itemKey: parent.modelData.id
                            checked: {
                                if (!Config.ready || !Config.options.appearance.background.randomTransitionPool) return true;
                                return Config.options.appearance.background.randomTransitionPool.includes(itemKey);
                            }
                            onToggled: {
                                if (!Config.ready) return;
                                let currentPool = Array.from(Config.options.appearance.background.randomTransitionPool || []);
                                if (checked) {
                                    currentPool = currentPool.filter(k => k !== itemKey);
                                } else {
                                    if (!currentPool.includes(itemKey)) currentPool.push(itemKey);
                                }
                                Config.options.appearance.background.randomTransitionPool = currentPool;
                            }
                        }
                    }
                }
            }
        }
    }
}
