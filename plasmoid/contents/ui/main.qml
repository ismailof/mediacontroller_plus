/***************************************************************************
 *   Copyright 2013 Sebastian Kügler <sebas@kde.org>                       *
 *   Copyright 2014 Kai Uwe Broulik <kde@privat.broulik.de>                *
 *   Copyright 2020 Ismael Asensio <isma.af@gmail.com>                     *
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

import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    id: root

    Plasmoid.switchWidth: units.gridUnit * 14
    Plasmoid.switchHeight: units.gridUnit * 10
    Plasmoid.icon: "media-playback-playing"
    Plasmoid.toolTipMainText: i18n("No media playing")
    Plasmoid.toolTipSubText: Media.currentPlayer
    Plasmoid.toolTipTextFormat: Text.PlainText
    Plasmoid.status: PlasmaCore.Types.PassiveStatus

    Plasmoid.onContextualActionsAboutToShow: {
        plasmoid.clearActions()

        if (Media.noPlayers) {
            return
        }

        if (Media.current.CanRaise) {
            var icon = Media.desktopIcon || ""
            plasmoid.setAction(Media.Actions.Raise, i18nc("Open player window or bring it to the front if already open", "Open"), icon)
        }

        if (Media.canControl) {
            plasmoid.setAction(Media.Actions.Previous, i18nc("Play previous track", "Previous Track"),
                               Qt.application.layoutDirection === Qt.RightToLeft ? "media-skip-forward" : "media-skip-backward")
            plasmoid.action(Media.Actions.Previous).enabled = Qt.binding(function() {
                return Media.canGoPrevious
            })

            // if CanPause, toggle the menu entry between Play & Pause, otherwise always use Play
            if (Media.state == "playing" && Media.canPause) {
                plasmoid.setAction(Media.Actions.Pause, i18nc("Pause playback", "Pause"), "media-playback-pause")
                plasmoid.action(Media.Actions.Pause).enabled = Qt.binding(function() {
                    return Media.state === "playing" && Media.canPause
                })
            } else {
                plasmoid.setAction(Media.Actions.Play, i18nc("Start playback", "Play"), "media-playback-start")
                plasmoid.action(Media.Actions.Play).enabled = Qt.binding(function() {
                    return Media.state !== "playing" && Media.canPlay
                })
            }

            plasmoid.setAction(Media.Actions.Next, i18nc("Play next track", "Next Track"),
                               Qt.application.layoutDirection === Qt.RightToLeft ? "media-skip-backward" : "media-skip-forward")
            plasmoid.action(Media.Actions.Next).enabled = Qt.binding(function() {
                return Media.canGoNext
            })

            plasmoid.setAction(Media.Actions.Stop, i18nc("Stop playback", "Stop"), "media-playback-stop")
            plasmoid.action(Media.Actions.Stop).enabled = Qt.binding(function() {
                return Media.state === "playing" || Media.state === "paused"
            })
        }

        if (Media.current.CanQuit) {
            plasmoid.setAction(Media.Actions.Quit, i18nc("Quit player", "Quit"), "application-exit")
        }

        if (Media.canControl || Media.current.CanRaise || Media.current.CanQuit) {
            plasmoid.setActionSeparator("action-separator")
        }
    }

    function actionTriggered(action) {
        //Parameter `action` is a string, but contains a Media.Actions enum value
        Media.perform(parseInt(action))
    }

    // HACK Some players like Amarok take quite a while to load the next track
    // this avoids having the plasmoid jump between popup and panel
    onStateChanged: {
        if (Media.state != "") {
            plasmoid.status = PlasmaCore.Types.ActiveStatus
        } else {
            updatePlasmoidStatusTimer.restart()
        }
    }

    Timer {
        id: updatePlasmoidStatusTimer
        interval: 3000
        onTriggered: {
            if (Media.state != "") {
                plasmoid.status = PlasmaCore.Types.ActiveStatus
            } else {
                plasmoid.status = PlasmaCore.Types.PassiveStatus
            }
        }
    }

    Plasmoid.fullRepresentation: ExpandedRepresentation {}

    Plasmoid.compactRepresentation: CompactRepresentation {}

    state: Media.state
    states: [
        State {
            name: "playing"

            PropertyChanges {
                target: plasmoid
                icon: "media-playback-playing"
                toolTipMainText: Media.currentTrack
                toolTipSubText: Media.currentArtist ? i18nc("by Artist (player name)", "by %1 (%2)", Media.currentArtist, Media.currentPlayer) : Media.currentPlayer
            }
        },
        State {
            name: "paused"

            PropertyChanges {
                target: plasmoid
                icon: "media-playback-paused"
                toolTipMainText: Media.currentTrack
                toolTipSubText: Media.currentArtist ? i18nc("by Artist (paused, player name)", "by %1 (paused, %2)", Media.currentArtist, Media.currentPlayer) : i18nc("Paused (player name)", "Paused (%1)", Media.currentPlayer)
            }
        }
    ]
}
