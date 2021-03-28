/***************************************************************************
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
import QtQuick 2.4
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore


Item {
    id: compactRoot

    Layout.fillWidth: plasmoid.configuration.showTrackInfo
    Layout.fillHeight: true

    readonly property bool iconView: (width < PlasmaCore.Units.gridUnit * 4) ||
                                     (!plasmoid.configuration.showAlbumArt &&
                                      !plasmoid.configuration.showTrackInfo &&
                                      !plasmoid.configuration.showPlaybackControls)

    Layout.minimumWidth: (iconView ? 1 : 5) * PlasmaCore.Units.gridUnit
    Layout.preferredWidth: plasmoid.configuration.showTrackInfo ? (plasmoid.configuration.minimumWidthUnits || 18) * PlasmaCore.Units.gridUnit
                                                                : mainRow.implicitWidth
    Layout.maximumWidth: plasmoid.configuration.maximumWidthUnits * PlasmaCore.Units.gridUnit || undefined


    Item {
        id: miniProgressBar
        z: 0

        anchors.fill: parent
        visible: plasmoid.configuration.showProgressBar && !iconView

        Item {
            id: progress
            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
            }

            width: parent.width * root.position / root.length
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
            id: albumArt
            visible: plasmoid.configuration.showAlbumArt
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: height
            Layout.preferredWidth: aspectRatio * height
        }

        TrackInfo {
            id: trackInfo
            visible: plasmoid.configuration.showTrackInfo
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            textAlignment: Text.AlignLeft
            oneLiner: height < PlasmaCore.Units.gridUnit * 1.5 && !iconView
            spacing: 0
        }

        PlayerControls {
            id: playerControls
            visible: plasmoid.configuration.showPlaybackControls
            Layout.fillWidth: !trackInfo.visible
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            compactView: true
            controlSize: Math.max(PlasmaCore.Units.iconSizes.small,
                                  trackInfo.visible ? Math.min(parent.height, PlasmaCore.Units.iconSizes.large)
                                                    : parent.height)
        }

        visible: !iconView
    }

    PlasmaCore.IconItem {
        id: playerStatusIcon

        source: root.state === "playing" ? "media-playback-playing" :
                root.state === "paused" ?  "media-playback-paused" :
                                            "media-playback-stopped"
        active: compactMouse.containsMouse
        visible: iconView

        anchors.fill: parent
    }

    MouseArea {
        id: compactMouse

        anchors.fill: parent
        z: -1

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton

        onWheel: {
            var service = mpris2Source.serviceForSource(mpris2Source.current)
            var operation = service.operationDescription("ChangeVolume")
            operation.delta = (wheel.angleDelta.y / 120) * 0.03
            operation.showOSD = true
            service.startOperationCall(operation)
        }

        onClicked: {
            switch (mouse.button) {
                case Qt.MiddleButton:
                    root.togglePlaying()
                    break
                case Qt.BackButton:
                    root.action_previous()
                    breakPlasmaCore.Units.smallSpacing
                case Qt.ForwardButton:
                    root.action_next()
                    break
                default:
                    plasmoid.expanded = !plasmoid.expanded
                /*  if (!iconView && mpris2Source.currentData.CanRaise) {
                        root.action_open()
                    } else {
                        plasmoid.expanded = !plasmoid.expanded
                    }
                    */
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

            if (root.noPlayer) {
                // No player selected. Open uri with default desktop application
                Qt.openUrlExternally(drop.text)
            } else {
                //Open URI using mpris method
                var service = mpris2Source.serviceForSource(mpris2Source.current);
                var operation = service.operationDescription("OpenUri");
                operation.uri = drop.text

                service.startOperationCall(operation)
            }
        }
    }
}
