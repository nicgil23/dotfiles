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
                model: ["Dynamic", "Horizontal Sweep", "Center Expand", "Random"]
                text: {
                    if (!Config.ready) return "Random";
                    const transition = Config.options.appearance.background.transition;
                    if (transition === "sweep") return "Horizontal Sweep";
                    if (transition === "expand") return "Center Expand";
                    if (transition === "dynamic") return "Dynamic";
                    return "Random";
                }
                onAccepted: function(value) {
                    if (!Config.ready) return;
                    text = value; // Update the UI immediately
                    
                    if (value === "Horizontal Sweep") {
                        Config.options.appearance.background.transition = "sweep";
                    } else if (value === "Center Expand") {
                        Config.options.appearance.background.transition = "expand";
                    } else if (value === "Dynamic") {
                        Config.options.appearance.background.transition = "dynamic";
                    } else {
                        Config.options.appearance.background.transition = "random";
                    }
                }
            }
        }
    }
}
