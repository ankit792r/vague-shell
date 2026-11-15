import QtQuick
import "../Commons"

// Icon and optional label used by bar modules. Clicks, the right button,
// the middle button, and the wheel are signals the module handles.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property int labelSize: Style.font.heading
    property int labelMaxWidth: 0
    property bool dimmed: false

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal wheeled(int delta)

    implicitWidth: row.implicitWidth
    implicitHeight: Style.bar.height
    opacity: dimmed ? 0.5 : 1

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.icon !== "" && root.label !== "" ? 6 : 0

        IconText {
            visible: root.icon !== ""
            width: visible ? Math.max(implicitWidth, 18) : 0
            height: Style.bar.height
            text: root.icon
            size: Style.font.heading
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        IconText {
            visible: root.label !== ""
            width: root.labelMaxWidth > 0 ? Math.min(implicitWidth, root.labelMaxWidth) : implicitWidth
            height: Style.bar.height
            text: root.label
            size: root.labelSize
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) root.rightClicked()
            else if (mouse.button === Qt.MiddleButton) root.middleClicked()
            else root.clicked()
        }
        onWheel: function (wheel) { root.wheeled(wheel.angleDelta.y) }
    }
}
