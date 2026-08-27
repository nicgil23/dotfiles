import "../../core"
import "../../widgets"
import "../../services"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ── Properties ──
    property var items: []
    property string _view: "list" // "list" | "notepad" | "todo"
    property string _editingId: ""

    readonly property string storagePath: Directories.home.replace("file://", "") + "/.cache/nandoroid/notes.json"

    function _currentItem() {
        return items.find(i => i.id === _editingId)
    }

    function makeId() { return Date.now().toString(36) + Math.random().toString(36).substr(2,5) }

    function stripHtml(html) {
        if (!html) return "";
        return html.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
    }

    function save() {
        const clean = root.items.map(i => {
            const c = {}
            for (const key in i) {
                if (key.startsWith("_")) continue
                c[key] = i[key]
            }
            return c
        })
        notesFile.setText(JSON.stringify(clean, null, 2))
        GlobalStates.updateTodoDeadlines(root.items)
    }

    function _flushSave() {
        if (saveTimer.running) {
            saveTimer.stop()
            _doSave()
        }
    }

    function goBack() {
        _flushSave()
        _view = "list"
        _editingId = ""
    }

    function openItem(id) {
        _flushSave()
        _editingId = id
        const item = _currentItem()
        if (!item) return
        _view = item.type
        if (item.type === "notepad") {
            noteTitleInput.text = item.title
            bodyArea.text = item.body
        } else if (item.type === "todo") {
            todoTitleInput.text = item.title
        }
    }

    function newNotepad() {
        const n = { type: "notepad", id: makeId(), title: "Untitled", body: "", color: "", updatedAt: new Date().toISOString() }
        root.items = [n].concat(root.items)
        save()
        openItem(n.id)
    }

    function newTodo() {
        const t = { type: "todo", id: makeId(), title: "Untitled", tasks: [], color: "", updatedAt: new Date().toISOString() }
        root.items = [t].concat(root.items)
        save()
        openItem(t.id)
    }

    function deleteCurrent() {
        if (!_editingId) return
        root.items = root.items.filter(i => i.id !== _editingId)
        save()
        goBack()
    }

    function deleteItem(itemId) {
        items = items.filter(i => i.id !== itemId)
        save()
    }

    // ── Todo task helpers ──
    function addTask() {
        const item = _currentItem()
        if (!item || item.type !== "todo") return
        item.tasks.push({ id: makeId(), content: "", done: false, deadline: null, deadlineTime: null })
        _refreshAndSave()
    }

    function removeTask(taskId) {
        const item = _currentItem()
        if (!item || item.type !== "todo") return
        item.tasks = item.tasks.filter(t => t.id !== taskId)
        _refreshAndSave()
    }

    function toggleTask(taskId) {
        const item = _currentItem()
        if (!item || item.type !== "todo") return
        const t = item.tasks.find(t => t.id === taskId)
        if (t) { t.done = !t.done; _refreshAndSave() }
    }

    function updateTaskContent(taskId, content) {
        const item = _currentItem()
        if (!item || item.type !== "todo") return
        const t = item.tasks.find(t => t.id === taskId)
        if (t) { t.content = content; save() }
    }

    function setTaskDeadline(taskId, date, time) {
        const item = _currentItem()
        if (!item || item.type !== "todo") return
        const t = item.tasks.find(t => t.id === taskId)
        if (t) { t.deadline = GlobalStates.toCanonicalDateStr(date) || null; t.deadlineTime = time || null; _refreshAndSave() }
    }

    function _refreshAndSave() {
        root.items = root.items.slice()
        save()
    }

    // ── Deadline helpers ──
    function _isDeadlineNear(deadline) {
        if (!deadline) return false
        const parts = deadline.split("-")
        if (parts.length !== 3) return false
        const d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]), 23, 59, 59)
        const now = new Date()
        return d.getTime() - now.getTime() < 86400000 && d.getTime() > now.getTime()
    }

    function _isDeadlineOverdue(deadline, deadlineTime) {
        if (!deadline) return false
        const parts = deadline.split("-")
        if (parts.length !== 3) return false
        const timePart = deadlineTime || "23:59"
        const timeParts = timePart.split(":")
        const d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]), parseInt(timeParts[0]) || 23, parseInt(timeParts[1]) || 59, 59)
        return d.getTime() < new Date().getTime()
    }

    function _displayTime(timeStr) {
        if (!timeStr) return timeStr
        const parts = String(timeStr).split(":")
        if (parts.length < 2) return timeStr
        const h = parseInt(parts[0], 10)
        if (isNaN(h)) return timeStr
        const m = parts[1]
        const rest = parts.length > 2 ? ":" + parts.slice(2).join(":") : ""
        const style = Config.ready && Config.options.time ? Config.options.time.timeStyle : "24H"
        if (style === "24H") return String(h).padStart(2, "0") + ":" + m + rest
        const upper = style === "12H_PM"
        const ap = h >= 12 ? (upper ? "PM" : "pm") : (upper ? "AM" : "am")
        const h12 = h % 12 || 12
        return String(h12).padStart(2, "0") + ":" + m + rest + " " + ap
    }

    function _displayDate(dStr) {
        if (!dStr) return dStr
        const style = Config.ready && Config.options.time ? (Config.options.time.dateStyle ?? "DMY") : "DMY"
        const parts = String(dStr).trim().split(/[-/]/).map(Number)
        if (parts.length < 3 || parts.some(isNaN)) return dStr
        let y, m, d
        if (parts[0] > 1000) { y = parts[0]; m = parts[1]; d = parts[2] }
        else if (style === "MDY") { m = parts[0]; d = parts[1]; y = parts[2] }
        else { d = parts[0]; m = parts[1]; y = parts[2] }
        if (!y || !m || !d) return dStr
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[new Date(y, m - 1, d).getDay()] + ", " + dStr
    }

    function _formatDeadline(deadline, deadlineTime) {
        if (!deadline) return ""
        const parts = deadline.split(/[-/]/)
        if (parts.length !== 3) return deadline
        const style = Config.ready && Config.options.time ? (Config.options.time.dateStyle ?? "DMY") : "DMY"
        let display = ""
        if (parts[0].length === 4) {
            // YYYY-MM-DD input
            if (style === "YMD") display = parts[0] + "/" + parts[1] + "/" + parts[2]
            else if (style === "MDY") display = parts[1] + "/" + parts[2]
            else display = parts[2] + "/" + parts[1]
        } else {
            display = deadline
        }
        if (deadlineTime) display += " " + root._displayTime(deadlineTime)
        return display
    }

    // ── File I/O ──
    FileView {
        id: notesFile
        path: root.storagePath
        watchChanges: false
        onLoaded: {
            try {
                let parsed = JSON.parse(notesFile.text())
                if (Array.isArray(parsed)) {
                    parsed = parsed.map(i => {
                        if (!i.type) { i.type = "notepad"; i.color = "" }
                        if (i.type === "todo" && !i.tasks) i.tasks = []
                        return i
                    })
                    root.items = parsed
                    GlobalStates.updateTodoDeadlines(parsed)
                }
            } catch(e) {}
        }
    }

    Component.onCompleted: notesFile.reload()

    // ── Auto-save timer ──
    function _doSave() {
        if (!root._editingId) return
        const now = new Date().toISOString()
        const item = root._currentItem()
        if (!item) return

        if (item.type === "notepad") {
            item.title = noteTitleInput.text
            item.body = bodyArea.text
        } else if (item.type === "todo") {
            item.title = todoTitleInput.text
        }
        item.updatedAt = now

        const idx = root.items.indexOf(item)
        if (idx > 0) {
            root.items.splice(idx, 1)
            root.items.unshift(item)
        }
        root.items = root.items.slice()
        root.save()
    }

    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: _doSave()
    }

    // ── Task content debounce timer ──
    property string _pendingTaskId: ""
    property string _pendingTaskContent: ""

    Timer {
        id: taskDebounceTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (root._pendingTaskId) {
                root.updateTaskContent(root._pendingTaskId, root._pendingTaskContent)
                root._pendingTaskId = ""
                root._pendingTaskContent = ""
            }
        }
    }

    function _defaultDeadlineDate() {
        let now = new Date()
        let y = now.getFullYear(), m = now.getMonth() + 1, d = now.getDate()
        const ys = String(y).padStart(4, '0')
        const ms = String(m).padStart(2, '0')
        const ds = String(d).padStart(2, '0')
        let style = Config.ready && Config.options.time ? (Config.options.time.dateStyle ?? "DMY") : "DMY"
        if (style === "YMD") return ys + "/" + ms + "/" + ds
        if (style === "MDY") return ms + "/" + ds + "/" + ys
        return ds + "/" + ms + "/" + ys
    }

    function _defaultDeadlineTime() {
        const now = new Date()
        let nextH = (now.getHours() + 1) % 24
        return String(nextH).padStart(2, '0') + ":00"
    }

    function openTaskDatePicker(taskId, currentDate) {
        GlobalStates.datePickerCurrentDate = currentDate || root._defaultDeadlineDate()
        GlobalStates.datePickerOnSelected = function(dateStr) {
            const item = root._currentItem()
            if (item && item.type === "todo") {
                const t = item.tasks.find(t => t.id === taskId)
                if (t) {
                    t._tmpDate = dateStr
                    t._editingDeadline = true
                    root.items = root.items.slice()
                }
            }
        }
        GlobalStates.datePickerOnCancelled = function() {}
        GlobalStates.datePickerOpen = true
    }

    function openTaskTimePicker(taskId, currentTime) {
        const item = root._currentItem()
        let activeTime = currentTime
        if (item && item.type === "todo") {
            const t = item.tasks.find(t => t.id === taskId)
            if (t) {
                activeTime = t._tmpTime || t.deadlineTime || currentTime
            }
        }

        GlobalStates.openTimePicker(
            activeTime || root._defaultDeadlineTime(),
            function(timeStr) {
                const curItem = root._currentItem()
                if (curItem && curItem.type === "todo") {
                    const t = curItem.tasks.find(t => t.id === taskId)
                    if (t) {
                        t._tmpTime = timeStr
                        t.deadlineTime = timeStr
                        t._editingDeadline = true
                        root.items = root.items.slice()
                    }
                }
            },
            function() {},
            Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : false
        )
    }

    // ══════════════════════════════════════════════════
    //  UI
    // ══════════════════════════════════════════════════
    Item {
        anchors.fill: parent
        anchors.margins: 16 * Appearance.effectiveScale

        // ──────────────────────────────────────────────
        //  STEP 1: LIST VIEW
        // ──────────────────────────────────────────────
        ColumnLayout {
            id: listView
            anchors.fill: parent
            spacing: 12 * Appearance.effectiveScale
            visible: root._view === "list"

            // ── Add Buttons ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 12 * Appearance.effectiveScale

                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44 * Appearance.effectiveScale
                    buttonRadius: 22 * Appearance.effectiveScale
                    colBackground: Appearance.colors.colPrimary
                    onClicked: root.newNotepad()
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6 * Appearance.effectiveScale
                        MaterialSymbol { text: "edit_note"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colOnPrimary }
                        StyledText { text: "Add Notepad"; color: Appearance.colors.colOnPrimary; font.weight: Font.Medium }
                    }
                }

                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44 * Appearance.effectiveScale
                    buttonRadius: 22 * Appearance.effectiveScale
                    colBackground: Appearance.colors.colSecondary
                    onClicked: root.newTodo()
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6 * Appearance.effectiveScale
                        MaterialSymbol { text: "checklist"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colOnSecondary }
                        StyledText { text: "Add Todo"; color: Appearance.colors.colOnSecondary; font.weight: Font.Medium }
                    }
                }
            }

            // ── Item List ──
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                clip: true

                ListView {
                    id: itemList
                    anchors.fill: parent
                    anchors.margins: 6 * Appearance.effectiveScale
                    spacing: 2 * Appearance.effectiveScale
                    model: root.items.slice().sort((a, b) =>
                        new Date(b.updatedAt) - new Date(a.updatedAt))

                    delegate: Item {
                        required property var modelData
                        width: itemList.width
                        height: 56 * Appearance.effectiveScale

                        readonly property bool isHovered: itemMouse.containsMouse

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            color: isHovered ? Appearance.m3colors.m3surfaceContainerHigh : "transparent"
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openItem(modelData.id)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10 * Appearance.effectiveScale
                            anchors.rightMargin: 10 * Appearance.effectiveScale
                            spacing: 10 * Appearance.effectiveScale

                            // Type icon
                            Rectangle {
                                implicitWidth: 28 * Appearance.effectiveScale
                                implicitHeight: 28 * Appearance.effectiveScale
                                radius: 14 * Appearance.effectiveScale
                                color: modelData.type === "todo"
                                    ? Appearance.colors.colSecondaryContainer
                                    : Appearance.colors.colPrimaryContainer
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: modelData.type === "todo" ? "checklist" : "edit_note"
                                    iconSize: 16 * Appearance.effectiveScale
                                    color: modelData.type === "todo"
                                        ? Appearance.colors.colOnSecondaryContainer
                                        : Appearance.colors.colOnPrimaryContainer
                                }
                            }

                            // Title + preview
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * Appearance.effectiveScale

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.title || "Untitled"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.type === "todo"
                                        ? (modelData.tasks
                                            ? modelData.tasks.filter(i => i.done).length + "/" + modelData.tasks.length + " done"
                                            : "0/0 done")
                                        : root.stripHtml(modelData.body).split("\n")[0] || "Empty notepad"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                }
                            }

                            // Type badge
                            Rectangle {
                                implicitWidth: badgeText.implicitWidth + 12 * Appearance.effectiveScale
                                implicitHeight: 20 * Appearance.effectiveScale
                                radius: 10 * Appearance.effectiveScale
                                color: modelData.type === "todo"
                                    ? Appearance.colors.colTertiaryContainer
                                    : Appearance.colors.colSecondaryContainer
                                StyledText {
                                    id: badgeText
                                    anchors.centerIn: parent
                                    text: modelData.type === "todo" ? "Todo" : "Note"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.Medium
                                    color: modelData.type === "todo"
                                        ? Appearance.colors.colOnTertiaryContainer
                                        : Appearance.colors.colOnSecondaryContainer
                                }
                            }

                            // Delete button
                            RippleButton {
                                implicitWidth: 28 * Appearance.effectiveScale
                                implicitHeight: 28 * Appearance.effectiveScale
                                buttonRadius: 14 * Appearance.effectiveScale
                                colBackground: "transparent"
                                onClicked: root.deleteItem(modelData.id)
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "delete"
                                    iconSize: 16 * Appearance.effectiveScale
                                    color: Appearance.colors.colError
                                }
                                StyledToolTip { text: "Delete" }
                            }
                        }
                    }
                }
            }
        }

        // ──────────────────────────────────────────────
        //  STEP 2: NOTEPAD EDITOR
        // ──────────────────────────────────────────────
        ColumnLayout {
            anchors.fill: parent
            spacing: 8 * Appearance.effectiveScale
            visible: root._view === "notepad"

            // Top bar: back + title + delete
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale

                RippleButton {
                    implicitWidth: 36 * Appearance.effectiveScale
                    implicitHeight: 36 * Appearance.effectiveScale
                    buttonRadius: 18 * Appearance.effectiveScale
                    colBackground: Appearance.colors.colLayer2
                    onClicked: root.goBack()
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        iconSize: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3onSurface
                    }
                }

                StyledTextInput {
                    id: noteTitleInput
                    Layout.fillWidth: true
                    implicitHeight: 40 * Appearance.effectiveScale
                    inputRadius: Appearance.rounding.small / Appearance.effectiveScale
                    backgroundColor: Appearance.m3colors.m3surfaceContainer
                    text: ""
                    placeholder: "Note title..."
                    onTextChanged: saveTimer.restart()
                }

                RippleButton {
                    implicitWidth: 40 * Appearance.effectiveScale
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainer
                    onClicked: root.deleteCurrent()
                    MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colError }
                    StyledToolTip { text: "Delete" }
                }
            }

            // Body editor
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                border.color: bodyArea.activeFocus ? Appearance.colors.colPrimary : "transparent"
                border.width: 2 * Appearance.effectiveScale
                clip: true

                Flickable {
                    id: bodyFlickable
                    anchors.fill: parent
                    anchors.margins: 12 * Appearance.effectiveScale
                    contentHeight: bodyArea.height
                    clip: true

                    TextEdit {
                        id: bodyArea
                        width: bodyFlickable.width
                        height: Math.max(implicitHeight, bodyFlickable.height)
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        wrapMode: TextEdit.Wrap
                        selectionColor: Appearance.colors.colPrimaryContainer
                        selectedTextColor: Appearance.colors.colOnPrimaryContainer
                        onTextChanged: saveTimer.restart()

                        onCursorRectangleChanged: {
                            const margin = 20 * Appearance.effectiveScale
                            if (cursorRectangle.y < bodyFlickable.contentY) {
                                bodyFlickable.contentY = cursorRectangle.y
                            } else if (cursorRectangle.y + cursorRectangle.height + margin > bodyFlickable.contentY + bodyFlickable.height) {
                                bodyFlickable.contentY = cursorRectangle.y + cursorRectangle.height - bodyFlickable.height + margin
                            }
                        }

                        StyledText {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            text: "Start typing your note..."
                            color: Appearance.colors.colSubtext
                            visible: !parent.text && !parent.activeFocus
                            font.pixelSize: Appearance.font.pixelSize.normal
                            wrapMode: Text.Wrap
                        }
                    }

                    ScrollBar.vertical: StyledScrollBar {}
                }
            }
        }

        // ──────────────────────────────────────────────
        //  STEP 2: TODO EDITOR
        // ──────────────────────────────────────────────
        ColumnLayout {
            anchors.fill: parent
            spacing: 8 * Appearance.effectiveScale
            visible: root._view === "todo"

            // Top bar: back + title + delete
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale

                RippleButton {
                    implicitWidth: 36 * Appearance.effectiveScale
                    implicitHeight: 36 * Appearance.effectiveScale
                    buttonRadius: 18 * Appearance.effectiveScale
                    colBackground: Appearance.colors.colLayer2
                    onClicked: root.goBack()
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        iconSize: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3onSurface
                    }
                }

                StyledTextInput {
                    id: todoTitleInput
                    Layout.fillWidth: true
                    implicitHeight: 40 * Appearance.effectiveScale
                    inputRadius: Appearance.rounding.small / Appearance.effectiveScale
                    backgroundColor: Appearance.m3colors.m3surfaceContainer
                    text: ""
                    placeholder: "Todo list title..."
                    onTextChanged: saveTimer.restart()
                }

                RippleButton {
                    implicitWidth: 40 * Appearance.effectiveScale
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainer
                    onClicked: root.deleteCurrent()
                    MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colError }
                    StyledToolTip { text: "Delete" }
                }
            }

            // Add task button
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: Appearance.colors.colSecondary
                onClicked: root.addTask()
                RowLayout {
                    anchors.centerIn: parent; spacing: 6 * Appearance.effectiveScale
                    MaterialSymbol { text: "add"; iconSize: 18 * Appearance.effectiveScale; color: Appearance.colors.colOnSecondary }
                    StyledText { text: "Add item"; color: Appearance.colors.colOnSecondary; font.weight: Font.Medium }
                }
            }

            // Task list
            ListView {
                id: taskListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4 * Appearance.effectiveScale
                model: {
                    const item = root._currentItem()
                    return item && item.type === "todo" ? item.tasks.slice() : []
                }
                clip: true

                delegate: Item {
                    id: taskDelegate
                    required property var modelData
                    required property int index
                    width: taskListView.width
                    height: _editingDeadline
                        ? _mainRow.height + _dlEditor.height + 24 * Appearance.effectiveScale
                        : _mainRow.height + 8 * Appearance.effectiveScale

                    property bool _editingDeadline: Boolean(modelData && modelData._editingDeadline)

                    on_EditingDeadlineChanged: {
                        if (modelData) modelData._editingDeadline = _editingDeadline
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.small
                        color: Appearance.m3colors.m3surfaceContainer

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 4 * Appearance.effectiveScale
                            spacing: 4 * Appearance.effectiveScale

                            // Main row
                            RowLayout {
                                id: _mainRow
                                Layout.fillWidth: true
                                spacing: 8 * Appearance.effectiveScale

                                // Checkbox
                                RippleButton {
                                    implicitWidth: 28 * Appearance.effectiveScale
                                    implicitHeight: 28 * Appearance.effectiveScale
                                    buttonRadius: 14 * Appearance.effectiveScale
                                    colBackground: modelData.done
                                        ? Appearance.colors.colPrimary
                                        : Appearance.m3colors.m3surfaceContainerHigh
                                    onClicked: root.toggleTask(modelData.id)
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: modelData.done ? "check" : ""
                                        iconSize: 18 * Appearance.effectiveScale
                                        color: Appearance.colors.colOnPrimary
                                    }
                                }

                                // Content input
                                StyledTextInput {
                                    Layout.fillWidth: true
                                    implicitHeight: 32 * Appearance.effectiveScale
                                    inputRadius: Appearance.rounding.small / Appearance.effectiveScale
                                    backgroundColor: "transparent"
                                    text: modelData.content
                                    placeholder: "Task..."
                                    font.strikeout: modelData.done
                                    opacity: modelData.done ? 0.5 : 1.0
                                    onTextChanged: {
                                        taskDebounceTimer.restart()
                                        root._pendingTaskId = modelData.id
                                        root._pendingTaskContent = text
                                    }
                                }

                                // Deadline badge (when set)
                                RippleButton {
                                    implicitWidth: dlText.implicitWidth + 16 * Appearance.effectiveScale
                                    implicitHeight: 28 * Appearance.effectiveScale
                                    buttonRadius: 14 * Appearance.effectiveScale
                                    visible: modelData.deadline !== null && modelData.deadline !== ""
                                    colBackground: root._isDeadlineOverdue(modelData.deadline, modelData.deadlineTime)
                                        ? Appearance.colors.colErrorContainer
                                        : (root._isDeadlineNear(modelData.deadline)
                                            ? Appearance.m3colors.m3tertiaryContainer
                                            : Appearance.m3colors.m3surfaceContainerHigh)
                                    onClicked: {
                                        modelData._tmpDate = modelData.deadline || root._defaultDeadlineDate()
                                        modelData._tmpTime = modelData.deadlineTime || root._defaultDeadlineTime()
                                        modelData._editingDeadline = true
                                        taskDelegate._editingDeadline = true
                                    }
                                    StyledText {
                                        id: dlText
                                        anchors.centerIn: parent
                                        text: root._formatDeadline(modelData.deadline, modelData.deadlineTime)
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: root._isDeadlineOverdue(modelData.deadline, modelData.deadlineTime)
                                            ? Appearance.colors.colOnErrorContainer
                                            : (root._isDeadlineNear(modelData.deadline)
                                                ? Appearance.colors.colOnTertiaryContainer
                                                : Appearance.colors.colOnLayer1)
                                    }
                                }

                                // Add deadline button (when none set)
                                RippleButton {
                                    implicitWidth: 28 * Appearance.effectiveScale
                                    implicitHeight: 28 * Appearance.effectiveScale
                                    buttonRadius: 14 * Appearance.effectiveScale
                                    visible: modelData.deadline === null || modelData.deadline === ""
                                    colBackground: "transparent"
                                    onClicked: {
                                        modelData._tmpDate = root._defaultDeadlineDate()
                                        modelData._tmpTime = root._defaultDeadlineTime()
                                        modelData._editingDeadline = true
                                        taskDelegate._editingDeadline = true
                                    }
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "calendar_today"
                                        iconSize: 16 * Appearance.effectiveScale
                                        color: Appearance.colors.colSubtext
                                    }
                                    StyledToolTip { text: "Add deadline" }
                                }

                                // Delete task
                                RippleButton {
                                    implicitWidth: 28 * Appearance.effectiveScale
                                    implicitHeight: 28 * Appearance.effectiveScale
                                    buttonRadius: 14 * Appearance.effectiveScale
                                    colBackground: "transparent"
                                    onClicked: root.removeTask(modelData.id)
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        iconSize: 16 * Appearance.effectiveScale
                                        color: Appearance.colors.colError
                                    }
                                }
                            }

                            // Deadline editor row
                            RowLayout {
                                id: _dlEditor
                                Layout.fillWidth: true
                                Layout.leftMargin: 36 * Appearance.effectiveScale
                                spacing: 6 * Appearance.effectiveScale
                                visible: _editingDeadline

                                // Date field
                                RippleButton {
                                    Layout.fillWidth: true
                                    implicitHeight: 34 * Appearance.effectiveScale
                                    buttonRadius: Appearance.rounding.small
                                    colBackground: "transparent"
                                    colBackgroundHover: "transparent"
                                    colText: "transparent"
                                    onClicked: root.openTaskDatePicker(modelData.id, modelData._tmpDate || modelData.deadline)
                                    StyledText {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 6 * Appearance.effectiveScale
                                        text: root._displayDate(modelData._tmpDate || modelData.deadline || root._defaultDeadlineDate())
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer1
                                        horizontalAlignment: Text.AlignLeft
                                    }
                                }

                                // Time field
                                RippleButton {
                                    Layout.fillWidth: true
                                    implicitHeight: 34 * Appearance.effectiveScale
                                    buttonRadius: Appearance.rounding.small
                                    colBackground: "transparent"
                                    colBackgroundHover: "transparent"
                                    colText: "transparent"
                                    onClicked: root.openTaskTimePicker(modelData.id, modelData._tmpTime || modelData.deadlineTime)
                                    StyledText {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.rightMargin: 6 * Appearance.effectiveScale
                                        text: root._displayTime(modelData._tmpTime || modelData.deadlineTime || root._defaultDeadlineTime())
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer1
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                // Apply
                                RippleButton {
                                    implicitWidth: 30 * Appearance.effectiveScale
                                    implicitHeight: 30 * Appearance.effectiveScale
                                    buttonRadius: 15 * Appearance.effectiveScale
                                    colBackground: Appearance.colors.colPrimary
                                    onClicked: {
                                        root.setTaskDeadline(modelData.id, modelData._tmpDate || modelData.deadline, modelData._tmpTime || modelData.deadlineTime)
                                        modelData._editingDeadline = false
                                        taskDelegate._editingDeadline = false
                                    }
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "check"
                                        iconSize: 16 * Appearance.effectiveScale
                                        color: Appearance.colors.colOnPrimary
                                    }
                                }

                                // Delete deadline
                                RippleButton {
                                    implicitWidth: 30 * Appearance.effectiveScale
                                    implicitHeight: 30 * Appearance.effectiveScale
                                    buttonRadius: 15 * Appearance.effectiveScale
                                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                                    visible: modelData.deadline !== null && modelData.deadline !== ""
                                    onClicked: {
                                        root.setTaskDeadline(modelData.id, "", "")
                                        taskDelegate._editingDeadline = false
                                    }
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "delete"
                                        iconSize: 16 * Appearance.effectiveScale
                                        color: Appearance.colors.colError
                                    }
                                }

                                // Cancel
                                RippleButton {
                                    implicitWidth: 30 * Appearance.effectiveScale
                                    implicitHeight: 30 * Appearance.effectiveScale
                                    buttonRadius: 15 * Appearance.effectiveScale
                                    colBackground: "transparent"
                                    onClicked: taskDelegate._editingDeadline = false
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "undo"
                                        iconSize: 16 * Appearance.effectiveScale
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }
                        }
                    }
                }

                ScrollBar.vertical: StyledScrollBar {}
            }
        }
    }
}
