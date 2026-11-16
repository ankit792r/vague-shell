import QtQuick
import "../Commons"
import "../Commons" as Commons

Text {
    property int size: Style.font.body

    color: Commons.Color.text
    font.family: Style.font.family
    font.pixelSize: size
}
