import qs.services
import QtQuick
import qs.widgets
import ".." 

OsdValueIndicator {
    id: osdValues
    value: Audio.sink?.audio?.volume ?? 0
    icon: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
    rotateIcon: true
    scaleIcon: true
    name: "Volume"
    shape: "Cookie7Sided"
}
