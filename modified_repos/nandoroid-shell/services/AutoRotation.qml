pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

/**
 * Service to manage iio-hyprland (auto-rotation daemon).
 * Manual toggle only, starts enabled by default as per Hyprland options.
 */
Singleton {
    id: root

    // Starts enabled by default as specified by user
    property bool active: true

    function enable() {
        Quickshell.execDetached(["bash", "-c", "pidof iio-hyprland || iio-hyprland &"])
        active = true
    }

    function disable() {
        Quickshell.execDetached(["pkill", "iio-hyprland"])
        active = false
    }

    function toggle() {
        if (active) disable()
        else enable()
    }
}
