import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

/**
 * Caffeine / Inactivity Mode detail panel.
 * Three modes: Normal / Keep Awake / AFK (Screen OFF).
 */
Rectangle {
    id: root
    signal dismiss()

    property int currentMode: Config.ready ? (Config.options.quickSettings.caffeineMode || (Config.options.quickSettings.caffeineActive ? 1 : 0)) : 0
    signal setMode(int modeId)

    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.panel

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = true
    }

    readonly property var modes: [
        {
            modeId: 0,
            name: "Normal Inactivity",
            icon: "coffee",
            description: "Standard timers (dim 5m, screen off 6m, suspend 10m)."
        },
        {
            modeId: 1,
            name: "Keep Awake (Screen ON)",
            icon: "kettle",
            description: "Screen stays ON indefinitely. Never suspends."
        },
        {
            modeId: 2,
            name: "AFK Mode (Screen OFF)",
            icon: "visibility_off",
            description: "Turns screen OFF immediately. System stays active AFK."
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
                text: "Inactivity & Sleep Modes"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.m3colors.m3onSurface
            }

            MaterialSymbol {
                text: "bedtime"
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

        // ── Mode cards ──
        Repeater {
            model: root.modes
            delegate: RippleButton {
                id: modeCard
                required property var modelData
                property bool isActive: root.currentMode === modelData.modeId

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
                    root.setMode(modelData.modeId)
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
                        color: modeCard.isActive
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colLayer3
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: modeCard.modelData.icon
                            iconSize: 20 * Appearance.effectiveScale
                            fill: modeCard.isActive ? 1 : 0
                            color: modeCard.isActive
                                ? Appearance.colors.colOnPrimary
                                : Appearance.m3colors.m3onSurfaceVariant
                        }
                    }

                    // Text
                    Column {
                        Layout.fillWidth: true
                        spacing: 1 * Appearance.effectiveScale

                        StyledText {
                            text: modeCard.modelData.name
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: modeCard.isActive
                                ? Appearance.colors.colPrimary
                                : Appearance.m3colors.m3onSurface
                        }
                        StyledText {
                            text: modeCard.modelData.description
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.m3colors.m3onSurfaceVariant
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    // Checkmark
                    MaterialSymbol {
                        visible: modeCard.isActive
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
                implicitWidth: cafDoneText.implicitWidth + (24 * Appearance.effectiveScale)
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: height / 2
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Qt.darker(Appearance.colors.colPrimary, 1.1)
                onClicked: root.dismiss()
                StyledText {
                    id: cafDoneText
                    anchors.centerIn: parent
                    text: "Done"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
    }
}
