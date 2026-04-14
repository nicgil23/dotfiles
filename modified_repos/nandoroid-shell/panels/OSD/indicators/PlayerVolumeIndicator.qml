import qs.services
import QtQuick
import qs.widgets
import ".." 

OsdValueIndicator {
    id: osdValues
    value: MprisController.activePlayer?.volume ?? 0
    icon: "music_note"
    name: "Music"
    shape: "Cookie4Sided"
}
