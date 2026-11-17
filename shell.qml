import QtQuick
import Quickshell
import "plugins/bar"
import "plugins/clipboard"
import "services/idle"
import "services/notifications"
import "plugins/launcher"
import "plugins/lock"
import "plugins/wallpaper" 

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
    Idle {}
    Notifications {}
    Launcher {}
    Lock {}
    Wallpaper {}
}