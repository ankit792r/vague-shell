import QtQuick
import "../Commons"

// Value is 0 to 1. moved() reports the position under the pointer.
Item {
    id: root

    property real value: 0
    property color fill: Color.text
    property real fillOpacity: 1

    signal moved(real value)

    width: parent ? parent.width : 0
    height: 18

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        color: Color.surface

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            color: root.fill
            opacity: root.fillOpacity
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: function (mouse) { root.moved(Math.max(0, Math.min(1, mouse.x / width))) }
        onPositionChanged: function (mouse) {
            if (pressed) root.moved(Math.max(0, Math.min(1, mouse.x / width)))
        }
    }
}
