import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Commons" as Commons

Item {
    id: root

    readonly property string path: (Quickshell.env("HOME") || "") + "/Downloads/arch.png"
    readonly property url source: Qt.resolvedUrl("file://" + path)

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            color: Commons.Color.background
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.namespace: "wallpaper"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Image {
            //     anchors.fill: parent
            //     source: root.source
            //     fillMode: Image.PreserveAspectCrop
            //     asynchronous: true
            //     cache: true
            // }
        }
    }
}