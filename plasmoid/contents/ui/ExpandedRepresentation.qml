/***************************************************************************
 *   Copyright 2013 Sebastian Kügler <sebas@kde.org>                       *
 *   Copyright 2014, 2016 Kai Uwe Broulik <kde@privat.broulik.de>          *
 *   Copyright 2020 Carson Black <uhhadd@gmail.com>                        *
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

import QtQuick 2.8
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.kirigami 2.4 as Kirigami
import QtGraphicalEffects 1.0

Item {
    id: expandedRepresentation

    Layout.minimumWidth: units.gridUnit * 14
    Layout.minimumHeight: units.gridUnit * 14
    Layout.preferredWidth: Layout.minimumWidth * 1.5
    Layout.preferredHeight: Layout.minimumHeight * 1.5

    readonly property int controlSize: units.iconSizes.large
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    property bool keyPressed: false

    // only show hours (the default for KFormat) when track is actually longer than an hour
    readonly property int durationFormattingOptions: Media.length >= 60*60*1000*1000 ? 0 : KCoreAddons.FormatTypes.FoldHours

    Connections {
        target: plasmoid
        onExpandedChanged: {
            if (plasmoid.expanded) {
                Media.retrievePosition()
            }
        }
    }

    Connections {
        target: Media
        function onSongLengthChanged(length) {
            Media.lockPositionUpdate = true
            {
                seekSlider.value = 0
                seekSlider.to = Media.songLength
                Media.retrievePosition()
            }
            Media.lockPositionUpdate = false
        }
        function onPositionChanged(position) {
            // Don't interrupt an active drag.
            if (!seekSlider.pressed && !keyPressed) {
                Media.lockPositionUpdate = true
                {
                    seekSlider.value = Media.position
                }
                Media.lockPositionUpdate = false
            }
        }
    }

    Keys.onPressed: keyPressed = true

    Keys.onReleased: {
        keyPressed = false

        if (!event.modifiers) {
            event.accepted = true

            if (event.key === Qt.Key_Space || event.key === Qt.Key_K) {
                // K is YouTube's key for "play/pause" :)
                Media.togglePlaying()
            } else if (event.key === Qt.Key_P) {
                Media.perform(Media.Actions.Previous)
            } else if (event.key === Qt.Key_N) {
                Media.perform(Media.Actions.Next)
            } else if (event.key === Qt.Key_S) {
                Media.perform(Media.Actions.Stop)
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_J) { // TODO ltr languages
                // seek back 5s
                seekSlider.value = Math.max(0, seekSlider.value - 5000000) // microseconds
                seekSlider.moved()
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                // seek forward 5s
                seekSlider.value = Math.min(seekSlider.to, seekSlider.value + 5000000)
                seekSlider.moved()
            } else if (event.key === Qt.Key_Home) {
                seekSlider.value = 0
                seekSlider.moved()
            } else if (event.key === Qt.Key_End) {
                seekSlider.value = seekSlider.to
                seekSlider.moved()
            } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                // jump to percentage, ie. 0 = beginnign, 1 = 10% of total length etc
                seekSlider.value = seekSlider.to * (event.key - Qt.Key_0) / 10
                seekSlider.moved()
            } else {
                event.accepted = false
            }
        }
    }

    ColumnLayout { // Main Column Layout
        id: mainCol
        anchors.fill: parent

        Item { // Album Art Background + Details
            Layout.fillWidth: true
            Layout.fillHeight: true


            Image {
                id: backgroundImage

                source: Media.albumArt
                sourceSize.width: 512 /*
                                       * Setting a sourceSize.width here
                                       * prevents flickering when resizing the
                                       * plasmoid on a desktop.
                                       */

                anchors.fill: parent
                anchors.margins: -units.smallSpacing*2
                fillMode: Image.PreserveAspectCrop

                asynchronous: true
                visible: Media.hasCurrentTrack && status === Image.Ready && !softwareRendering

                layer.enabled: !softwareRendering
                layer.effect: HueSaturation {
                    cached: true

                    lightness: -0.5
                    saturation: 0.9

                    layer.enabled: true
                    layer.effect: GaussianBlur {
                        cached: true

                        radius: 256
                        deviation: 12
                        samples: 129

                        transparentBorder: false
                    }
                }
            }
            RowLayout { // Album Art + Details
                id: albumRow

                anchors {
                    fill: parent
                    leftMargin: units.largeSpacing
                    rightMargin: units.largeSpacing
                }

                spacing: units.largeSpacing

                AlbumArt {
                    id: albumArt
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 50
                    iconMargins: units.largeSpacing * 2
                }

                ColumnLayout { // Details Column
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 50
                    Layout.alignment: !(albumArt.visible || Media.current["Desktop Icon Name"]) ? Qt.AlignHCenter : 0

                    /*
                     * We use Kirigami.Heading instead of PlasmaExtras.Heading
                     * to prevent a binding loop caused by the PC2 Label component
                     * used by PlasmaExtras.Heading
                     */
                    Kirigami.Heading { // Song Title
                        id: songTitle
                        level: 1

                        color: (softwareRendering || !albumArt.visible) ? PlasmaCore.ColorScope.textColor : "white"

                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        fontSizeMode: Text.VerticalFit
                        elide: Text.ElideRight

                        text: Media.hasCurrentTrack ? Media.currentTrack : i18n("No media playing")

                        Layout.fillWidth: true
                        Layout.maximumHeight: units.gridUnit*5
                    }
                    Kirigami.Heading { // Song Artist
                        id: songArtist
                        visible: Media.hasCurrentArtist
                        level: 2

                        color: (softwareRendering || !albumArt.visible) ? PlasmaCore.ColorScope.textColor : "white"

                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        fontSizeMode: Text.VerticalFit
                        elide: Text.ElideRight

                        text: Media.currentArtist
                        Layout.fillWidth: true
                        Layout.maximumHeight: units.gridUnit*2
                    }
                    Kirigami.Heading { // Song Album
                        color: (softwareRendering || !albumArt.visible) ? PlasmaCore.ColorScope.textColor : "white"

                        level: 3
                        opacity: 0.6

                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        fontSizeMode: Text.VerticalFit
                        elide: Text.ElideRight

                        visible: text.length !== 0
                        text: Media.currentAlbum
                        Layout.fillWidth: true
                        Layout.maximumHeight: units.gridUnit*2
                    }
                }
            }
        }

        Item {
            implicitHeight: units.smallSpacing
        }

        RowLayout { // Seek Bar
            spacing: units.smallSpacing

            // if there's no "mpris:length" in the metadata, we cannot seek, so hide it in that case
            enabled: !Media.noPlayers && Media.hasCurrentTrack && Media.songLength > 0
            opacity: enabled ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: units.longDuration }
            }

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumWidth: Math.min(units.gridUnit*45, Math.round(expandedRepresentation.width*(7/10)))

            // ensure the layout doesn't shift as the numbers change and measure roughly the longest text that could occur with the current song
            TextMetrics {
                id: timeMetrics
                text: i18nc("Remaining time for song e.g -5:42", "-%1",
                            KCoreAddons.Format.formatDuration(seekSlider.to / 1000, expandedRepresentation.durationFormattingOptions))
                font: theme.smallestFont
            }

            PlasmaComponents3.Label { // Time Elapsed
                Layout.preferredWidth: timeMetrics.width
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: KCoreAddons.Format.formatDuration(seekSlider.value / 1000, expandedRepresentation.durationFormattingOptions)
                opacity: 0.9
                font: theme.smallestFont
                color: PlasmaCore.ColorScope.textColor
            }

            PlasmaComponents3.Slider { // Slider
                id: seekSlider
                Layout.fillWidth: true
                z: 999
                value: 0
                visible: Media.canSeek

                onMoved: {
                    if (!Media.lockPositionUpdate) {
                        // delay setting the position to avoid race conditions
                        queuedPositionUpdate.restart()
                    }
                }

                Timer {
                    id: seekTimer
                    interval: 1000 / Media.playbackRate
                    repeat: true
                    running: Media.state === "playing" && plasmoid.expanded && !keyPressed && interval > 0 && seekSlider.to >= 1000000
                    onTriggered: {
                        // some players don't continuously update the seek slider position via mpris
                        // add one second; value in microseconds
                        if (!seekSlider.pressed) {
                            Media.lockPositionUpdate = true
                            if (seekSlider.value == seekSlider.to) {
                                Media.retrievePosition()
                            } else {
                                seekSlider.value += 1000000
                            }
                            Media.lockPositionUpdate = false
                        }
                    }
                }
            }

            RowLayout {
                visible: !Media.canSeek

                Layout.fillWidth: true
                Layout.preferredHeight: seekSlider.height

                PlasmaComponents3.ProgressBar { // Time Remaining
                    value: seekSlider.value
                    from: seekSlider.from
                    to: seekSlider.to

                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            PlasmaComponents3.Label {
                Layout.preferredWidth: timeMetrics.width
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                text: i18nc("Remaining time for song e.g -5:42", "-%1",
                            KCoreAddons.Format.formatDuration((seekSlider.to - seekSlider.value) / 1000, expandedRepresentation.durationFormattingOptions))
                opacity: 0.9
                font: theme.smallestFont
                color: PlasmaCore.ColorScope.textColor
            }
        }

        Row { // Player Controls
            id: playerControls

            property bool enabled: Media.canControl
            property int controlsSize: theme.mSize(theme.defaultFont).height * 3

            Layout.alignment: Qt.AlignHCenter
            spacing: units.largeSpacing

            PlasmaComponents3.ToolButton { // Previous
                anchors.verticalCenter: parent.verticalCenter
                width: expandedRepresentation.controlSize
                height: width
                enabled: playerControls.enabled && Media.canGoPrevious
                icon.name: LayoutMirroring.enabled ? "media-skip-forward" : "media-skip-backward"
                onClicked: {
                    seekSlider.value = 0    // Let the media start from beginning. Bug 362473
                    Media.perform(Media.Actions.Previous)
                }
            }

            PlasmaComponents3.ToolButton { // Pause/Play
                width: Math.round(expandedRepresentation.controlSize * 1.5)
                height: width
                enabled: Media.state == "playing" ? Media.canPause : Media.canPlay
                icon.name: Media.state == "playing" ? "media-playback-pause" : "media-playback-start"
                onClicked: Media.togglePlaying()
            }

            PlasmaComponents3.ToolButton { // Next
                anchors.verticalCenter: parent.verticalCenter
                width: expandedRepresentation.controlSize
                height: width
                enabled: playerControls.enabled && Media.canGoNext
                icon.name: LayoutMirroring.enabled ? "media-skip-backward" : "media-skip-forward"
                onClicked: {
                    seekSlider.value = 0    // Let the media start from beginning. Bug 362473
                    Media.perform(Media.Actions.Next)
                }
            }
        }

        PlasmaComponents3.ComboBox {
            Layout.fillWidth: true
            Layout.leftMargin: units.gridUnit*2
            Layout.rightMargin: units.gridUnit*2

            id: playerCombo
            textRole: "text"
            visible: model.length > 2 // more than one player, @multiplex is always there
            model: Media.sources

            onModelChanged: {
                // if model changes, ComboBox resets, so we try to find the current player again...
                for (var i = 0; i < model.length; ++i) {
                    if (model[i].source === Media.source.current) {
                        currentIndex = i
                        break
                    }
                }
            }

            onActivated: {
                Media.lockPositionUpdate = true
                // ComboBox has currentIndex and currentText, why doesn't it have currentItem/currentModelValue?
                Media.currentSource = model[index].source
                Media.lockPositionUpdate = false
            }
        }
    }

    Timer {
        id: queuedPositionUpdate
        interval: 100
        onTriggered: {
            if (Media.position == seekSlider.value) {
                return
            }
            Media.setPosition(seekSlider.value)
        }
    }
}
