
import QtQuick 2.4
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras


Column {
    id: trackInfo

    property alias textAlignment: song.horizontalAlignment
    property bool showAlbumLine: true

    
    function getAlbum() {
        var metadata = root.currentMetadata
        
        if (!metadata) {
            return ""
        }
        var xesamAlbum = metadata["xesam:album"]
        if (xesamAlbum) {
            return xesamAlbum
        }

        // if we play a local file without title and artist, show its containing folder instead
        if (metadata["xesam:title"] || root.artist) {
            return ""
        }

        var xesamUrl = (metadata["xesam:url"] || "").toString()
        if (xesamUrl.indexOf("file:///") !== 0) { // "!startsWith()"
            return ""
        }

        var urlParts = xesamUrl.split("/")
        if (urlParts.length < 3) {
            return ""
        }

        var lastFolderPath = urlParts[urlParts.length - 2] // last would be filename
        if (lastFolderPath) {
            return lastFolderPath
        }

        return ""
    }
    
    
    PlasmaExtras.Heading {
        id: song
        width: parent.width
        height: undefined
        level: 4
        horizontalAlignment: Text.AlignHCenter

        maximumLineCount: 1
        elide: Text.ElideRight
        text: {
            if (!root.track) {
                return i18n("No media playing")
            }
            return (showAlbumLine && root.artist) ? i18nc("artist – track", "%1 – %2", root.artist, root.track) : root.track
        }
        textFormat: Text.PlainText
    }

    PlasmaExtras.Heading {
        id: album
        width: parent.width
        height: undefined
        level: 5
        opacity: 0.6
        horizontalAlignment: textAlignment
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
        visible: text !== ""
        text: showAlbumLine ? getAlbum() : root.artist || ""
        textFormat: Text.PlainText
    }
}
