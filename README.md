# mediacontroller+
This is a modified version of mediacontroller plasma5 widget.

It provides the same functionality as the traditional mediacontroller widget, giving you control over every media player in your system (through the MPRIS2 protocol), but it adapts to more factor forms and sizes, allowing you to have a nice media control even on the panel.

You can download it on the [KDE Store](https://store.kde.org/p/1317639/), or use the built-in 'Get New Addons' directly in your plasma desktop.

![mediacontroller+ gallery](screenshot.png)

* Full Representation (_desktop_, _pop-up_):
    - Vertical View (same as in classic mediacontroller)
    - Horizontal View: when the widget gets wider, the album art goes to the left
    - Icon tab bar to select the player in a nicer and quicker way

* Compact Representation (_panel_, _systray_):
    - Different Views:
        - Compact View for panels. It keeps most of the functionallity in a smaller size: icon/album art, track/artist, player controls and progress bar which uses the same style as the taskbar progress jobs.
        - Minimal View for thinner panels, hiding the album art and progress bar
        - Icon View for smaller sizes (same as in classic mediacontroller)
    - Minimum (preferred) / Maximum widths configurable
    - Display options to show/hide progressbar
    - Drag and drop any media file to open it on the selected player (the player has to support this option)

As a disclaimer, it is one of my first tries on qml and plasmoids, and I just wanted to have a nicer media player applet for my panel, while keeping the most of the classic widget untouched. Of course, my main wish would be for this changes to be integrated in the official mediacontroller applet, which I find kind of visually simple in its current state.
