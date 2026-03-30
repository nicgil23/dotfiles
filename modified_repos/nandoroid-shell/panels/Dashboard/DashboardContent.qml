import QtQuick
import QtQuick.Layouts
import "../../widgets"
import "../../core"
import "../../services"

/**
 * Drop-down Dashboard – 3 tabs: Calendar+Pomodoro, Translator, GitHub.
 * Slides down from the status bar and visually connects to the dynamic island.
 */
Item {
    id: root
    signal closed()

    property bool active: GlobalStates.dashboardOpen

    // -- Backdrop --------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.active ? 0.40 : 0
        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: root.closed() }
    }

    // -- Island Connector bridge -----------------------------------------------
    // A black trapezoid that grows from the pill width to the sheet width,
    // clipped by the status bar at the top. It gives the "sheet drops from island" feel.
    Item {
        id: bridgeArea
        anchors.horizontalCenter: parent.horizontalCenter
        width: sheet.width
        y: Appearance.sizes.statusBarHeight - 4 * Appearance.effectiveScale
        height: 12 * Appearance.effectiveScale
        visible: root.active
        opacity: root.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        // The connector: a rectangle the full width that merges into the sheet
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 8 * Appearance.effectiveScale
            color: Appearance.colors.colStatusBarSolid
            // No top radius — flat on top, matches bar bottom
            bottomLeftRadius: 0
            bottomRightRadius: 0
            topLeftRadius: 0
            topRightRadius: 0
        }
    }

    // -- Sheet Panel -----------------------------------------------------------
    Rectangle {
        id: sheet

        readonly property real barHeight: Appearance.sizes.statusBarHeight
        readonly property real sheetHeight: Math.min(580 * Appearance.effectiveScale, parent.height * 0.70)
        readonly property real hMargin: 32 * Appearance.effectiveScale

        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(940 * Appearance.effectiveScale, parent.width - hMargin * 2)
        height: sheetHeight

        y: root.active
            ? barHeight - 41 * Appearance.effectiveScale
            : -(sheetHeight + 40 * Appearance.effectiveScale)

        Behavior on y {
            NumberAnimation { duration: 440; easing.type: Easing.OutQuint }
        }

        // Square top, rounded bottom – visually "attached" to the bar
        radius: 20 * Appearance.effectiveScale
        topLeftRadius: 0
        topRightRadius: 0

        color: Appearance.colors.colStatusBarSolid
        clip: true

        layer.enabled: true
        layer.effect: null   // shadow handled separately below to avoid clip issues

        opacity: root.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 280 } }

        // Top highlight line (where bar meets sheet)
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        // -- Side Tab Strip ----------------------------------------------------
        Rectangle {
            id: sideTabs
            width: 68 * Appearance.effectiveScale
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Appearance.colors.colLayer0
            // Same radii as sheet: square top, rounded bottom-left
            topLeftRadius: 0
            bottomLeftRadius: sheet.radius

            property int currentTab: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 16 * Appearance.effectiveScale
                anchors.bottomMargin: 16 * Appearance.effectiveScale
                spacing: 6 * Appearance.effectiveScale

                Repeater {
                    model: [
                        { icon: "calendar_today", label: "Calendario" },
                        { icon: "translate",      label: "Traducir" },
                        { icon: "code",           label: "GitHub" }
                    ]
                    delegate: RippleButton {
                        required property var modelData
                        required property int index
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 48 * Appearance.effectiveScale
                        implicitHeight: 48 * Appearance.effectiveScale
                        buttonRadius: 24 * Appearance.effectiveScale
                        colBackground: sideTabs.currentTab === index
                            ? Appearance.colors.colPrimary : "transparent"
                        onClicked: sideTabs.currentTab = index

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: modelData.icon
                            iconSize: 22 * Appearance.effectiveScale
                            color: sideTabs.currentTab === index
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colOnLayer1
                        }
                        StyledToolTip { text: modelData.label }
                    }
                }

                Item { Layout.fillHeight: true }

                // Close button
                RippleButton {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 40 * Appearance.effectiveScale
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: Appearance.colors.colLayer2
                    onClicked: root.closed()
                    MaterialSymbol {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 2 * Appearance.effectiveScale
                        text: "close"
                        iconSize: 18 * Appearance.effectiveScale
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }
        }

        // Divider between side tabs and content
        Rectangle {
            anchors.left: sideTabs.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Qt.rgba(1, 1, 1, 0.06)
        }

        // -- Content Area ------------------------------------------------------
        StackLayout {
            anchors.left: sideTabs.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16 * Appearance.effectiveScale
            anchors.rightMargin: 16 * Appearance.effectiveScale
            anchors.topMargin: 16 * Appearance.effectiveScale
            anchors.bottomMargin: 16 * Appearance.effectiveScale
            currentIndex: sideTabs.currentTab

            // Tab 0: Calendar + Pomodoro (combined in DashCalendar)
            DashCalendar   { Layout.fillWidth: true; Layout.fillHeight: true }
            // Tab 1: Translator
            DashTranslation { Layout.fillWidth: true; Layout.fillHeight: true }
            // Tab 2: GitHub
            DashGitHub      { Layout.fillWidth: true; Layout.fillHeight: true }
        }
    }
}
