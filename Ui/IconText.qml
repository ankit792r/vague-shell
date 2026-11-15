import QtQuick
import "../Commons"

Text {
    property int size: Style.font.body

    color: Color.text
    font.family: Style.font.family
    font.pixelSize: size
}
