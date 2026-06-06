pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import QtQuick.Controls
import Quickshell
import "../../../core"
import "../../../core/functions" as Functions
import "../../../services"

Singleton {
    id: root

    enum Action {
        Copy,
        Edit,
        Search,
        CharRecognition,
        Record,
        RecordWithSound,
        RecordFullscreenWithSound,
        QRCode
    }

    property string imageSearchEngineBaseUrl: (Config.ready && Config.options?.search?.imageSearch?.imageSearchEngineBaseUrl) ? Config.options.search.imageSearch.imageSearchEngineBaseUrl : "https://lens.google.com/uploadbyurl?url="
    property string fileUploadApiEndpoint: "https://uguu.se/upload"

    function getCommand(x, y, width, height, screenshotPath, action, targetPath = "") {
        // Set command for action
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);
        
        const shellEscape = Functions.StringUtils.shellSingleQuoteEscape;
        
        const isCropping = (rw > 0 && rh > 0);
        const cropBase = isCropping
            ? `magick ${shellEscape(screenshotPath)} -crop ${rw}x${rh}+${rx}+${ry}`
            : "";
        const cropToStdout = isCropping ? `${cropBase} -` : `cat ${shellEscape(screenshotPath)}`;
        const cropInPlace = isCropping ? `${cropBase} '${shellEscape(screenshotPath)}'` : "true";
        
        const isTemp = screenshotPath.includes("/tmp/") || screenshotPath.includes(Directories.screenshotTemp);
        const cleanup = isTemp ? `rm '${shellEscape(screenshotPath)}'` : "true";
        const slurpRegion = `${rx},${ry} ${rw}x${rh}`;
        
        const uploadAndGetUrl = (filePath) => {
            return `curl -sF files[]=@'${shellEscape(filePath)}' ${root.fileUploadApiEndpoint} | jq -r '.files[0].url'`
        }
        
        const useSatty = (Config.ready && Config.options.regionSelector && Config.options.regionSelector.annotation) 
            ? Config.options.regionSelector.annotation.useSatty 
            : false;
        const annotationCommand = `${useSatty ? "satty" : "swappy"} -f -`;
        const recordScript = Quickshell.shellPath("scripts/videos/record.sh");
        
        const expandPath = (path) => path.replace(/^~/, Directories.home);
        const finalSaveDir = expandPath(Functions.FileUtils.trimFileProtocol((Config.ready && Config.options.screenshot) ? Config.options.screenshot.savePath : "~/Pictures/Screenshots"));
        const finalRecDir = expandPath(Functions.FileUtils.trimFileProtocol((Config.ready && Config.options.screenshot) ? Config.options.screenshot.recordPath : "~/Videos/Recordings"));

        let actualTargetPath = screenshotPath;
        let cmdArray = [];

        switch (action) {
            case ScreenshotAction.Action.Copy:
                const autoSave = (Config.ready && Config.options.screenshot) ? Config.options.screenshot.autoSave : true;
                const autoCopy = (Config.ready && Config.options.screenshot) ? Config.options.screenshot.autoCopy : true;
                
                if (!autoSave) {
                    // Just move to temp and conditionally auto-copy to clipboard
                    const copyCmd = autoCopy ? `${cropToStdout} | wl-copy && ` : "";
                    cmdArray = ["bash", "-c", `${copyCmd}${cropInPlace}`];
                    actualTargetPath = screenshotPath;
                } else {
                    const dateStr = Qt.formatDateTime(new Date(), "yyyy-MM-dd-HH-mm-ss");
                    actualTargetPath = targetPath !== "" ? targetPath : `${finalSaveDir}/Screenshot_${dateStr}.png`;
                    const teeCopy = autoCopy ? " | tee >(wl-copy)" : "";
                    cmdArray = [
                        "bash", "-c",
                        `mkdir -p '${shellEscape(finalSaveDir)}' && \
                        ${cropToStdout}${teeCopy} > '${shellEscape(actualTargetPath)}' && \
                        ${cleanup}`
                    ];
                }
                break;

            case ScreenshotAction.Action.Edit:
                cmdArray = ["bash", "-c", `${cropToStdout} | ${annotationCommand} && ${cleanup}`];
                break;
                
            case ScreenshotAction.Action.Search:
                const uploadCmd = uploadAndGetUrl(screenshotPath);
                cmdArray = ["bash", "-c", `${cropInPlace} && IMG_LINK=$(${uploadCmd}) && [ -n "$IMG_LINK" ] && xdg-open "${root.imageSearchEngineBaseUrl}$IMG_LINK" && ${cleanup}`];
                break;
                
            case ScreenshotAction.Action.CharRecognition:
                cmdArray = ["bash", "-c", `${cropInPlace} && tesseract '${shellEscape(screenshotPath)}' stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\n' '+' | sed 's/\\+$/\\n/') | wl-copy && ${cleanup}`];
                break;
                
            case ScreenshotAction.Action.Record:
                cmdArray = ["bash", "-c", `'${recordScript}' --region '${slurpRegion}' --path '${shellEscape(finalRecDir)}'`];
                break;
                
            case ScreenshotAction.Action.RecordWithSound:
                cmdArray = ["bash", "-c", `'${recordScript}' --region '${slurpRegion}' --sound --path '${shellEscape(finalRecDir)}'`];
                break;
            
            case ScreenshotAction.Action.RecordFullscreenWithSound:
                cmdArray = ["bash", "-c", `'${recordScript}' --fullscreen --sound --path '${shellEscape(finalRecDir)}'`];
                break;

            case ScreenshotAction.Action.QRCode:
                cmdArray = ["bash", "-c", `${cropInPlace} && zbarimg --raw '${shellEscape(screenshotPath)}' | wl-copy && notify-send "QR Code" "Content copied to clipboard" && ${cleanup}`];
                break;
                
            default:
                cmdArray = [];
                break;
        }

        return {
            command: cmdArray,
            targetPath: actualTargetPath
        };
    }
}
