import QtQuick
import "../Commons"
import "../Commons" as Commons

Rectangle {
    id: root

    property bool active: false
    property string label: ""

    signal activated()

    width: ListView.view ? ListView.view.width : (parent ? parent.width : 0)
    height: 32
    color: active || mouse.containsMouse ? Commons.Color.surface : "transparent"

    IconText {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 8
        text: root.label
        size: Style.font.body
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.activated()
    }
}
