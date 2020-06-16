/***************************************************************************
 *   Copyright 2013 Sebastian Kügler <sebas@kde.org>                       *
 *   Copyright 2014, 2016 Kai Uwe Broulik <kde@privat.broulik.de>          *
 *   Copyright 2020 Carson Black <uhhadd@gmail.com>                        *
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

pragma Singleton

import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

QtObject {
    id: media

    property var sources: []

    property alias source: mpris2Source

    property var current: mpris2Source.currentData || {}

    property alias currentSource: mpris2Source.currentSource

    readonly property var currentMetadata: mpris2Source.currentData ? mpris2Source.currentData.Metadata : {}
    readonly property bool noPlayers: mpris2Source.sources.length <= 1
    readonly property var albumArt: currentMetadata ? currentMetadata["mpris:artUrl"] || "" : ""
    readonly property var fallbackIcon: current ? current["Desktop Icon Name"] || "media-album-cover" : "media-album-cover"
    readonly property var desktopIcon: current ? current["Desktop Icon Name"] || current["DesktopEntry"] || "emblem-music-symbolic" : "emblem-music-symbolic"

    readonly property bool hasCurrentTrack: currentTrack != ""
    readonly property bool hasAlbumArt: albumArt != "" && hasCurrentTrack
    readonly property bool hasCurrentArtist: currentArtist != "" && hasCurrentTrack
    readonly property string currentPlayer: !noPlayers ? current.Identity : ""

    property bool lockPositionUpdate: false

    readonly property string currentTrack: {
        if (!currentMetadata) return ""

        var xesamTitle = currentMetadata["xesam:title"]
        if (xesamTitle) return xesamTitle

        var xesamUrl = currentMetadata["xesam:url"] ? currentMetadata["xesam:url"].toString() : ""
        if (!xesamUrl) return ""

        var lastSlashPos = xesamUrl.lastIndexOf('/')
        if (lastSlashPos < 0) return ""

        var lastUrlPart = xesamUrl.substring(lastSlashPos + 1)
        return decodeURIComponent(lastUrlPart)
    }
    readonly property string currentArtist: {
        if (!currentMetadata) return ""

        var xesamArtist = currentMetadata["xesam:artist"]
        if (!xesamArtist) return ""

        if (typeof xesamArtist == "string") {
            return xesamArtist
        }
        return xesamArtist.join(", ")
    }
    readonly property string currentAlbum: {
        if (!currentMetadata) return ""

        var xesamAlbum = currentMetadata["xesam:album"]
        if (xesamAlbum) return xesamAlbum

        if (currentMetadata["xesam:title"] || currentArtist) return ""

        var xesamUrl = (currentMetadata["xesam:url"] || "").toString()
        if (xesamUrl.indexOf("file:///") !== 0) return ""

        var urlParts = xesamUrl.split("/")
        if (urlParts.length < 3) return ""

        var lastFolderPath = urlParts[urlParts.length - 2] // last would be filename
        if (lastFolderPath) return lastFolderPath

        return ""
    }

    readonly property real playbackRate: current.Rate || 1
    readonly property double songLength: currentMetadata ? currentMetadata["mpris:length"] || 0 : 0
    readonly property bool canSeek: current.CanSeek || false

    readonly property bool canControl: (!noPlayers && current.CanControl) || false
    readonly property bool canGoPrevious: (canControl && current.CanGoPrevious) || false
    readonly property bool canGoNext: (canControl && current.CanGoNext) || false
    readonly property bool canPlay: (canControl && current.CanPlay) || false
    readonly property bool canPause: (canControl && current.CanPause) || false

    property double position: current.Position || 0

    enum Actions {
        Play,
        Pause,
        Next,
        Previous,
        Stop,
        Raise,
        Quit,
        PlayPause
    }

    // Helper function so we don't spam output logs for something that we
    // expect can be null.
    function silentNull(i) {
        if (i == null) {
            return {}
        }
        return i
    }

    property QtObject dataSource: PlasmaCore.DataSource {
        id: mpris2Source

        readonly property string multiplexSource: "@multiplex"
                 property string currentSource: multiplexSource

        readonly property var currentData: data[currentSource]

        engine: "mpris2"
        connectedSources: sources

        onSourceAdded: media.updateSources()
        onSourceRemoved: media.updateSources()
        Component.onCompleted: media.updateSources()
    }


    function retrievePosition() {
        var service = mpris2Source.serviceForSource(mpris2Source.currentSource)
        var operation = service.operationDescription("GetPosition")
        service.startOperationCall(operation)
    }

    function setPosition(position) {
        var service = mpris2Source.serviceForSource(mpris2Source.currentSource)
        var operation = service.operationDescription("SetPosition")
        operation.microseconds = position
        service.startOperationCall(operation)
    }

    function openUri(uri) {
        var service = mpris2Source.serviceForSource(mpris2Source.currentSource)
        var operation = service.operationDescription("OpenUri")
        operation.uri = uri
        service.startOperationCall(operation)
    }

    function updateSources() {
        /* Qt 5.14 - This doesn't work as expected
        media.sources = Array.from(mpris2Source.sources)
                             .filter(source => source !== mpris2Source.multiplexSource)
                             .map(source => {
                                 return {
                                     'text': mpris2Source.data[source]["Identity"],
                                     'icon': mpris2Source.data[source]["Desktop Icon Name"] || mpris2Source.data[source]["Desktop Entry"] || source,
                                     'source': source
                                 }
                             })
                             .unshift({
                                'text': i18n("Choose player automatically"),
                                'icon': 'emblem-favorite',
                                'source': mpris2Source.multiplexSource
                            })
        */
        var model = [media.sources = {
            'text': i18n("Choose player automatically"),
            'icon': 'emblem-favorite',
            'source': mpris2Source.multiplexSource
        }]

        var sources = mpris2Source.sources
        for (var i = 0, length = sources.length; i < length; ++i) {
            var source = sources[i]
            if (source === mpris2Source.multiplexSource) {
                continue
            }

            model.push({
                'text': mpris2Source.data[source]["Identity"],
                'icon': mpris2Source.data[source]["Desktop Icon Name"] || mpris2Source.data[source]["Desktop Entry"] || source,
                'source': source
            });
        }

        media.sources = model;
    }

    function serviceOp(src, op) {
        var service = mpris2Source.serviceForSource(src)
        var operation = service.operationDescription(op)
        service.startOperationCall(operation)
    }

    function adjustVolume(delta) {
        let service = mpris2Source.serviceForSource(mpris2Source.currentSource)
        let operation = service.operationDescription("ChangeVolume")
        operation.delta = delta
        operation.showOSD = true
        service.startOperationCall(operation)
    }

    function perform(act) {
        switch(act) {
            case Media.Actions.Play:
                serviceOp(mpris2Source.currentSource, "Play")
                break
            case Media.Actions.Pause:
                serviceOp(mpris2Source.currentSource, "Pause")
                break
            case Media.Actions.Previous:
                serviceOp(mpris2Source.currentSource, "Previous")
                break
            case Media.Actions.Next:
                serviceOp(mpris2Source.currentSource, "Next")
                break
            case Media.Actions.Stop:
                serviceOp(mpris2Source.currentSource, "Stop")
                break
            case Media.Actions.Raise:
                serviceOp(mpris2Source.currentSource, "Raise")
                break
            case Media.Actions.Quit:
                serviceOp(mpris2Source.currentSource, "Quit")
                break
            case Media.Actions.PlayPause:
                serviceOp(mpris2Source.currentSource, "PlayPause")
                break
            default:
                print("Unhandled action: " + act)
        }
    }

    function togglePlaying() {
        if (Media.state === "playing" && Media.canPause) {
            Media.perform(Media.Actions.Pause)
        } else if (Media.canPlay) {
            Media.perform(Media.Actions.Play)
        }
    }

    function action_open()      { Media.perform(Media.Actions.Raise)     }
    function action_quit()      { Media.perform(Media.Actions.Quit)      }
    function action_play()      { Media.perform(Media.Actions.Play)      }
    function action_pause()     { Media.perform(Media.Actions.Pause)     }
    function action_playPause() { Media.perform(Media.Actions.PlayPause) }
    function action_previous()  { Media.perform(Media.Actions.Previous)  }
    function action_next()      { Media.perform(Media.Actions.Next)      }
    function action_stop()      { Media.perform(Media.Actions.Stop)      }

    property string state: {
        if (!media.noPlayer && silentNull(media.current).PlaybackStatus === "Playing") {
            return "playing"
        } else if (!media.noPlayer && silentNull(media.current).PlaybackStatus === "Paused") {
            return "paused"
        }
        return ""
    }
}
