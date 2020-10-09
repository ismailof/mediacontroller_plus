/***************************************************************************
 *   Copyright 2020 Carson Black <uhhadd@gmail.com>                        *
 *   Copyright 2020 Ismael Asensio <ismailof@git.com>                      *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU Library General Public License as       *
 *   published by the Free Software Foundation; either version 2 of the    *
 *   License, or (at your option) any later version.                       *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU Library General Public License for more details.                  *
 *                                                                         *
 *   You should have received a copy of the GNU Library General Public     *
 *   License along with this program; if not, write to the                 *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQml 2.2
import QtQuick 2.8
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras


Item {
    id: compactRepresentation

    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property bool iconView: width < PlasmaCore.Units.gridUnit * 8
    readonly property bool minimalView: height < PlasmaCore.Units.gridUnit * 3

    Layout.preferredWidth: (plasmoid.configuration.minimumWidthUnits || 18) * PlasmaCore.Units.gridUnit
    Layout.maximumWidth: plasmoid.configuration.maximumWidthUnits * PlasmaCore.Units.gridUnit || undefined


    Item {
        id: miniProgressBar
        z: 0

        property double progress: Media.songLength > 0 ? root.displayPosition / Media.songLength : 0

        anchors.fill: parent
        visible: plasmoid.configuration.showProgressBar && !iconView

        Item {
            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
            }
            width: parent.width * miniProgressBar.progress
            clip: true

            PlasmaCore.FrameSvgItem {
                width: miniProgressBar.width
                height: miniProgressBar.height

                imagePath: "widgets/tasks"
                prefix: ["progress", "hover"]
            }
        }
    }

    Item {
        id: verticalCenterHelper
        anchors {
            left: compactRoot.left
            right: compactRoot.right
            verticalCenter: compactRoot.verticalCenter
            margins: 0
        }
        height: mainRow.implicitHeight
    }

    RowLayout {
        id: mainRow
        z: 100

        readonly property bool heightOverflow: trackInfo.implicitHeight > compactRoot.height

        spacing: PlasmaCore.Units.smallSpacing

        anchors {
            fill: heightOverflow ? verticalCenterHelper : parent
            margins: 0
        }

        AlbumArt {
            visible: !minimalView

            Layout.fillHeight: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.minimumWidth: height
            Layout.maximumWidth: (artSize[0] / artSize[1]) * height
            Layout.margins: PlasmaCore.Units.smallSpacing
        }

        ColumnLayout {
            id: trackInfo

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            PlasmaExtras.Heading {
                id: mainLabel
                Layout.fillWidth: true
                level: 4
                horizontalAlignment: Text.AlignLeft

                maximumLineCount: 1
                elide: Text.ElideRight
                text: {
                    if (!Media.currentTrack) {
                        return i18n("No media playing")
                    }
                    if (minimalView && Media.currentArtist) {
                        return i18nc("artist – track", "%1 – %2", Media.currentArtist, Media.currentTrack)
                    }
                    return Media.currentTrack
                }
                textFormat: Text.PlainText
            }

            PlasmaExtras.Heading {
                id: secondLabel
                Layout.fillWidth: true

                level: 5
                opacity: 0.6
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                textFormat: Text.PlainText
                visible: !minimalView

                text: {
                    if (!Media.currentAlbum) {
                        return Media.currentArtist
                    }
                    if (!Media.currentArtist) {
                        return Media.currentAlbum
                    }
                    return i18nc("artist / album", "%1 / %2", Media.currentArtist,  Media.currentAlbum)
                }
            }
        }

        PlayerControls {
            id: playerControls
            Layout.alignment: Qt.AlignCenter
            compactView: true
            controlSize: Math.max(PlasmaCore.Units.iconSizes.small,
                                  Math.min(parent.height, PlasmaCore.Units.iconSizes.large))
            hideDisabledControls: plasmoid.configuration.hideDisabledControls
        }

        visible: !iconView
    }

    PlasmaCore.IconItem {
        id: playerStatusIcon
        anchors.fill: parent
        source: {
            if (Media.state === "playing") {
                return "media-playback-playing"
            } else if (Media.state == "paused") {
                return "media-playback-paused"
            } else {
                return "media-playback-stopped"
            }
        }
        active: compactMouse.containsMouse
        visible: iconView
    }

    MouseArea {
        id: compactMouse

        anchors.fill: parent
        z: -1

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton

        onWheel: Media.adjustVolume((wheel.angleDelta.y / 120) * 0.03)

        onClicked: {
            switch (mouse.button) {
            case Qt.MiddleButton:
                Media.togglePlaying()
                break
            case Qt.BackButton:
                Media.perform(Media.previous)
                break
            case Qt.ForwardButton:
                Media.perform(Media.next)
                break
            default:
            /*  if (!iconView && mpris2Source.currentData.CanRaise) {
                    Media.perform(Media.raise)
                    break
                }
            */
                plasmoid.expanded = !plasmoid.expanded
            }
        }
    }

    DropArea {
        z: -10
        anchors.fill: parent
        keys: ["text/uri-list", "audio/*", "video/*"]

        onDropped: {
            console.log("***\n" + drop.text
                        + " - " + drop.keys
                        + "\n***")

            drop.accept()

            if (Media.noPlayers) {
                Qt.openUrlExternally(drop.text)
            } else {
                Media.openUri(drop.text)
            }
        }
    }
}
