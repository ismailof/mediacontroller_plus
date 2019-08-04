import QtQuick 2.4
import org.kde.plasma.core 2.0 as PlasmaCore


Item {

    property alias artSize: albumArt.sourceSize

    PlasmaCore.IconItem {
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        height: Math.min(parent.height, Math.max(units.iconSizes.large, Math.round(parent.height / 2)))
        width: height

        source: mpris2Source.currentData["Desktop Icon Name"]
        visible: !albumArt.visible

        usesPlasmaTheme: false
    }

    Image {
        id: albumArt
        anchors {
            fill: parent
        }

        source: root.albumArt
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(height, height)
        visible: !!root.track && status === Image.Ready
    }
}
