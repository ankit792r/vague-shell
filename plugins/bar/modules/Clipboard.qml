import QtQuick
import Quickshell
import "../../../Commons"
import "../../../Ui"

Item {
    id: root

    implicitWidth: icon.width
    implicitHeight: Style.bar.height

    BarButton {
        id: icon
        icon: "󰅇"
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "clipboard", "toggle"])
    }
}
