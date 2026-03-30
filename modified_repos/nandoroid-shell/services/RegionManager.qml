pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../panels/RegionSelector"

Singleton {
    id: root

    function screenshot() {
        RegionSelector.screenshot()
    }

    function ocr() {
        RegionSelector.ocr()
    }

    function qrcode() {
        RegionSelector.qrcode()
    }

    function search() {
        RegionSelector.search()
    }

    function record() {
        RegionSelector.record()
    }

    function recordWithSound() {
        RegionSelector.recordWithSound()
    }

    function recordFullscreenWithSound() {
        RegionSelector.recordFullscreenWithSound()
    }


    function stopRecording() {
        Quickshell.execDetached(["bash", "-c", "pkill -SIGINT wf-recorder && notify-send 'Recording stopped'"]);
    }
}
