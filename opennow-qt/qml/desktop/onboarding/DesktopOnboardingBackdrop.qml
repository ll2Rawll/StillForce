import QtQuick
import OpenNOW

Rectangle {
    color: Theme.shell
    Image {
        anchors.fill: parent
        source: "qrc:/qt/qml/OpenNOW/res/brand/stillforce-satin.png"
        sourceSize: Qt.size(1280, 720)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: Theme.lightMode ? 0.14 : 0.95
    }
}
