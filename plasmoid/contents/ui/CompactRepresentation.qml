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
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore  // Required for KSvg
import org.kde.ksvg as KSvg
import org.kde.kirigami 2 as Kirigami


Item {
    id: compactRoot

    readonly property bool isOnVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    readonly property bool iconView: (width < Kirigami.Units.gridUnit * 2)
                                        || (!Plasmoid.configuration.showAlbumArt
                                            && !Plasmoid.configuration.showTrackInfo
                                            && !Plasmoid.configuration.showPlaybackControls)

    Layout.fillWidth: isOnVertical || Plasmoid.configuration.showTrackInfo
    Layout.fillHeight: !isOnVertical

    Layout.minimumWidth: isOnVertical ? Plasmoid.width : (iconView ? 1 : 5) * Kirigami.Units.gridUnit
    Layout.preferredWidth: Plasmoid.configuration.showTrackInfo ? (Plasmoid.configuration.minimumWidthUnits || 18) * Kirigami.Units.gridUnit
                                                                : mainRow.implicitWidth
    Layout.maximumWidth: isOnVertical ? root.width : Plasmoid.configuration.maximumWidthUnits * Kirigami.Units.gridUnit

    Layout.preferredHeight: isOnVertical ? mainRow.implicitHeight : root.height

    // HACK: To get the panel backgroud margins
    KSvg.Svg {
        id: marginsHelper
        imagePath: "widgets/panel-background"

        readonly property int topMargin: {
            if (hasElement("hint-top-margin")) {
                print(elementSize("hint-top-margin").height)
                return elementSize("hint-top-margin").height
            }
            return Kirigami.Units.smallSpacing
        }
    }

    Item {
        id: miniProgressBar
        z: 0
        visible: Plasmoid.configuration.showProgressBar && !iconView

        anchors.fill: parent
        // Negative margins to fill the panel. It seems simpler than
        //  Plasmoid.constraintHints: PlasmaCore.Types.CanFillArea
        // and the hack to get the margins is required anyway
        anchors.margins: -marginsHelper.topMargin

        Item {
            id: progress
            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
            }

            width: parent.width * root.position / root.length
            clip: true

            KSvg.FrameSvgItem {
                width: miniProgressBar.width
                height: miniProgressBar.height

                imagePath: "widgets/tasks"
                prefix: ["progress", "hover"]
            }
        }
    }

    // HACK: To allow two lines on small panels (~ 32px to 36px)
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

    GridLayout {
        id: mainRow
        z: 100
        visible: !iconView

        columns: isOnVertical ? 1 : -1
        rows: isOnVertical ? -1 : 1

        readonly property bool heightOverflow: trackInfo.implicitHeight > compactRoot.height

        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: rowSpacing

        anchors {
            fill: (isOnVertical || !heightOverflow) ? parent : verticalCenterHelper
            margins: 0
        }

        AlbumArt {
            id: albumArt
            visible: Plasmoid.configuration.showAlbumArt
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            Layout.margins: 2   // To mimick the breeze icons internal margins and better adjust height
            Layout.minimumWidth: isOnVertical ? 0 : height
            Layout.preferredWidth: isOnVertical ? width : height * aspectRatio
            Layout.minimumHeight: isOnVertical ? width : 0
            Layout.preferredHeight: isOnVertical ? width / aspectRatio : height
        }

        TrackInfo {
            id: trackInfo
            visible: Plasmoid.configuration.showTrackInfo
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            textAlignment: isOnVertical ? Text.AlignHCenter : Text.AlignLeft
            lineLimit: {
                if (isOnVertical) return 3;
                if (compactRoot.height > Kirigami.Units.gridUnit * 3) return 3;
                if (compactRoot.height > Kirigami.Units.gridUnit * 1.5) return 2;
                return 1;
            }
            spacing: 0
        }

        PlayerControls {
            id: playerControls
            visible: Plasmoid.configuration.showPlaybackControls
            Layout.fillWidth: isOnVertical || !trackInfo.visible
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            compactView: true
            canFitPrevNext: !isOnVertical || compactRoot.width > Kirigami.Units.iconSizes.smallMedium * 3
            controlSize: Math.max(Kirigami.Units.iconSizes.small,
                                  isOnVertical ? Math.min(compactRoot.width / controlsCount, Kirigami.Units.iconSizes.large) :
                                  trackInfo.visible ? Math.min(parent.height, Kirigami.Units.iconSizes.large)
                                                    : parent.height)
        }
    }

    Kirigami.Icon {
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

        onWheel: wheel => {
            var service = mpris2Source.serviceForSource(mpris2Source.current)
            var operation = service.operationDescription("ChangeVolume")
            operation.delta = (wheel.angleDelta.y / 120) * 0.03
            operation.showOSD = true
            service.startOperationCall(operation)
        }

        onClicked: mouse => {
            switch (mouse.button) {
                case Qt.MiddleButton:
                    root.togglePlaying()
                    break
                case Qt.BackButton:
                    root.action_previous()
                    break
                case Qt.ForwardButton:
                    root.action_next()
                    break
                default:
                    root.expanded = !root.expanded
                    /*  if (!iconView && mpris2Source.currentData.CanRaise) {
                        root.action_open()
                    } else {
                        roo.expanded = !root.expanded
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
