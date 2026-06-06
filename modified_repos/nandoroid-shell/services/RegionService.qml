pragma Singleton
import QtQuick
import Quickshell

import "../core"

Singleton {
    id: root
    
    function screenshot() { Quickshell.execDetached(Directories.ipcPrefix.concat(["ipc", "call", "region", "screenshot"])) }
    function search() { Quickshell.execDetached(Directories.ipcPrefix.concat(["ipc", "call", "region", "search"])) }
    function ocr() { Quickshell.execDetached(Directories.ipcPrefix.concat(["ipc", "call", "region", "ocr"])) }
    function record() { Quickshell.execDetached(Directories.ipcPrefix.concat(["ipc", "call", "region", "record"])) }
    function recordWithSound() { Quickshell.execDetached(Directories.ipcPrefix.concat(["ipc", "call", "region", "recordWithSound"])) }
    function recordFullscreenWithSound() { Quickshell.execDetached(Directories.ipcPrefix.concat(["ipc", "call", "region", "recordFullscreenWithSound"])) }
    function qrcode() { Quickshell.execDetached(Directories.ipcPrefix.concat(["ipc", "call", "region", "qrcode"])) }
}
