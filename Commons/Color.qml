pragma Singleton
import QtQuick

// Palette for the shell. Surfaces read these roles instead of hex colors.
QtObject {
    readonly property color background: "#1e1e2e"
    readonly property color surface: "#313244"
    readonly property color border: "#45475a"
    readonly property color text: "#cdd6f4"
    readonly property color subtext: "#a6adc8"
    readonly property color muted: "#7f849c"
    readonly property color urgent: "#f38ba8"
    readonly property color success: "#a6e3a1"
    readonly property color warning: "#f9e2af"
    readonly property color scrim: "#11111b"
}
