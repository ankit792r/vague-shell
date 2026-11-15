import QtQuick
import "../Commons"

Rectangle {
    id: root

    property bool checked: false

    signal toggled()

    width: 36
    height: 20
    color: checked ? Color.success : Color.border

    Rectangle {
        width: 16
        height: 16
        color: Color.background
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 2 : 2
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggled()
    }
}
