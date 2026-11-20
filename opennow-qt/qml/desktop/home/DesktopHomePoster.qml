pragma ComponentBehavior: Bound

import QtQuick
import OpenNOW

Item {
    id: card
    required property var game
    property int tileWidth: DesktopTokens.posterWidth
    property int tileHeight: DesktopTokens.posterHeight
    property bool featured: false
    property bool current: false
    readonly property bool highlighted: hover.hovered || (current && AppController.inputMode !== "pointer")
    readonly property string title: game ? String(game.title || qsTr("Game")) : ""
    readonly property string artwork: DesktopTokens.artworkUrl(game, false)
    signal activated()
    signal playRequested()
    signal pointed()
    function activateAt(position) {
        if (highlighted && quickPlay.contains(quickPlay.mapFromItem(card, position.x, position.y))) playRequested()
        else activated()
    }

    objectName: "desktopHomePoster-" + String(game && game.id || "")
    width: tileWidth; height: tileHeight
    Accessible.role: Accessible.Button; Accessible.name: title; Accessible.description: labels.summary
    Accessible.onPressAction: activated()

    MotionProgress { id: highlight; shown: card.highlighted; enterDuration: 190; exitDuration: 155 }
    Item {
        id: cover
        width: card.tileWidth; height: card.tileHeight
        transformOrigin: Item.Center
        property real pressScale: tap.pressed ? 0.978 : 1
        Behavior on pressScale { NumberAnimation { duration: DesktopTokens.quickDuration; easing.type: Easing.OutCubic } }
        scale: AppController.reducedMotion ? 1 : (1 + 0.018 * highlight.progress) * pressScale
        transform: Translate { y: AppController.reducedMotion ? 0 : -DesktopTokens.px(3) * highlight.progress }
        RoundedArtwork {
            anchors.fill: parent; artwork: card.artwork; fallbackTitle: card.title; fallbackColor: "#22242D"
            cornerRadius: DesktopTokens.px(6); scrimStart: 1 - 0.22 * highlight.progress
        }
        Rectangle { anchors.fill: parent; radius: DesktopTokens.px(6); color: "transparent"; border.color: DesktopTokens.seamSoft }
        Rectangle {
            anchors.fill: parent; anchors.margins: -2; radius: DesktopTokens.px(8)
            color: "transparent"; border.width: 1; border.color: "#F3F3F5"; opacity: card.featured ? 0.72 : highlight.progress
        }
        DesktopGameLabels {
            id: labels
            anchors.fill: parent
            anchors.margins: DesktopTokens.px(9)
            game: card.game
            liftedBottom: quickPlay.height + DesktopTokens.px(5)
            opacity: locked ? 1 : highlight.progress
            visible: hasContent && opacity > 0
        }
        Rectangle {
            id: quickPlay; objectName: "desktopPosterPlay"
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: DesktopTokens.px(10)
            width: DesktopTokens.px(37); height: width; radius: width / 2; color: "#F4F5F8"
            visible: highlight.present; opacity: highlight.progress
            transform: Translate { y: AppController.reducedMotion ? 0 : (1 - highlight.progress) * 5 }
            Accessible.role: Accessible.Button; Accessible.name: qsTr("Play"); Accessible.onPressAction: card.playRequested()
            DesktopGlyph { anchors.centerIn: parent; width: DesktopTokens.px(17); height: width; icon: "desktop-play-filled.svg" }
        }
    }
    HoverHandler {
        id: hover; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: if (hovered) card.pointed()
    }
    TapHandler {
        id: tap; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus | PointerDevice.TouchScreen
        onTapped: eventPoint => card.activateAt(eventPoint.position)
    }
}
