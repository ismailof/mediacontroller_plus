
import QtQuick 2.4
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3


Row {
    id: playerControls

    property bool enabled: root.canControl
    property bool compactView: false  // In compactView diabled controls are hidden
    property int controlSize: compactView? units.iconSizes.medium: units.iconSizes.large
    
    spacing: compactView? 0 : units.largeSpacing
    
    PlasmaComponents3.ToolButton {
        anchors.verticalCenter: parent.verticalCenter
        width: controlSize
        height: width
        enabled: playerControls.enabled && root.canGoPrevious
        visible: compactView? enabled : true
        icon.name: LayoutMirroring.enabled ? "media-skip-forward" : "media-skip-backward"
        onClicked: {
            //root.position = 0    // Let the media start from beginning. Bug 362473
            root.action_previous()
        }
    }

    PlasmaComponents3.ToolButton {
        width: Math.round(controlSize * 1.5)
        height: width
        enabled: root.state == "playing" ? root.canPause : root.canPlay
        icon.name: root.state == "playing" ? "media-playback-pause" : "media-playback-start"
        onClicked: root.togglePlaying()
    }

    PlasmaComponents3.ToolButton {
        anchors.verticalCenter: parent.verticalCenter
        width: controlSize
        height: width
        enabled: playerControls.enabled && root.canGoNext
        visible: compactView? enabled : true
        icon.name: LayoutMirroring.enabled ? "media-skip-backward" : "media-skip-forward"
        onClicked: {
            //root.position = 0    // Let the media start from beginning. Bug 362473
            root.action_next()
        }
    }
}
