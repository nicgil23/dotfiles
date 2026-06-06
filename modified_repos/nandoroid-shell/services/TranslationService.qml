pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../core/functions" as Functions

/**
 * TranslationService.qml
 * Handles text translation using MyMemory API (free, no key needed).
 * Does not require external 'translate-shell' dependency.
 */
Singleton {
    id: root

    property string translatedText: ""
    property bool isTranslating: translateProc.running
    property var availableLanguages: ["auto", "id", "en", "ja", "zh", "ko", "fr", "de", "es", "it", "ru", "pt", "ar", "hi", "tr", "pl", "nl", "ca", "gl", "eu", "uk", "cs", "fi", "ro", "sv"]

    function translate(text, source, target) {
        const cleanText = (text || "").trim();
        if (cleanText.length === 0) {
            root.translatedText = "";
            return;
        }
        
        if (translateProc.running) translateProc.terminate();

        const s = (source === "auto" || !source) ? "Autodetect" : source;
        const t = target || "en";
        const langPair = `${s}|${t}`;

        const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(cleanText)}&langpair=${encodeURIComponent(langPair)}`;

        translateProc.command = ["curl", "-s", url];
        translateProc.running = true;
    }

    Process {
        id: translateProc
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim();
                if (output.length > 0) {
                    try {
                        const data = JSON.parse(output);
                        if (data.responseData && data.responseData.translatedText) {
                            root.translatedText = data.responseData.translatedText;
                        } else {
                            root.translatedText = data.responseStatus || "Error";
                        }
                    } catch(e) {
                        root.translatedText = "Could not parse response";
                        console.error("[TranslationService] JSON parse error:", e);
                    }
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.error("[TranslationService] stderr:", this.text.trim());
                }
            }
        }
    }
}
