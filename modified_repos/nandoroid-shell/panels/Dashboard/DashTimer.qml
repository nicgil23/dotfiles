import "../../core"
import "../../widgets"
import "../../services"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

RowLayout {
    id: root
    spacing: 16 * Appearance.effectiveScale

    // Helper function to parse user inputted time string into seconds
    function parseTimeInput(text) {
        const clean = text.trim();
        if (clean === "") return 0;
        const parts = clean.split(':').map(x => parseInt(x, 10) || 0);
        if (parts.length === 3) {
            return parts[0] * 3600 + parts[1] * 60 + parts[2];
        } else if (parts.length === 2) {
            return parts[0] * 60 + parts[1];
        } else if (parts.length === 1) {
            return parts[0] * 60; // Treat single number as minutes
        }
        return 60;
    }

    // --- Left Section: Cronómetro (Stopwatch) ---
    Rectangle {
        Layout.fillHeight: true
        Layout.fillWidth: true
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.large
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.05)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24 * Appearance.effectiveScale
            spacing: 16 * Appearance.effectiveScale

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "timer"
                    iconSize: 22 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Cronómetro"
                    font.pixelSize: 15 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                Item { Layout.fillWidth: true }
            }

            // Big Clock Display
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8 * Appearance.effectiveScale

                    StyledText {
                        text: StopwatchService.timeStringDetailed
                        font.pixelSize: 42 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        font.family: Appearance.font.family.numbers
                        color: Appearance.colors.colOnLayer1
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledText {
                        text: StopwatchService.active ? "En ejecución" : "Pausado"
                        font.pixelSize: 12 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16 * Appearance.effectiveScale

                M3IconButton {
                    iconName: "stop"
                    onClicked: StopwatchService.reset()
                    StyledToolTip { text: "Restaurar" }
                }

                // Play/Pause Pill Button
                RippleButton {
                    id: startStopwatchPill
                    implicitWidth: 120 * Appearance.effectiveScale
                    implicitHeight: 44 * Appearance.effectiveScale
                    buttonRadius: 22 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3primary
                    colText: Appearance.m3colors.m3onPrimary

                    onClicked: {
                        if (StopwatchService.active) StopwatchService.pause();
                        else StopwatchService.start();
                    }

                    contentItem: RowLayout {
                        spacing: 8 * Appearance.effectiveScale
                        Layout.alignment: Qt.AlignHCenter
                        MaterialSymbol {
                            text: StopwatchService.active ? "pause" : "play_arrow"
                            iconSize: 20 * Appearance.effectiveScale
                            color: startStopwatchPill.colText
                            anchors.horizontalCenterOffset: (!StopwatchService.active) ? 2 * Appearance.effectiveScale : 0
                        }
                        StyledText {
                            text: StopwatchService.active ? "Pausar" : "Iniciar"
                            font.pixelSize: 13 * Appearance.effectiveScale
                            font.weight: Font.DemiBold
                            color: startStopwatchPill.colText
                        }
                    }
                }

                Item {
                    width: 40 * Appearance.effectiveScale
                    height: 40 * Appearance.effectiveScale
                }
            }
        }
    }

    // --- Right Section: Temporizador (Timer) ---
    Rectangle {
        Layout.fillHeight: true
        Layout.fillWidth: true
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.large
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.05)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24 * Appearance.effectiveScale
            spacing: 16 * Appearance.effectiveScale

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "hourglass_bottom"
                    iconSize: 22 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Temporizador"
                    font.pixelSize: 15 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                Item { Layout.fillWidth: true }
            }

            // Big Clock Display & Configurator
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12 * Appearance.effectiveScale

                    // Timer Display: editable TextField when paused/stopped, plain StyledText when running
                    TextField {
                        id: timerInput
                        visible: !TimerService.active
                        text: TimerService.timeString
                        font.pixelSize: 42 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        font.family: Appearance.font.family.numbers
                        color: Appearance.colors.colOnLayer1
                        horizontalAlignment: TextInput.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        
                        background: null
                        selectByMouse: true
                        topPadding: 0
                        bottomPadding: 0
                        leftPadding: 0
                        rightPadding: 0
                        
                        onEditingFinished: {
                            const secs = root.parseTimeInput(text);
                            if (secs > 0) {
                                TimerService.setDuration(secs);
                            } else {
                                text = TimerService.timeString;
                            }
                        }
                        
                        onActiveFocusChanged: {
                            if (activeFocus) {
                                selectAll();
                            }
                        }
                        
                        Connections {
                            target: TimerService
                            function onTimeStringChanged() {
                                if (!timerInput.activeFocus) {
                                    timerInput.text = TimerService.timeString;
                                }
                            }
                        }
                        
                        Component.onCompleted: {
                            timerInput.text = TimerService.timeString;
                        }
                    }

                    StyledText {
                        visible: TimerService.active
                        text: TimerService.timeString
                        font.pixelSize: 42 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        font.family: Appearance.font.family.numbers
                        color: Appearance.colors.colOnLayer1
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Presets
                    RowLayout {
                        spacing: 4 * Appearance.effectiveScale
                        Layout.alignment: Qt.AlignHCenter

                        Repeater {
                            model: [
                                { label: "1m", secs: 60 },
                                { label: "5m", secs: 300 },
                                { label: "10m", secs: 600 },
                                { label: "30m", secs: 1800 }
                            ]
                            delegate: RippleButton {
                                implicitWidth: 44 * Appearance.effectiveScale
                                implicitHeight: 28 * Appearance.effectiveScale
                                buttonRadius: 14 * Appearance.effectiveScale
                                colBackground: TimerService.duration === modelData.secs ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                                onClicked: TimerService.setDuration(modelData.secs)

                                contentItem: StyledText {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.pixelSize: 11 * Appearance.effectiveScale
                                    font.weight: Font.Medium
                                    color: TimerService.duration === modelData.secs ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }

                    // Manual Adjustment controls
                    RowLayout {
                        spacing: 8 * Appearance.effectiveScale
                        Layout.alignment: Qt.AlignHCenter

                        M3IconButton {
                            iconName: "remove"
                            onClicked: TimerService.setDuration(TimerService.duration - 60)
                            StyledToolTip { text: "Restar 1 minuto" }
                        }

                        StyledText {
                            text: Math.round(TimerService.duration / 60) + " min"
                            font.pixelSize: 13 * Appearance.effectiveScale
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                        }

                        M3IconButton {
                            iconName: "add"
                            onClicked: TimerService.setDuration(TimerService.duration + 60)
                            StyledToolTip { text: "Sumar 1 minuto" }
                        }
                    }
                }
            }

            // Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16 * Appearance.effectiveScale

                M3IconButton {
                    iconName: "stop"
                    onClicked: TimerService.stop()
                    StyledToolTip { text: "Detener & Reset" }
                }

                // Play/Pause Pill Button
                RippleButton {
                    id: startTimerPill
                    implicitWidth: 120 * Appearance.effectiveScale
                    implicitHeight: 44 * Appearance.effectiveScale
                    buttonRadius: 22 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3primary
                    colText: Appearance.m3colors.m3onPrimary

                    onClicked: {
                        if (TimerService.active) TimerService.pause();
                        else TimerService.start();
                    }

                    contentItem: RowLayout {
                        spacing: 8 * Appearance.effectiveScale
                        Layout.alignment: Qt.AlignHCenter
                        MaterialSymbol {
                            text: TimerService.active ? "pause" : "play_arrow"
                            iconSize: 20 * Appearance.effectiveScale
                            color: startTimerPill.colText
                            anchors.horizontalCenterOffset: (!TimerService.active) ? 2 * Appearance.effectiveScale : 0
                        }
                        StyledText {
                            text: TimerService.active ? "Pausar" : "Iniciar"
                            font.pixelSize: 13 * Appearance.effectiveScale
                            font.weight: Font.DemiBold
                            color: startTimerPill.colText
                        }
                    }
                }

                Item {
                    width: 40 * Appearance.effectiveScale
                    height: 40 * Appearance.effectiveScale
                }
            }
        }
    }
}
