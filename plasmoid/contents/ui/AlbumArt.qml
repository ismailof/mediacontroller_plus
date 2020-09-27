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

import QtQuick 2.4
import org.kde.plasma.core 2.0 as PlasmaCore


Item {
    readonly property double artRatio: albumArt.visible ? (albumArt.sourceSize.width / albumArt.sourceSize.height) : 1
    property int iconMargins: 0     // Setting this as an alias property makes plasmoidviewer segfault

    Image { // Album Art
        id: albumArt

        anchors.fill: parent

        visible: Media.hasAlbumArt && status === Image.Ready

        asynchronous: true

        horizontalAlignment: Image.AlignRight
        verticalAlignment: Image.AlignVCenter
        fillMode: Image.PreserveAspectFit

        source: processArtUrl(Media.albumArt.toString())
    }

    PlasmaCore.IconItem { // Fallback Icon
        id: mediaIcon
        visible: !albumArt.visible
        source: Media.fallbackIcon

        anchors {
            fill: parent
            margins: iconMargins
        }
    }

    //FIXME: This function gets called on every media update (every second)
    // Improve the timer update or the property changes binding

    // HACK: Spotify has changed the base URL of their album art images
    // but hasn't updated the URL reported by the MPRIS service
    // https://community.spotify.com/t5/Desktop-Linux/MPRIS-cover-art-url-file-not-found/td-p/4920104
    function processArtUrl(artUrl) {
        let SPOTIFY_OLD_URL = "https://open.spotify.com"
        let SPOTIFY_NEW_URL = "https://i.scdn.co"

        if (artUrl.startsWith(SPOTIFY_OLD_URL)) {
            return artUrl.replace(SPOTIFY_OLD_URL, SPOTIFY_NEW_URL)
        }
        return artUrl
    }
}
