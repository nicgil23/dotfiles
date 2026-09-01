#!/usr/bin/env python3
import sys
import os
import subprocess
import json
import time
import urllib.parse

def main():
    if len(sys.argv) < 3:
        print(json.dumps({"success": False, "sent": 0, "total": 0, "error": "missing_args"}))
        sys.exit(1)

    dev = sys.argv[1]
    files = json.loads(sys.argv[2])
    count = len(files)

    if not dev:
        print(json.dumps({"success": False, "sent": 0, "total": count, "error": "no_device"}))
        sys.exit(0)

    err_count = 0
    for f in files:
        if f.startswith("file://"):
            f = f[7:]
        f = urllib.parse.unquote(f)
        r = subprocess.run(
            ["kdeconnect-cli", "--device", dev, "--share", f],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        if r.returncode != 0:
            err_count += 1
        time.sleep(0.2)

    label = "1 archivo" if count == 1 else f"{count} archivos"

    if err_count == count:
        print(json.dumps({"success": False, "sent": 0, "total": count, "error": "all_failed"}))
    elif err_count > 0:
        print(json.dumps({"success": False, "sent": count - err_count, "total": count, "error": "partial_failed"}))
    else:
        print(json.dumps({"success": True, "sent": count, "total": count}))
        cmd = f'notify-send -i kdeconnect -a "KDE Connect" -u normal "KDE Connect" "Enviados {label} al móvil correctamente"'
        subprocess.run(cmd, shell=True)

if __name__ == "__main__":
    main()
