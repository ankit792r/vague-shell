import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Same timeouts as hypridle.conf. Lock uses the shell lock screen.
Item {
    id: root

    function run(command) {
        Quickshell.execDetached(command)
    }

    function lock() {
        root.run(["qs", "ipc", "call", "lock", "lock"])
    }

    function onIdle(monitor, idle, resume) {
        if (!monitor.ready) {
            monitor.ready = true
            if (!monitor.isIdle) return
        }
        if (monitor.isIdle) idle()
        else if (resume) resume()
    }

    IdleMonitor {
        id: dimmed
        property bool ready: false
        timeout: 150
        onIsIdleChanged: root.onIdle(dimmed, function () {
            root.run(["brightnessctl", "-s", "set", "10"])
            root.run(["brightnessctl", "-sd", "rgb:kbd_backlight", "set", "0"])
        }, function () {
            root.run(["brightnessctl", "-r"])
            root.run(["brightnessctl", "-rd", "rgb:kbd_backlight"])
        })
    }

    IdleMonitor {
        id: locked
        property bool ready: false
        timeout: 300
        onIsIdleChanged: root.onIdle(locked, root.lock)
    }

    IdleMonitor {
        id: monitors
        property bool ready: false
        timeout: 330
        onIsIdleChanged: root.onIdle(monitors, function () {
            root.run(["niri", "msg", "action", "power-off-monitors"])
        }, function () {
            root.run(["niri", "msg", "action", "power-on-monitors"])
        })
    }

    IdleMonitor {
        id: suspended
        property bool ready: false
        timeout: 600
        onIsIdleChanged: root.onIdle(suspended, function () {
            root.run(["systemctl", "suspend"])
        })
    }

    Process {
        id: sleepWatch
        command: ["dbus-monitor", "--system", "type=signal,interface=org.freedesktop.login1.Manager,member=PrepareForSleep"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                var text = String(line)
                if (text.indexOf("boolean true") >= 0) root.lock()
                else if (text.indexOf("boolean false") >= 0)
                    root.run(["niri", "msg", "action", "power-on-monitors"])
            }
        }
        onExited: sleepRestart.restart()
    }

    Timer {
        id: sleepRestart
        interval: 1000
        onTriggered: if (!sleepWatch.running) sleepWatch.running = true
    }
}
