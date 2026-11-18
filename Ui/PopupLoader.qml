import QtQuick

// Loader for a PanelPopup that stays alive until the popup has eased out.
Loader {
    id: loader

    property bool open: false
    property bool lingering: false

    active: open || lingering

    onOpenChanged: if (!open) lingering = !!item && item.reveal > 0

    Connections {
        target: loader.item
        ignoreUnknownSignals: true
        function onRevealChanged() {
            if (!loader.open && loader.item.reveal <= 0) loader.lingering = false
        }
    }
}
