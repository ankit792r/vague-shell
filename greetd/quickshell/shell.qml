
import QtQuick
import Quickshell
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

    property string notice: Greetd.available
        ? ""
        : "Greetd did not start this screen"

    property bool failure: !Greetd.available
    property bool hideSecret: true
    property bool awaitingResponse: false
    property bool creatingSession: false
    property string pendingSecret: ""

    function submit() {
        if (!Greetd.available)
            return

        failure = false

        // Answer an authentication prompt first.
        if (awaitingResponse) {
            var reply = secretField.text

            if (reply === "")
                return

            secretField.text = ""
            awaitingResponse = false

            Greetd.respond(reply)
            return
        }

        // Prevent duplicate session creation.
        if (creatingSession)
            return

        // Start a new authentication session.
        if (Greetd.state === GreetdState.Inactive) {
            var name = usernameField.text.trim()
            var password = secretField.text

            if (name === "" || password === "")
                return

            pendingSecret = password
            secretField.text = ""
            creatingSession = true

            Greetd.createSession(name)
        }
    }

    function power(command) {
        Quickshell.execDetached(["systemctl", command])
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, isError, responseRequired, echoResponse) {
            root.notice = message
            root.failure = isError

            if (!responseRequired)
                return

            root.hideSecret = !echoResponse

            // Automatically answer the initial hidden password prompt.
            if (!echoResponse && root.pendingSecret !== "") {
                var reply = root.pendingSecret
                root.pendingSecret = ""

                Greetd.respond(reply)
                return
            }

            // Handle any additional PAM prompt.
            root.awaitingResponse = true
            secretField.text = ""
            secretField.forceActiveFocus()
        }

        function onAuthFailure(message) {
            root.notice = message
            root.failure = true

            root.pendingSecret = ""
            root.awaitingResponse = false
            root.creatingSession = false

            secretField.text = ""
            secretField.forceActiveFocus()
        }

        function onReadyToLaunch() {
            root.notice = "Starting session"
            root.failure = false

            root.pendingSecret = ""
            root.awaitingResponse = false
            root.creatingSession = false

            Greetd.launch(
                root.sessions[root.sessionIndex].command,
                [
                    "XDG_SESSION_TYPE=wayland",
                    "XDG_CURRENT_DESKTOP=niri"
                ]
            )
        }

        function onError(message) {
            root.notice = message
            root.failure = true

            root.pendingSecret = ""
            root.awaitingResponse = false
            root.creatingSession = false
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

                // Username
                Rectangle {
                    width: parent.width
                    height: 44

                    color: root.background
                    border.color: root.border
                    border.width: 2

                    TextInput {
                        id: usernameField

                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14

                        verticalAlignment: TextInput.AlignVCenter

                        color: root.text
                        font.family: root.fontFamily
                        font.pixelSize: 16

                        focus: true
                        selectByMouse: true

                        enabled: Greetd.state === GreetdState.Inactive
                            && !root.creatingSession

                        onAccepted: secretField.forceActiveFocus()
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Username"
                        color: root.muted

                        font.family: root.fontFamily
                        font.pixelSize: 16

                        visible: usernameField.text.length === 0
                    }
                }

                // Password / PAM response
                Rectangle {
                    width: parent.width
                    height: 44

                    color: root.background

                    border.color: root.failure
                        ? root.urgent
                        : root.border

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

                        echoMode: root.hideSecret
                            ? TextInput.Password
                            : TextInput.Normal

                        passwordCharacter: "•"

                        selectByMouse: true

                        enabled: Greetd.state !== GreetdState.Launching
                            && Greetd.state !== GreetdState.Launched

                        onAccepted: root.submit()
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter

                        text: root.hideSecret
                            ? "Password"
                            : "Response"

                        color: root.muted

                        font.family: root.fontFamily
                        font.pixelSize: 16

                        visible: secretField.text.length === 0
                    }
                }

                // Authentication status
                Text {
                    width: parent.width

                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap

                    text: root.notice

                    color: root.failure
                        ? root.urgent
                        : root.subtext

                    font.family: root.fontFamily
                    font.pixelSize: 13

                    visible: text !== ""
                }

                // Session and login buttons
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Rectangle {
                        width: 176
                        height: 36

                        color: sessionMouse.containsMouse
                            ? root.surface
                            : "transparent"

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

                            enabled: Greetd.state === GreetdState.Inactive
                                && !root.creatingSession

                            onClicked: {
                                root.sessionIndex =
                                    (root.sessionIndex + 1)
                                    % root.sessions.length
                            }
                        }
                    }

                    Rectangle {
                        width: 176
                        height: 36

                        color: loginMouse.containsMouse
                            ? root.surface
                            : "transparent"

                        border.color: root.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent

                            text: root.awaitingResponse
                                ? "Continue"
                                : "Log in"

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

            // Power controls
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

                        color: powerMouse.containsMouse
                            ? root.surface
                            : "transparent"

                        border.color: modelData.command === "poweroff"
                            ? root.urgent
                            : root.border

                        border.width: 1

                        Text {
                            anchors.centerIn: parent

                            text: modelData.label

                            color: modelData.command === "poweroff"
                                ? root.urgent
                                : root.text

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
