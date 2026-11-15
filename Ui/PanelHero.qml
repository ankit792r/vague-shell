import QtQuick
import "../Commons"

// Large icon, title, subtitle, and an optional control on the right.
// The row is parented after it exists, then anchored. Anchors set on an
// item that has no parent are ignored, which left the title with no width
// and the switch on top of the icon.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property real iconOpacity: 1

    default property alias trailing: slot.data

    width: parent ? parent.width : 0
    height: 42

    property Item layout: Item {
        IconText {
            id: heroIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            size: Style.font.displayLarge
            opacity: root.iconOpacity
        }

        Item {
            id: slot
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: Math.max(childrenRect.height, 1)
        }

        Column {
            anchors.left: heroIcon.right
            anchors.leftMargin: 14
            anchors.right: slot.left
            anchors.rightMargin: slot.width > 0 ? 12 : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            IconText {
                width: parent.width
                text: root.title
                size: Style.font.heading
                font.bold: true
                elide: Text.ElideRight
            }

            SectionLabel {
                width: parent.width
                text: root.subtitle
                elide: Text.ElideRight
                visible: text !== ""
            }
        }
    }

    Component.onCompleted: {
        layout.parent = root
        layout.anchors.fill = root
    }
}
