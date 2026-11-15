import QtQuick
import Quickshell
import "plugins/bar"
import "plugins/clipboard"
import "plugins/lock"

ShellRoot {
    id: shell

    readonly property string defaultBarId: "shell.bar"
    property string activeBarId: defaultBarId

    Component {
        id: defaultBarComponent
        Bar {}
    }

    Loader {
        active: shell.activeBarId === shell.defaultBarId
        sourceComponent: defaultBarComponent
    }

    Clipboard {}
    Lock {}
}