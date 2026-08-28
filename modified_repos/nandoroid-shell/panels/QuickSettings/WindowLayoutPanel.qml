import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

/**
 * Window Layout detail panel in Quick Settings.
 * Option cards: Dwindle, Master, Scrolling.
 */
Rectangle {
    id: root
    signal dismiss()

    readonly property string currentLayout: GlobalStates.hyprlandLayout || "dwindle"

    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.panel

    // Block clicks from leaking through to the header
    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = true
    }

    readonly property var layouts: [
        {
            id: "dwindle",
            name: "Dwindle",
            icon: "view_quilt",
            description: "Binary tree spiral layout splitting windows automatically."
        },
        {
            id: "master",
            name: "Master",
            icon: "splitscreen",
            description: "Master main area on left with vertical slave stack on right."
        },
        {
            id: "scrolling",
            name: "Scrolling",
            icon: "view_column",
            description: "Horizontal scrolling column-based workspace layout."
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14 * Appearance.effectiveScale
        spacing: 12 * Appearance.effectiveScale

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale

            RippleButton {
                implicitWidth: 36 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.dismiss()
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3onSurface
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "Window Layout"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.m3colors.m3onSurface
            }

            MaterialSymbol {
                text: "dashboard"
                iconSize: 22 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
        }

        // ── Separator ──
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.m3colors.m3outlineVariant
        }

        // ── Layout cards ──
        Repeater {
            model: root.layouts
            delegate: RippleButton {
                id: layoutCard
                required property var modelData
                property bool isActive: root.currentLayout === modelData.id

                Layout.fillWidth: true
                implicitHeight: 64 * Appearance.effectiveScale
                buttonRadius: 16 * Appearance.effectiveScale
                colBackground: isActive
                    ? Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82)
                    : Appearance.colors.colLayer2
                colBackgroundHover: isActive
                    ? Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.75)
                    : Appearance.colors.colLayer2Hover

                onClicked: {
                    HyprlandData.setLayout(modelData.id);
                }

                Behavior on colBackground { ColorAnimation { duration: 150 } }

                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14 * Appearance.effectiveScale
                    anchors.rightMargin: 14 * Appearance.effectiveScale
                    spacing: 12 * Appearance.effectiveScale

                    // Icon circle
                    Rectangle {
                        implicitWidth: 36 * Appearance.effectiveScale
                        implicitHeight: 36 * Appearance.effectiveScale
                        radius: 18 * Appearance.effectiveScale
                        color: layoutCard.isActive
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colLayer3
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: layoutCard.modelData.icon
                            iconSize: 20 * Appearance.effectiveScale
                            fill: layoutCard.isActive ? 1 : 0
                            color: layoutCard.isActive
                                ? Appearance.colors.colOnPrimary
                                : Appearance.m3colors.m3onSurfaceVariant
                        }
                    }

                    // Text
                    Column {
                        Layout.fillWidth: true
                        spacing: 1 * Appearance.effectiveScale

                        StyledText {
                            text: layoutCard.modelData.name
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: layoutCard.isActive
                                ? Appearance.colors.colPrimary
                                : Appearance.m3colors.m3onSurface
                        }
                        StyledText {
                            text: layoutCard.modelData.description
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.m3colors.m3onSurfaceVariant
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    // Checkmark
                    MaterialSymbol {
                        visible: layoutCard.isActive
                        text: "check_circle"
                        iconSize: 20 * Appearance.effectiveScale
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ── Footer ──
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.m3colors.m3outlineVariant
        }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            RippleButton {
                implicitWidth: doneText.implicitWidth + (24 * Appearance.effectiveScale)
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: height / 2
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Qt.darker(Appearance.colors.colPrimary, 1.1)
                onClicked: root.dismiss()
                StyledText {
                    id: doneText
                    anchors.centerIn: parent
                    text: "Done"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
    }
}
