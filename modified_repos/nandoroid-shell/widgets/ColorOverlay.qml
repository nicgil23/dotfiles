import QtQuick
import QtQuick.Effects

/**
 * Compatibility wrapper for ColorOverlay from Qt5Compat.GraphicalEffects.
 * Uses modern QtQuick.Effects MultiEffect.
 */
Item {
    id: root
    property Item source
    property color color

    MultiEffect {
        anchors.fill: parent
        source: root.source
        colorization: 1.0
        colorizationColor: root.color
    }
}
