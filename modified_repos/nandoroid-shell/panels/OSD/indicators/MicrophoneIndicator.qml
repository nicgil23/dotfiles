import "../../../services"
import QtQuick
import "../../widgets"
import ".."

OsdValueIndicator {
    id: osdValues
    value: Audio.microphoneVolume
    icon: Audio.microphoneMuted ? "mic_off" : "mic"
    rotateIcon: true
    scaleIcon: true
    name: "Microphone"
    shape: "Squircle"
}
