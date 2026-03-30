pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    
    function screenshot() { RegionManager.screenshot() }
    function search() { RegionManager.search() }
    function ocr() { RegionManager.ocr() }
    function record() { RegionManager.record() }
    function recordWithSound() { RegionManager.recordWithSound() }
    function recordFullscreenWithSound() { RegionManager.recordFullscreenWithSound() }
    function qrcode() { RegionManager.qrcode() }
}
