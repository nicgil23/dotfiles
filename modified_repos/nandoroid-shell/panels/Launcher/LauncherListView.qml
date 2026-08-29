import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import "../../widgets"
import "../../core"

RippleButton {
    id: root
    
    property var result: modelData
    property bool selected: false
    
    width: parent ? parent.width : 0
    height: 48 * Appearance.effectiveScale
    
    colBackground: root.selected ? Qt.alpha(Appearance.m3colors.m3primary, 0.1) : "transparent"
    buttonRadius: Appearance.rounding.small
    
    onClicked: {
        if (result) {
            result.execute();
            GlobalStates.launcherOpen = false;
            GlobalStates.spotlightOpen = false;
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12 * Appearance.effectiveScale
        anchors.rightMargin: 12 * Appearance.effectiveScale
        spacing: 12 * Appearance.effectiveScale
        
        // Icon Container
        Item {
            Layout.preferredWidth: 28 * Appearance.effectiveScale
            Layout.preferredHeight: 28 * Appearance.effectiveScale
            Layout.alignment: Qt.AlignVCenter

            MaterialShape {
                id: iconBg
                anchors.fill: parent
                readonly property bool isNoneShape: Config.ready && Config.options.search ? Config.options.search.iconShape === "None" : false
                shapeString: Config.ready ? Config.options.search.iconShape : "Square"
                color: isNoneShape ? "transparent" : ((root.hovered || root.selected) ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3surfaceVariant)
                borderWidth: isNoneShape ? 0 : 1 * Appearance.effectiveScale
                borderColor: isNoneShape ? "transparent" : Qt.rgba(0, 0, 0, 0.1)
                
                IconImage {
                    id: iconImg
                    source: (result && !result.isPlugin) ? Quickshell.iconPath(result.icon || "application-x-executable", "image-missing") : ""
                    visible: result && !result.isPlugin && result.emoji === ""
                    width: (iconBg.isNoneShape ? 24 : 18) * Appearance.effectiveScale
                    height: (iconBg.isNoneShape ? 24 : 18) * Appearance.effectiveScale
                    anchors.centerIn: parent
                }

                StyledText {
                    text: result.emoji || ""
                    visible: result && result.emoji !== ""
                    anchors.centerIn: parent
                    font.pixelSize: Math.round((iconBg.isNoneShape ? 24 : 18) * Appearance.effectiveScale)
                }
                
                MaterialSymbol {
                    text: (result && result.isPlugin) ? (result.icon || "extension") : ""
                    visible: result && result.isPlugin && result.emoji === "" && !result.isImage
                    iconSize: (iconBg.isNoneShape ? 24 : 18) * Appearance.effectiveScale
                    anchors.centerIn: parent
                    color: (root.hovered || root.selected) ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurfaceVariant
                }

                ThumbnailImage {
                    anchors.fill: parent
                    sourcePath: (result && result.isImage) ? result.imagePath : ""
                    visible: !!(result && result.isImage)
                    fillMode: Image.PreserveAspectCrop
                }
            }
        }
        Column {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 1 * Appearance.effectiveScale
            
            StyledText {
                text: (result && result.name) ? result.name : ""
                font.pixelSize: Math.round(14 * Appearance.effectiveScale)
                font.weight: root.selected ? Font.DemiBold : Font.Medium
                color: root.selected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface
                elide: Text.ElideRight
            }
            
            StyledText {
                text: (result && result.subtitle) ? result.subtitle : ""
                visible: text !== ""
                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                color: root.selected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
                opacity: 0.7
                elide: Text.ElideRight
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: (result && result.category) ? result.category : (result && result.isPlugin ? "Command" : "Application")
            font.pixelSize: Math.round(11 * Appearance.effectiveScale)
            color: root.selected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
            opacity: 0.5
        }
    }
}
