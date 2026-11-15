pragma Singleton
import QtQuick

// Typography and bar size. Change fontFamily or fontBaseSize here and the
// rest of the shell follows. Sizes are the current ones at a 16px base.
QtObject {
    id: root

    property string fontFamily: "Iosevka Nerd Font"
    property int fontBaseSize: 16

    function fontPx(mult) {
        return Math.max(1, Math.round(fontBaseSize * mult))
    }

    readonly property QtObject font: QtObject {
        readonly property string family: root.fontFamily
        readonly property int caption: root.fontPx(0.6875)       // 11
        readonly property int bodySmall: root.fontPx(0.75)       // 12
        readonly property int body: root.fontPx(0.8125)          // 13
        readonly property int subtitle: root.fontPx(0.875)       // 14
        readonly property int title: root.fontPx(0.9375)         // 15
        readonly property int heading: root.fontPx(1)            // 16
        readonly property int icon: root.fontPx(1)               // 16
        readonly property int iconLarge: root.fontPx(1.125)      // 18
        readonly property int displaySmall: root.fontPx(1.25)    // 20
        readonly property int display: root.fontPx(1.5)          // 24
        readonly property int displayLarge: root.fontPx(1.75)    // 28
        readonly property int clock: root.fontPx(4.5)            // 72
    }

    readonly property QtObject bar: QtObject {
        readonly property int height: Math.max(32, root.fontBaseSize * 2)
    }
}
