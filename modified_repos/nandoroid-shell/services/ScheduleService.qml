pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * Schedule Service — manages events and persistence.
 */
Singleton {
    id: root

    property var events: []
    readonly property string storagePath: Directories.home.replace("file://", "") + "/.cache/nandoroid/schedule.json"

    // Normalize date/endDate to canonical YYYY-MM-DD (consumers compare/split ISO dates)
    // Only touches keys that exist, so partial updates (e.g. lastNotified* fields) don't wipe dates
    function _normalizeEvent(ev) {
        if (!ev) return ev
        const out = Object.assign({}, ev)
        if (ev.date !== undefined && ev.date !== null) out.date = GlobalStates.toCanonicalDateStr(ev.date) || ev.date
        if (ev.endDate !== undefined && ev.endDate !== null) out.endDate = GlobalStates.toCanonicalDateStr(ev.endDate) || ev.endDate
        return out
    }

    function save() {
        scheduleFile.setText(JSON.stringify(root.events, null, 2))
    }

    function deleteEvent(id) {
        root.events = root.events.filter(e => e.id !== id)
        save()
    }

    function addEvent(event) {
        root.events = [...root.events, root._normalizeEvent(event)]
        save()
    }

    function updateEvent(id, updatedFields) {
        root.events = root.events.map(e => e.id === id ? Object.assign({}, e, root._normalizeEvent(updatedFields)) : e)
        save()
    }

    FileView {
        id: scheduleFile
        path: root.storagePath
        onLoaded: {
            try {
                let content = scheduleFile.text()
                if (content && content.trim() !== "") {
                    let parsed = JSON.parse(content)
                    if (Array.isArray(parsed)) root.events = parsed.map(e => root._normalizeEvent(e))
                }
            } catch(e) {

            }
        }
    }

    Component.onCompleted: {
        // Ensure directory exists
        const dir = storagePath.substring(0, storagePath.lastIndexOf('/'));
        Quickshell.execDetached(["mkdir", "-p", dir]);
        scheduleFile.reload();
    }
}
