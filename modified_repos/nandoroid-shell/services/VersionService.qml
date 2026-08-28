pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property string version: "1.5.X"
    property bool updateAvailable: false

    Process {
        id: verProc
        command: ["bash", "-c", `
            f="$HOME/.config/nandoroid/install_state.json"
            [ ! -f "$f" ] && { echo "1.5.X"; exit; }
            d=$(python3 -c "import json,sys; print(json.load(open('$f')).get('install_dir',''))" 2>/dev/null)
            [ -z "$d" ] && { echo "1.5.X"; exit; }
            v=$(git -C "$d" describe --tags --always 2>/dev/null)
            [ -n "$v" ] && [ "$v" != "unknown" ] && echo "$v" || echo "1.5.X"
        `]
        stdout: StdioCollector { id: verOut }
        running: true
        onExited: {
            const v = verOut.text.trim()
            if (v && v !== "unknown") root.version = v
            else root.version = "1.5.X"
        }
    }

    Process {
        id: updProc
        command: ["bash", "-c", `
            f="$HOME/.config/nandoroid/install_state.json"
            [ ! -f "$f" ] && { echo "up-to-date"; exit; }
            d=$(python3 -c "import json; print(json.load(open('$f')).get('install_dir',''))" 2>/dev/null)
            c=$(python3 -c "import json; print(json.load(open('$f')).get('channel','stable'))" 2>/dev/null)
            [ -z "$d" ] && { echo "up-to-date"; exit; }
            cd "$d" || { echo "up-to-date"; exit; }
            if [ "$c" = "stable" ]; then
                git fetch --tags >/dev/null 2>&1 || { echo "up-to-date"; exit; }
                LATEST=$(git describe --tags $(git rev-list --tags --max-count=1 2>/dev/null) 2>/dev/null)
                [ -z "$LATEST" ] && { echo "up-to-date"; exit; }
                TC=$(git rev-list -n 1 "$LATEST" 2>/dev/null)
                [ -n "$TC" ] && [ "$(git rev-parse HEAD)" != "$TC" ] && echo "available" || echo "up-to-date"
            else
                git fetch origin main >/dev/null 2>&1 || { echo "up-to-date"; exit; }
                REMOTE=$(git rev-parse origin/main 2>/dev/null)
                [ -n "$REMOTE" ] && [ "$(git rev-parse HEAD)" != "$REMOTE" ] && echo "available" || echo "up-to-date"
            fi
        `]
        stdout: StdioCollector { id: updOut }
        running: true
        onExited: root.updateAvailable = updOut.text.trim() === "available"
    }
}
