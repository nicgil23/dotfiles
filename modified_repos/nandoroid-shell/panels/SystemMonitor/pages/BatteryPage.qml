import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../../core"
import "../../../core/functions" as Functions
import "../../../services"
import "../../../widgets"

/**
 * Polished Battery Stats page for System Monitor.
 * Features OpacityMask hero battery bar, native stat cards,
 * and clean Hardware Information details section.
 */
Flickable {
    id: root
    contentHeight: mainCol.implicitHeight + (40 * Appearance.effectiveScale)
    clip: true
    
    // Smooth value for battery bar
    property real displayPercentage: Battery.percentage
    Behavior on displayPercentage { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }

    ColumnLayout {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20 * Appearance.effectiveScale
        spacing: 20 * Appearance.effectiveScale

        // Header Title
        StyledText {
            text: "Battery & Power"
            font.pixelSize: Appearance.font.pixelSize.huge
            font.weight: Font.DemiBold
            color: Appearance.m3colors.m3onSurface
        }

        // ── 1. Hero Battery Overview Card ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: heroCol.implicitHeight + (32 * Appearance.effectiveScale)
            radius: 16 * Appearance.effectiveScale
            color: Appearance.colors.colLayer2
            border.width: Math.max(1, 1 * Appearance.effectiveScale)
            border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOutlineVariant, 0.15)

            ColumnLayout {
                id: heroCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 20 * Appearance.effectiveScale
                anchors.rightMargin: 20 * Appearance.effectiveScale
                anchors.topMargin: 14 * Appearance.effectiveScale
                anchors.bottomMargin: 18 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale

                // Top Row: Big Percentage + Status Tag on left, Remaining Time / Source on right
                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8 * Appearance.effectiveScale
                        StyledText {
                            text: Math.round(root.displayPercentage * 100) + "%"
                            font.pixelSize: Math.round(36 * Appearance.effectiveScale)
                            font.weight: Font.DemiBold
                            color: Appearance.m3colors.m3onSurface
                        }

                        StyledText {
                            text: "•  " + (Battery.isCharging ? "Charging" : (Battery.chargeState === 4 ? "Fully Charged" : "Discharging"))
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Battery.isCharging ? Appearance.colors.colSuccess : Appearance.colors.colSubtext
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: {
                            if (Battery.isCharging && Battery.timeToFull > 0) return `${Math.round(Battery.timeToFull / 60)} mins until full`;
                            if (!Battery.isCharging && Battery.timeToEmpty > 0) return `${Math.round(Battery.timeToEmpty / 60)} mins remaining`;
                            return Battery.isPluggedIn ? "Power Source: AC Adapter" : "Power Source: Battery";
                        }
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colSubtext
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // Full-width Battery Progress Bar with OpacityMask (100% Perfect Rounded Clipping)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6 * Appearance.effectiveScale

                    Item {
                        id: pillTrackContainer
                        Layout.fillWidth: true
                        height: 20 * Appearance.effectiveScale

                        Rectangle {
                            id: pillTrack
                            anchors.fill: parent
                            radius: height / 2
                            color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.12)
                        }

                        Item {
                            id: fillSource
                            anchors.fill: parent
                            visible: false

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.max(0, Math.min(1, root.displayPercentage))
                                color: {
                                    if (Battery.isCritical && !Battery.isCharging) return Appearance.colors.colError;
                                    if (Battery.isLow && !Battery.isCharging) return Appearance.colors.colWarning;
                                    if (Battery.isCharging) return Appearance.colors.colSuccess;
                                    return Appearance.colors.colPrimary;
                                }

                                Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: fillSource
                            maskSource: Rectangle {
                                width: pillTrackContainer.width
                                height: pillTrackContainer.height
                                radius: pillTrackContainer.height / 2
                            }
                        }
                    }

                    // Battery Terminal Tip
                    Rectangle {
                        width: 5 * Appearance.effectiveScale
                        height: 12 * Appearance.effectiveScale
                        radius: 2 * Appearance.effectiveScale
                        color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.25)
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        // ── 2. Stat Cards with Unique MaterialShape Badges ──
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 16 * Appearance.effectiveScale
            rowSpacing: 16 * Appearance.effectiveScale

            StatCard {
                Layout.fillWidth: true
                label: "Health"
                value: Battery.health > 0 ? (Math.round(Battery.health) + "%") : "N/A"
                icon: "favorite"
                materialShape: MaterialShape.Shape.Cookie12Sided
            }

            StatCard {
                Layout.fillWidth: true
                label: "Usage Rate"
                value: Battery.energyRate > 0 ? (Battery.energyRate.toFixed(1) + " W") : "0.0 W"
                icon: "bolt"
                materialShape: MaterialShape.Shape.SoftBurst
            }

            StatCard {
                Layout.fillWidth: true
                label: "Voltage"
                value: Battery.voltage > 0 ? (Battery.voltage.toFixed(2) + " V") : "N/A"
                icon: "electric_bolt"
                materialShape: MaterialShape.Shape.Clover4Leaf
            }

            StatCard {
                Layout.fillWidth: true
                label: "Cycles"
                value: Battery.cycles > 0 ? Battery.cycles.toString() : "0"
                icon: "autorenew"
                materialShape: MaterialShape.Shape.Cookie7Sided
            }
        }

        // ── 3. Technical & Hardware Specifications Card ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: techCol.implicitHeight + (32 * Appearance.effectiveScale)
            radius: 16 * Appearance.effectiveScale
            color: Appearance.colors.colLayer2
            border.width: Math.max(1, 1 * Appearance.effectiveScale)
            border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOutlineVariant, 0.15)

            ColumnLayout {
                id: techCol
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale

                RowLayout {
                    spacing: 8 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "info"
                        iconSize: 18 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Hardware Information"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onSurface
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 16 * Appearance.effectiveScale
                    columnSpacing: 32 * Appearance.effectiveScale

                    TechInfo { label: "Vendor"; value: Battery.vendor || "Unknown" }
                    TechInfo { label: "Model"; value: Battery.model || "Generic Battery" }
                    TechInfo { label: "Technology"; value: Battery.technology || "Lithium-Ion" }
                    TechInfo { label: "Serial Number"; value: Battery.serial || "Not Available" }
                    TechInfo { label: "Design Capacity"; value: (Battery.energyFullDesign || 0).toFixed(2) + " Wh" }
                    TechInfo { label: "Full Capacity"; value: (Battery.energyFull || 0).toFixed(2) + " Wh" }
                }
            }
        }
    }

    // ── Internal Components ──

    // StatCard with customizable MaterialShape for unique shapes per card
    component StatCard: Rectangle {
        id: cardRoot
        property string label
        property string value
        property string icon
        property var materialShape: MaterialShape.Shape.Cookie12Sided
        
        implicitHeight: Math.round(width * 0.8)
        radius: 16 * Appearance.effectiveScale
        color: Appearance.colors.colLayer2
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOutlineVariant, 0.15)
        
        Item {
            anchors.fill: parent
            anchors.margins: 16 * Appearance.effectiveScale

            // Top-Right Scalloped MaterialShape Icon Badge
            MaterialShapeWrappedMaterialSymbol {
                anchors.right: parent.right
                anchors.top: parent.top
                text: cardRoot.icon
                iconSize: 18 * Appearance.effectiveScale
                padding: 8 * Appearance.effectiveScale
                shape: cardRoot.materialShape
                color: Appearance.colors.colSecondaryContainer
                colSymbol: Appearance.colors.colOnSecondaryContainer
            }

            // Bottom-Left Value & Label Stack
            ColumnLayout {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 48 * Appearance.effectiveScale
                spacing: 2 * Appearance.effectiveScale

                StyledText {
                    text: cardRoot.value
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.DemiBold
                    color: Appearance.m3colors.m3onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                StyledText {
                    text: cardRoot.label
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }

    component TechInfo: ColumnLayout {
        id: infoRoot
        property string label
        property string value
        spacing: 2 * Appearance.effectiveScale
        Layout.fillWidth: true

        StyledText {
            text: infoRoot.label
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.weight: Font.Medium
            color: Appearance.colors.colSubtext
        }
        StyledText {
            text: infoRoot.value
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.m3colors.m3onSurface
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
