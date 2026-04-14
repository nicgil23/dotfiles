import QtQuick
import qs.core
import qs.services
import qs.core
import qs.widgets
import qs.core

ToggleButton {
    buttonIcon: "grid_view"
    tooltipText: "Open Window Overview"

    onToggle: function () {
        if (GlobalStates.overviewOpen) {
            GlobalStates.closeAllPanels();
        } else {
            Visibilities.setActiveModule("overview");
        }
    }
}
