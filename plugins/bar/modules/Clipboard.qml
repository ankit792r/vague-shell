import QtQuick
import Quickshell
import "../../../Commons"

Item {
    id: root

    implicitWidth: icon.width
    implicitHeight: Style.bar.height

    Text {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(implicitWidth, 18)
        height: 32
        text: "󰅇"
        color: Color.text
        font.family: Style.font.family
        font.pixelSize: Style.font.heading
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "clipboard", "toggle"])
    }
}
