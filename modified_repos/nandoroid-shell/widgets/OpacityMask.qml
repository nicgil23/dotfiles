import QtQuick
import QtQuick.Effects

/**
 * Compatibility wrapper for OpacityMask from Qt5Compat.GraphicalEffects.
 * Uses modern QtQuick.Effects MultiEffect.
 */
Item {
    id: root
    property Item source
    property Item maskSource
    property bool invert: false

    MultiEffect {
        anchors.fill: parent
        source: root.source
        maskSource: root.maskSource
        maskEnabled: true
        maskInverted: root.invert
    }
}
