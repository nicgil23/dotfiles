import "../../core"
import "../../widgets"
import "../../services"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

/**
 * Dashboard Tab: Translator
 * Real-time translation using MyMemory API (free, no key needed).
 * Supports 20+ language pairs with searchable StyledComboBox pickers.
 */
Item {
    id: root

    property string sourceLang: "en"
    property string targetLang: "es"
    property string sourceText: ""
    property string translatedText: ""
    property bool loading: false

    // Map of display name → ISO code for MyMemory
    readonly property var languages: [
        { name: "Español",    code: "es" },
        { name: "English",    code: "en" },
        { name: "Français",   code: "fr" },
        { name: "Deutsch",    code: "de" },
        { name: "Italiano",   code: "it" },
        { name: "Português",  code: "pt" },
        { name: "Русский",    code: "ru" },
        { name: "中文",        code: "zh" },
        { name: "日本語",      code: "ja" },
        { name: "한국어",      code: "ko" },
        { name: "العربية",    code: "ar" },
        { name: "हिन्दी",    code: "hi" },
        { name: "Türkçe",    code: "tr" },
        { name: "Polski",     code: "pl" },
        { name: "Nederlands", code: "nl" },
        { name: "Català",     code: "ca" },
        { name: "Galego",     code: "gl" },
        { name: "Euskara",    code: "eu" },
        { name: "Українська", code: "uk" },
        { name: "Čeština",    code: "cs" },
        { name: "Suomi",      code: "fi" },
        { name: "Română",     code: "ro" },
        { name: "Svenska",    code: "sv" }
    ]

    readonly property var langNames: languages.map(l => l.name)

    function codeToName(code) {
        for (let l of languages) { if (l.code === code) return l.name }
        return code.toUpperCase()
    }
    function nameToCode(name) {
        for (let l of languages) { if (l.name === name) return l.code }
        return "en"
    }

    function swapLangs() {
        let tmp = sourceLang
        sourceLang = targetLang
        targetLang = tmp
        // Also swap displayed text
        let t = sourceArea.text
        sourceArea.text = root.translatedText
        root.sourceText = sourceArea.text
        root.translatedText = t
    }

    // Debounce translation
    Timer {
        id: translateTimer
        interval: 700
        repeat: false
        onTriggered: root.performTranslation()
    }

    function performTranslation() {
        if (!sourceText.trim()) { translatedText = ""; return }
        loading = true
        translateProc.running = true
    }

    Process {
        id: translateProc
        command: ["sh", "-c",
            `curl -s "https://api.mymemory.translated.net/get?q=${encodeURIComponent(root.sourceText)}&langpair=${root.sourceLang}|${root.targetLang}"`
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    if (data.responseData?.translatedText) {
                        root.translatedText = data.responseData.translatedText
                    } else {
                        root.translatedText = (data.responseStatus || "Error")
                    }
                } catch(e) {
                    root.translatedText = "Could not parse response"
                }
                root.loading = false
            }
        }
        onExited: (code) => { if (code !== 0) root.loading = false }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16 * Appearance.effectiveScale
        spacing: 12 * Appearance.effectiveScale

        // -- Language Picker Row -----------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale

            // Source language
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale
                StyledText {
                    text: "Desde"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
                StyledComboBox {
                    id: fromCombo
                    Layout.fillWidth: true
                    implicitHeight: 40 * Appearance.effectiveScale
                    model: root.langNames
                    text: root.codeToName(root.sourceLang)
                    searchable: true
                    placeholder: "Idioma origen..."
                    onAccepted: (val) => {
                        root.sourceLang = root.nameToCode(val)
                        root.translatedText = ""
                        if (root.sourceText.trim()) translateTimer.restart()
                    }
                }
            }

            // Swap button
            RippleButton {
                implicitWidth: 36 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: Appearance.colors.colLayer2
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 2 * Appearance.effectiveScale
                onClicked: root.swapLangs()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "swap_horiz"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colOnLayer1
                }
                StyledToolTip { text: "Intercambiar idiomas" }
            }

            // Target language
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale
                StyledText {
                    text: "Hasta"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
                StyledComboBox {
                    id: toCombo
                    Layout.fillWidth: true
                    implicitHeight: 40 * Appearance.effectiveScale
                    model: root.langNames
                    text: root.codeToName(root.targetLang)
                    searchable: true
                    placeholder: "Idioma destino..."
                    onAccepted: (val) => {
                        root.targetLang = root.nameToCode(val)
                        root.translatedText = ""
                        if (root.sourceText.trim()) translateTimer.restart()
                    }
                }
            }
        }

        // -- Source Text Input -------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainer
            border.color: sourceArea.activeFocus ? Appearance.colors.colPrimary : "transparent"
            border.width: 2 * Appearance.effectiveScale

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12 * Appearance.effectiveScale
                spacing: 6 * Appearance.effectiveScale

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: root.codeToName(root.sourceLang)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colPrimary
                    }
                    Item { Layout.fillWidth: true }
                    // Clear button
                    RippleButton {
                        implicitWidth: 24 * Appearance.effectiveScale
                        implicitHeight: 24 * Appearance.effectiveScale
                        buttonRadius: 12 * Appearance.effectiveScale
                        colBackground: "transparent"
                        visible: sourceArea.text !== ""
                        onClicked: { sourceArea.text = ""; root.sourceText = ""; root.translatedText = "" }
                        MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: sourceArea.implicitHeight
                    clip: true

                    TextEdit {
                        id: sourceArea
                        width: parent.width
                        height: Math.max(implicitHeight, parent.height)
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        wrapMode: TextEdit.Wrap
                        onTextChanged: {
                            root.sourceText = text
                            translateTimer.restart()
                        }

                        StyledText {
                            anchors.fill: parent
                            text: "Escribe aquí para traducir…"
                            color: Appearance.colors.colSubtext
                            visible: !sourceArea.text && !sourceArea.activeFocus
                            font.pixelSize: Appearance.font.pixelSize.normal
                            wrapMode: Text.Wrap
                        }
                    }
                    ScrollBar.vertical: StyledScrollBar {}
                }
            }
        }

        // -- Translated Output -------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12 * Appearance.effectiveScale
                spacing: 6 * Appearance.effectiveScale

                // Header with lang name + copy
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: root.codeToName(root.targetLang)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colPrimary
                    }
                    Item { Layout.fillWidth: true }

                    // Loading spinner (small)
                    Rectangle {
                        visible: root.loading
                        width: 16 * Appearance.effectiveScale; height: 16 * Appearance.effectiveScale
                        radius: 8 * Appearance.effectiveScale; color: "transparent"
                        Rectangle {
                            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                            width: 3 * Appearance.effectiveScale; height: 8 * Appearance.effectiveScale
                            radius: 1.5 * Appearance.effectiveScale; color: Appearance.colors.colPrimary
                            RotationAnimation on rotation { from: 0; to: 360; duration: 700; loops: Animation.Infinite; running: root.loading }
                        }
                    }

                    // Copy button
                    RippleButton {
                        implicitWidth: 28 * Appearance.effectiveScale; implicitHeight: 28 * Appearance.effectiveScale
                        buttonRadius: 14 * Appearance.effectiveScale; colBackground: "transparent"
                        visible: root.translatedText !== "" && !root.loading
                        onClicked: {
                            const proc = Qt.createQmlObject(
                                'import Quickshell.Io; Process { command: ["wl-copy"] }', root)
                            proc.stdin = root.translatedText
                            proc.running = true
                        }
                        MaterialSymbol { anchors.centerIn: parent; text: "content_copy"; iconSize: 16 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        StyledToolTip { text: "Copiar traducción" }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: resultText.implicitHeight
                    clip: true

                    StyledText {
                        id: resultText
                        width: parent.width
                        text: root.translatedText
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        wrapMode: Text.Wrap
                        opacity: root.loading ? 0.4 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        StyledText {
                            anchors.fill: parent
                            visible: !root.translatedText && !root.loading
                            text: "La traducción aparecerá aquí…"
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.normal
                            wrapMode: Text.Wrap
                        }
                    }
                    ScrollBar.vertical: StyledScrollBar {}
                }
            }
        }
    }
}
