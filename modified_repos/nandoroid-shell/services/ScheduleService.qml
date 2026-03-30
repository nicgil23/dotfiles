pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * ScheduleService – singleton that persists calendar events to
 * ~/.cache/nandoroid/schedule.json
 * Each event: { id, title, date, time, endTime, recurrence, description, focus, lastFired }
 */
Singleton {
    id: root

    property var events: []
    readonly property string storagePath: Directories.home.replace("file://", "") + "/.cache/nandoroid/schedule.json"

    // -- Persistence --
    FileView {
        id: scheduleFile
        path: root.storagePath
        watchChanges: false
        onLoaded: {
            try {
                const parsed = JSON.parse(scheduleFile.text())
                if (Array.isArray(parsed)) root.events = parsed
            } catch(e) {
                root.events = []
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root.save()
        }
    }

    Component.onCompleted: {
        // Ensure directory exists before first load
        Quickshell.execDetached(["mkdir", "-p", storagePath.substring(0, storagePath.lastIndexOf('/'))])
        scheduleFile.reload()
    }

    function save() {
        scheduleFile.setText(JSON.stringify(root.events, null, 2))
    }

    // -- CRUD --
    function addEvent(ev) {
        events = events.concat([ev])
        save()
    }

    function updateEvent(id, fields) {
        events = events.map(e => e.id === id ? Object.assign({}, e, fields) : e)
        save()
    }

    function deleteEvent(id) {
        events = events.filter(e => e.id !== id)
        save()
    }
}
