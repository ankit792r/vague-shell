import QtQuick
import Quickshell.Services.Notifications
import "../../Commons"
import "../../Commons" as Commons
import "../../Ui"

Rectangle {
    id: root

    property string appName: ""
    property string summary: ""
    property string body: ""
    property var urgency: NotificationUrgency.Normal
    property string icon: ""
    property double progress: -1
    property int count: 1
    property var actions: []

    signal dismissed()
    signal invoked(string identifier)
    signal hovered(bool inside)

    readonly property bool critical: urgency === NotificationUrgency.Critical
    readonly property bool low: urgency === NotificationUrgency.Low
    readonly property color ink: critical ? Commons.Color.urgent : (low ? Commons.Color.muted : Commons.Color.text)
    readonly property color edge: critical ? Commons.Color.urgent : (low ? Commons.Color.muted : Commons.Color.border)

    width: 480
    implicitHeight: column.implicitHeight + 16
    color: Commons.Color.background
    border.color: edge
    border.width: 2

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered(true)
        onExited: root.hovered(false)
        onClicked: root.dismissed()
    }

    Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 4

        Row {
            width: parent.width
            spacing: iconImage.visible ? 8 : 0

            Image {
                id: iconImage
                anchors.verticalCenter: parent.verticalCenter
                visible: status === Image.Ready
                width: visible ? 32 : 0
                height: visible ? 32 : 0
                source: root.icon
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                sourceSize: Qt.size(64, 64)
            }

            Column {
                width: parent.width - (iconImage.visible ? 40 : 0)
                spacing: 2

                IconText {
                    width: parent.width
                    text: root.appName
                    color: Commons.Color.muted
                    size: Style.font.caption
                    elide: Text.ElideRight
                    visible: root.appName !== ""
                }

                IconText {
                    width: parent.width
                    text: root.summary
                    color: root.ink
                    size: Style.font.subtitle
                    elide: Text.ElideRight
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: root.body
                    color: Commons.Color.subtext
                    font.family: Style.font.family
                    font.pixelSize: Style.font.body
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    visible: root.body !== ""
                }
            }
        }

        Rectangle {
            visible: root.progress >= 0
            width: parent.width
            height: 4
            color: Commons.Color.surface

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.progress))
                height: parent.height
                color: Commons.Color.subtext
            }
        }

        Row {
            visible: root.actions.length > 0
            width: parent.width
            spacing: 6

            Repeater {
                model: root.actions.slice(0, 3)

                delegate: Rectangle {
                    required property var modelData
                    width: Math.min(140, (parent.width - 12) / Math.max(1, Math.min(3, root.actions.length)))
                    height: 26
                    color: actionMouse.containsMouse ? Commons.Color.surface : "transparent"
                    border.color: root.edge
                    border.width: 1

                    IconText {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        text: modelData.text || "Open"
                        color: root.ink
                        size: Style.font.caption
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.invoked(modelData.identifier)
                    }
                }
            }
        }
    }

    IconText {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        text: root.count > 1 ? String(root.count) : ""
        color: Commons.Color.muted
        size: Style.font.caption
        visible: root.count > 1
    }
}
