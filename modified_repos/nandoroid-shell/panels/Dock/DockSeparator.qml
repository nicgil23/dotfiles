import QtQuick
import QtQuick.Layouts
import "../../core"

/**
 * Simple vertical separator for the dock.
 */
Rectangle {
    id: root
    Layout.fillHeight: true
    Layout.topMargin: 10 * Appearance.effectiveScale
    Layout.bottomMargin: 10 * Appearance.effectiveScale
    implicitWidth: Math.max(1, 1 * Appearance.effectiveScale)
    color: Appearance.colors.colOutlineVariant
    opacity: 0.5
}
