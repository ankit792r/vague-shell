import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

Item {
    id: root

    property bool lockRequested: false
    property bool authenticating: false
    property bool settling: false
    property string pendingPassword: ""
    property string failureMessage: ""
    property int failedAttempts: 0

    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME")
    readonly property string pamDir: {
        var path = Qt.resolvedUrl("./pam.d").toString()
        if (path.indexOf("file://") === 0) path = decodeURIComponent(path.substring(7))
        return path
    }

    function beginLock() {
        if (sessionLock.locked || sessionLock.secure) return true
        failureMessage = ""
        failedAttempts = 0
        pendingPassword = ""
        authenticating = false
        lockRequested = true
        sessionLock.locked = true
        return true
    }

    function finishUnlock() {
        lockRequested = false
        authenticating = false
        pendingPassword = ""
        failureMessage = ""
        failedAttempts = 0
        if (passwordPam.active) passwordPam.abort()
        sessionLock.locked = false
    }

    function fail(message) {
        if (settling || !lockRequested) return
        settling = true
        authenticating = false
        pendingPassword = ""
        failedAttempts += 1
        failureMessage = message || ("Wrong password  " + failedAttempts)
        if (passwordPam.active) passwordPam.abort()
        clearPassword()
        settling = false
    }

    function submit(value) {
        var password = String(value || "")
        if (!lockRequested || authenticating || password.length === 0) return
        pendingPassword = password
        failureMessage = ""
        authenticating = true
        if (!passwordPam.start()) fail("Could not start password check")
    }

    PamContext {
        id: passwordPam
        config: "lock"
        configDirectory: root.pamDir
        user: root.userName

        onResponseRequiredChanged: {
            if (responseRequired && root.authenticating) respond(root.pendingPassword)
        }

        onCompleted: function (result) {
            if (root.settling) return
            root.authenticating = false
            root.pendingPassword = ""
            if (result === PamResult.Success) root.finishUnlock()
            else root.fail()
        }

        onError: function () {
            if (!root.authenticating) return
            root.fail("Could not start password check")
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): string {
            root.beginLock()
            return "ok"
        }
        function isLocked(): string {
            return (root.lockRequested || sessionLock.locked || sessionLock.secure) ? "true" : "false"
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        onLockStateChanged: if (locked) Qt.callLater(function () { root.focusPassword() })

        WlSessionLockSurface {
            id: lockSurface
            color: "#11111b"

            SystemClock {
                id: clock
                precision: SystemClock.Seconds
            }

            Column {
                anchors.centerIn: parent
                spacing: 18
                width: 360

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: "#cdd6f4"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 64
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                    color: "#a6adc8"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 16
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.userName
                    color: "#7f849c"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 14
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 320
                    height: 44
                    color: "#1e1e2e"
                    border.color: root.failureMessage ? "#f38ba8" : "#45475a"
                    border.width: 2

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#cdd6f4"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 16
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        enabled: !root.authenticating
                        selectByMouse: true
                        onAccepted: root.submit(text)
                        onTextChanged: if (text.length > 0) root.failureMessage = ""

                        Component.onCompleted: {
                            root.focusPassword = function () { passwordInput.forceActiveFocus() }
                            root.clearPassword = function () { passwordInput.text = "" }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.authenticating ? "Checking" : "Password"
                        color: "#7f849c"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 16
                        visible: passwordInput.text.length === 0
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.failureMessage
                    color: "#f38ba8"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 13
                    visible: text !== ""
                }
            }
        }
    }

    function focusPassword() {}
    function clearPassword() {}
}
