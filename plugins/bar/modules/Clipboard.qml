import QtQuick
import Quickshell

Item {
    id: root

    implicitWidth: icon.width
    implicitHeight: 32

    Text {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(implicitWidth, 18)
        height: 32
        text: "󰅇"
        color: "#cdd6f4"
        font.family: "Iosevka Nerd Font"
        font.pixelSize: 16
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "clipboard", "toggle"])
    }
}
