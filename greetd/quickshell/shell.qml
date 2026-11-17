import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd

ShellRoot {
    id: root

    readonly property color background: "#1e1e2e"
    readonly property color surface: "#313244"
    readonly property color border: "#45475a"
    readonly property color text: "#cdd6f4"
    readonly property color subtext: "#a6adc8"
    readonly property color muted: "#7f849c"
    readonly property color urgent: "#f38ba8"
    readonly property color scrim: "#11111b"
    readonly property string fontFamily: "Iosevka Nerd Font"

    readonly property var sessions: [
        { label: "niri", command: ["niri-session"] }
    ]

    property int sessionIndex: 0

    property var users: []
    property int userIndex: 0
    property bool userMenuOpen: false
    property string manualName: ""
    property string secret: ""

    property string notice: Greetd.available ? "" : "Greetd did not start this screen"
    property bool failure: !Greetd.available
    property bool hideSecret: true
    property bool awaitingResponse: false
    property bool creatingSession: false
    property string pendingSecret: ""

    readonly property bool idle: Greetd.state === GreetdState.Inactive && !creatingSession
    readonly property bool launching: Greetd.state === GreetdState.Launching
        || Greetd.state === GreetdState.Launched

    // The password lives in each screen's field; these reach every copy.
    signal secretCleared()
    signal secretFocused()

    function parseUsers(raw) {
        var out = []
        var lines = String(raw || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split(":")
            if (parts.length < 7) continue
            var uid = parseInt(parts[2], 10)
            if (isNaN(uid) || uid < 1000 || uid >= 60000) continue
            if (/(nologin|false)$/.test(parts[6])) continue
            var display = String(parts[4] || "").split(",")[0].trim()
            out.push({ name: parts[0], display: display || parts[0] })
        }
        return out
    }

    function selectedName() {
        if (users.length > 0) return users[Math.max(0, Math.min(userIndex, users.length - 1))].name
        return manualName.trim()
    }

    function stepUser(delta) {
        if (!idle || users.length === 0) return
        userIndex = (userIndex + delta + users.length) % users.length
    }

    function clearSecret() {
        secret = ""
        secretCleared()
    }

    function resetAuth() {
        pendingSecret = ""
        awaitingResponse = false
        creatingSession = false
        hideSecret = true
        if (Greetd.state !== GreetdState.Inactive
                && Greetd.state !== GreetdState.Launching
                && Greetd.state !== GreetdState.Launched)
            Greetd.cancelSession()
    }

    function submit() {
        userMenuOpen = false

        if (!Greetd.available) {
            notice = "Greetd did not start this screen"
            failure = true
            return
        }

        if (awaitingResponse) {
            var reply = secret
            if (reply === "" && hideSecret) return
            awaitingResponse = false
            clearSecret()
            Greetd.respond(reply)
            return
        }

        if (!idle) return

        var name = selectedName()
        if (name === "") {
            notice = "Choose a user"
            failure = true
            return
        }
        if (secret === "") {
            notice = "Enter your password"
            failure = true
            secretFocused()
            return
        }

        pendingSecret = secret
        clearSecret()
        creatingSession = true
        notice = "Checking"
        failure = false
        Greetd.createSession(name)
    }

    function power(command) {
        Quickshell.execDetached(["systemctl", command])
    }

    FileView {
        path: "/etc/passwd"
        printErrors: false
        onLoaded: {
            root.users = root.parseUsers(text())
            if (root.userIndex >= root.users.length) root.userIndex = 0
        }
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, isError, responseRequired, echoResponse) {
            root.notice = message
            root.failure = isError

            if (!responseRequired) return

            root.hideSecret = !echoResponse

            if (!echoResponse && root.pendingSecret !== "") {
                var reply = root.pendingSecret
                root.pendingSecret = ""
                Greetd.respond(reply)
                return
            }

            root.awaitingResponse = true
            root.clearSecret()
            root.secretFocused()
        }

        function onAuthFailure(message) {
            root.notice = message || "Wrong password"
            root.failure = true
            root.resetAuth()
            root.clearSecret()
            root.secretFocused()
        }

        function onReadyToLaunch() {
            root.notice = "Starting session"
            root.failure = false
            root.pendingSecret = ""
            root.awaitingResponse = false

            Greetd.launch(root.sessions[root.sessionIndex].command, [
                "XDG_SESSION_TYPE=wayland",
                "XDG_CURRENT_DESKTOP=niri"
            ])
        }

        function onError(message) {
            root.notice = message
            root.failure = true
            root.resetAuth()
            root.clearSecret()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData

            screen: modelData
            color: root.scrim
            focusable: true

            WlrLayershell.namespace: "greeter"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            SystemClock {
                id: clock
                precision: SystemClock.Seconds
            }

            Connections {
                target: root
                function onSecretCleared() { secretField.text = "" }
                function onSecretFocused() { secretField.forceActiveFocus() }
            }

            Component.onCompleted: Qt.callLater(function () {
                if (root.users.length === 0) manualField.forceActiveFocus()
                else secretField.forceActiveFocus()
            })

            MouseArea {
                anchors.fill: parent
                onClicked: root.userMenuOpen = false
            }

            Column {
                anchors.centerIn: parent
                spacing: 16
                width: 360

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: root.text
                    font.family: root.fontFamily
                    font.pixelSize: 72
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                    color: root.subtext
                    font.family: root.fontFamily
                    font.pixelSize: 16
                }

                // User selection
                Item {
                    id: userPicker

                    width: parent.width
                    height: 44
                    z: 10
                    activeFocusOnTab: true

                    Keys.onUpPressed: root.stepUser(-1)
                    Keys.onDownPressed: root.stepUser(1)
                    Keys.onSpacePressed: if (root.idle) root.userMenuOpen = !root.userMenuOpen
                    Keys.onEscapePressed: root.userMenuOpen = false
                    Keys.onReturnPressed: {
                        root.userMenuOpen = false
                        secretField.forceActiveFocus()
                    }
                    Keys.onEnterPressed: {
                        root.userMenuOpen = false
                        secretField.forceActiveFocus()
                    }
                    Keys.onTabPressed: {
                        root.userMenuOpen = false
                        secretField.forceActiveFocus()
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: root.background
                        border.color: userPicker.activeFocus || manualField.activeFocus ? root.text : root.border
                        border.width: 2
                        opacity: root.idle ? 1 : 0.6

                        Text {
                            visible: root.users.length > 0
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.right: arrow.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.users.length > 0 ? root.users[root.userIndex].display : ""
                            color: root.text
                            font.family: root.fontFamily
                            font.pixelSize: 16
                            elide: Text.ElideRight
                        }

                        Text {
                            id: arrow
                            visible: root.users.length > 0
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.userMenuOpen ? "▴" : "▾"
                            color: root.muted
                            font.family: root.fontFamily
                            font.pixelSize: 16
                        }

                        MouseArea {
                            visible: root.users.length > 0
                            anchors.fill: parent
                            enabled: root.idle
                            onClicked: {
                                userPicker.forceActiveFocus()
                                root.userMenuOpen = !root.userMenuOpen
                            }
                        }

                        // No regular users found: type the name instead.
                        TextInput {
                            id: manualField
                            visible: root.users.length === 0
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.text
                            font.family: root.fontFamily
                            font.pixelSize: 16
                            selectByMouse: true
                            enabled: root.idle
                            onTextChanged: root.manualName = text
                            onAccepted: secretField.forceActiveFocus()
                        }

                        Text {
                            visible: root.users.length === 0 && manualField.text.length === 0
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Username"
                            color: root.muted
                            font.family: root.fontFamily
                            font.pixelSize: 16
                        }
                    }

                    Rectangle {
                        visible: root.userMenuOpen && root.users.length > 0
                        anchors.top: parent.bottom
                        anchors.topMargin: 4
                        width: parent.width
                        height: Math.min(root.users.length, 5) * 36 + 4
                        color: root.background
                        border.color: root.border
                        border.width: 2

                        ListView {
                            anchors.fill: parent
                            anchors.margins: 2
                            clip: true
                            model: root.users

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: ListView.view.width
                                height: 36
                                color: index === root.userIndex || optionMouse.containsMouse
                                    ? root.surface
                                    : "transparent"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.display === modelData.name
                                        ? modelData.name
                                        : modelData.display + "  " + modelData.name
                                    color: root.text
                                    font.family: root.fontFamily
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: optionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.userIndex = index
                                        root.userMenuOpen = false
                                        secretField.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }

                // Password / PAM response
                Rectangle {
                    width: parent.width
                    height: 44
                    color: root.background
                    border.color: root.failure ? root.urgent : (secretField.activeFocus ? root.text : root.border)
                    border.width: 2

                    TextInput {
                        id: secretField

                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.text
                        font.family: root.fontFamily
                        font.pixelSize: 16
                        echoMode: root.hideSecret ? TextInput.Password : TextInput.Normal
                        passwordCharacter: "•"
                        selectByMouse: true
                        enabled: !root.launching && (root.idle || root.awaitingResponse)

                        onTextChanged: {
                            root.secret = text
                            if (text.length > 0 && root.failure && root.idle) {
                                root.failure = false
                                root.notice = ""
                            }
                        }
                        onAccepted: root.submit()
                        onActiveFocusChanged: if (activeFocus) root.userMenuOpen = false

                        Keys.onEscapePressed: root.clearSecret()
                        Keys.onBacktabPressed: {
                            if (root.users.length > 0) userPicker.forceActiveFocus()
                            else manualField.forceActiveFocus()
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.creatingSession && !root.awaitingResponse
                            ? "Checking"
                            : (root.hideSecret ? "Password" : "Response")
                        color: root.muted
                        font.family: root.fontFamily
                        font.pixelSize: 16
                        visible: secretField.text.length === 0
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: root.notice
                    color: root.failure ? root.urgent : root.subtext
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    visible: text !== ""
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Rectangle {
                        width: 176
                        height: 36
                        color: sessionMouse.containsMouse ? root.surface : "transparent"
                        border.color: root.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.sessions[root.sessionIndex].label
                            color: root.text
                            font.family: root.fontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: sessionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.idle
                            onClicked: root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length
                        }
                    }

                    Rectangle {
                        width: 176
                        height: 36
                        color: loginMouse.containsMouse ? root.surface : "transparent"
                        border.color: root.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.awaitingResponse ? "Continue" : "Log in"
                            color: root.text
                            font.family: root.fontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: loginMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.submit()
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                spacing: 8

                Repeater {
                    model: [
                        { label: "Reboot", command: "reboot" },
                        { label: "Power off", command: "poweroff" }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: 110
                        height: 32
                        color: powerMouse.containsMouse ? root.surface : "transparent"
                        border.color: modelData.command === "poweroff" ? root.urgent : root.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: modelData.command === "poweroff" ? root.urgent : root.text
                            font.family: root.fontFamily
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.power(modelData.command)
                        }
                    }
                }
            }
        }
    }
}
