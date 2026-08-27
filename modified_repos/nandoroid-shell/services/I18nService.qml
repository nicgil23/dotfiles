pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property var translations: ({})
    property var generatedTranslations: ({})
    property var availableLanguages: ["en_US"]
    property var availableGeneratedLanguages: []
    property var allAvailableLanguages: {
        const combined = new Set([...root.availableLanguages, ...root.availableGeneratedLanguages]);
        return Array.from(combined).sort();
    }
    property bool isScanning: scanLanguagesProcess.running
    property bool isLoading: false
    property string translationKeepSuffix: "/*keep*/"
    
    // Hardcoded for safety to ensure it points to the nandoroid translations dir
    property string translationsDir: Quickshell.shellPath("translations")
    property string generatedTranslationsDir: Directories.shellConfig + "/translations"

    property string languageCode: {
        var configLang = Config?.options?.language?.ui ?? "auto";

        if (configLang !== "auto")
            return configLang;

        return Qt.locale().name;
    }

    TranslationScanner {
        id: scanLanguagesProcess
        translationsDir: root.translationsDir
        onLanguagesScanned: (languages) => {
            root.availableLanguages = [...languages];
        }
    }

    TranslationScanner {
        id: scanGeneratedLanguagesProcess
        translationsDir: root.generatedTranslationsDir
        onLanguagesScanned: (languages) => {
            root.availableGeneratedLanguages = [...languages];
        }
    }

    onLanguageCodeChanged: updateTranslations()
    onAvailableGeneratedLanguagesChanged: updateTranslations()

    function updateTranslations() {
        if (!root.languageCode) return;
        translationFileView.reread();

        if (root.availableGeneratedLanguages && root.availableGeneratedLanguages.indexOf(root.languageCode) !== -1) {
            generatedTranslationFileView.reread();
        } else {
            root.generatedTranslations = ({});
            generatedTranslationFileView.path = "";
        }
    }

    TranslationReader {
        id: translationFileView
        translationsDir: root.translationsDir
        languageCode: root.languageCode
        onContentLoaded: (data) => {
            root.translations = data;
            root.isLoading = false;
        }
    }

    TranslationReader {
        id: generatedTranslationFileView
        translationsDir: root.generatedTranslationsDir
        languageCode: ""
        onContentLoaded: (data) => {
            root.generatedTranslations = data;
            root.isLoading = false;
        }
    }

    function tr(text) {
        // Special cases
        if (!text) return "";
        var key = text.toString();
        if (root.isLoading || (!root?.translations?.hasOwnProperty(key) && !root?.generatedTranslations?.hasOwnProperty(key)))
            return key;
        
        // Normal cases
        var translation = root.translations[key] || root.generatedTranslations[key] || key;
        
        if (typeof translation === 'string' && translation.endsWith(root.translationKeepSuffix)) {
            translation = translation.substring(0, translation.length - root.translationKeepSuffix.length).trim();
        }
        return translation;
    }

    component TranslationScanner: Process {
        id: translationScanner
        required property string translationsDir
        signal languagesScanned(var languages)

        command: ["find", translationScanner.translationsDir, "-name", "*.json", "-exec", "basename", "{}", ".json", ";"]
        running: true

        stdout: StdioCollector {
            id: languagesCollector
            onStreamFinished: {
                const output = languagesCollector.text;
                if (output.trim().length > 0) {
                    const files = output.trim().split('\n').map(f => f.trim()).filter(f => f.length > 0);
                    if (files.length > 0) {
                        translationScanner.languagesScanned(files);
                        return;
                    }
                }
                translationScanner.languagesScanned(["en_US", "id_ID"]);
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                translationScanner.languagesScanned(["en_US", "id_ID"]);
            }
        }
    }

    component TranslationReader: FileView {
        id: translationReader
        property string translationsDir: ""
        property string languageCode: ""
        signal contentLoaded(var data)

        function reread() {
            if (!translationsDir || !languageCode) {
                path = "";
                return;
            }
            var targetPath = `${translationsDir}/${languageCode}.json`;
            if (path !== targetPath) {
                path = targetPath;
            }
        }
        path: ""

        onLoaded: {
            var textContent = "";
            try {
                textContent = text();
                var jsonData = JSON.parse(textContent);
                translationReader.contentLoaded(jsonData);
            } catch (e) {
                console.log("[I18nService] Failed to load translations:", e);
                translationReader.contentLoaded({});
            }
        }
        onLoadFailed: error => {
            translationReader.contentLoaded({});
        }
    }
}
