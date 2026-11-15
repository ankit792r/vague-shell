import QtQuick
import "../Commons"

Item {
    id: root

    property string label: ""
    property string value: ""

    width: parent ? parent.width : 0
    height: 18

    SectionLabel {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
    }

    IconText {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        size: Style.font.body
    }
}
