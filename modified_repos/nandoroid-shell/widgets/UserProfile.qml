import "../core"
import "../core/functions" as Functions
import "../services"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * Universal User Profile widget for sidebars.
 * Shows Avatar, Display Name (or real name), Hostname, and Distribution/Uptime info.
 */
Rectangle {
    id: root
    implicitWidth: parent.width
    implicitHeight: 72 * Appearance.effectiveScale
    color: "transparent"
    
    property bool compact: false
    signal clicked()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4 * Appearance.effectiveScale
        spacing: 14 * Appearance.effectiveScale
        
        // Circular Avatar
        Item {
            id: avatarContainer
            width: 44 * Appearance.effectiveScale; height: 44 * Appearance.effectiveScale
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            Layout.alignment: Qt.AlignVCenter
            
            Image {
                id: avatarImage
                anchors.fill: parent
                source: {
                    const profPath = Config.options.profile?.avatarPicture;
                    if (profPath && profPath !== "") return `file://${profPath}`;
                    const cfgPath = Config.options.bar?.avatar_path;
                    if (cfgPath && cfgPath !== "") return `file://${cfgPath}`;
                    if (SystemInfo.userAvatarValid) return "file://" + SystemInfo.userAvatarPath;
                    return "";
                }
                sourceSize: Qt.size(width, height)
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            Rectangle {
                id: maskRect
                anchors.fill: parent
                radius: width / 2
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: avatarImage
                maskSource: maskRect
                visible: avatarImage.status === Image.Ready
            }
            
            MaterialSymbol {
                anchors.centerIn: parent
                visible: avatarImage.status !== Image.Ready
                text: "person"
                iconSize: 22 * Appearance.effectiveScale
                color: Appearance.m3colors.m3onPrimaryContainer
            }

        }
        
        ColumnLayout {
            visible: !root.compact
            spacing: -2 * Appearance.effectiveScale
            Layout.fillWidth: true

            StyledText {
                text: {
                    const displayName = Config.options.profile?.displayName;
                    if (displayName && displayName !== "") return displayName;
                    return SystemInfo.realName || SystemInfo.username;
                }
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: Appearance.m3colors.m3onSurface
                elide: Text.ElideRight
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
            }
            StyledText {
                text: {
                    const descMode = Config.options.profile?.descriptionText || "::distro::";
                    if (descMode === "::uptime::") return "Up " + DateTime.uptime;
                    return SystemInfo.distroName || "Linux System";
                }
                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
            }
        }

        MouseArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
