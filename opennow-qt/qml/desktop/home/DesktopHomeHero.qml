pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import OpenNOW

Item {
    id: hero
    required property var game
    required property string metadata
    required property string streamDescription
    required property string editorialFont
    required property bool loading
    required property bool active
    required property int position
    required property int count
    required property int selection
    property bool horizontal: false
    readonly property int margin: Math.min(DesktopTokens.px(48), Math.max(DesktopTokens.px(12), width * 0.055))
    readonly property bool small: height < DesktopTokens.px(570)
    readonly property string artwork: DesktopTokens.artworkUrl(game, true)
    readonly property string title: game ? String(game.title || qsTr("Game")) : loading ? qsTr("Loading…") : qsTr("No games yet")
    signal play()
    signal details()
    signal browse()
    signal step(int direction)

    ArtworkSource { id: art; sourceUrl: hero.artwork; active: hero.active }
    property int front: -1
    function requestImage() {
        if (!first || !second) return
        const url = String(art.resolvedUrl || "")
        if (!url) { front = -1; return }
        if (String(first.source) === url && first.status === Image.Ready) { front = 0; return }
        if (String(second.source) === url && second.status === Image.Ready) { front = 1; return }
        const target = front === 0 ? second : first
        target.source = url
    }
    Connections { target: art; function onResolvedUrlChanged() { hero.requestImage() } }
    Component.onCompleted: requestImage()
    onGameChanged: if (active && titleEntrance) titleEntrance.restart()

    component ArtPlane: Image {
        id: plane
        required property int slot
        // Widescreen key art typically places its subject just right of centre.
        width: parent.width * (implicitWidth > implicitHeight * 1.7 ? 1.48 : 1)
        height: parent.height; anchors.right: parent.right
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: Math.min(2240, Math.max(640, Math.ceil(parent.width * 1.55 * Screen.devicePixelRatio / 128) * 128))
        opacity: hero.front === slot ? 1 : 0
        visible: opacity > 0
        onStatusChanged: {
            if (String(source) !== String(art.resolvedUrl)) return
            art.reportImageStatus(status, source)
            if (status === Image.Ready) hero.front = slot
            else if (status === Image.Error) hero.front = -1
        }
        Behavior on opacity { NumberAnimation { duration: DesktopTokens.revealDuration; easing.type: Easing.InOutCubic } }
    }

    Item {
        id: photograph
        x: hero.horizontal ? hero.width * 0.42 : hero.margin * 0.37
        y: hero.horizontal ? 0 : Math.max(DesktopTokens.px(21), hero.height * 0.047)
        width: hero.horizontal ? hero.width - x : hero.width - x - hero.margin * 0.36
        height: hero.horizontal ? hero.height : hero.height * 0.83
        Item {
            anchors.fill: parent; clip: true
            Rectangle { anchors.fill: parent; color: "#242735" }
            Image { anchors.fill: parent; source: "qrc:/qt/qml/OpenNOW/res/brand/stillforce-satin.png"; fillMode: Image.PreserveAspectCrop }
            ArtPlane { id: first; slot: 0 }
            ArtPlane { id: second; slot: 1 }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.33; color: "transparent" }
                    GradientStop { position: 0.68; color: "#2009090C" }
                    GradientStop { position: 0.87; color: "#A009090C" }
                    GradientStop { position: 1; color: "#FF09090C" }
                }
            }
            Rectangle {
                anchors.fill: parent; visible: hero.horizontal
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#FF09090C" }
                    GradientStop { position: 0.65; color: "transparent" }
                }
            }
        }
        Shape {
            id: rim
            anchors.fill: parent
            readonly property real bend: Math.min(width * 0.50, height * 0.49)
            readonly property real tangent: bend * 0.447715
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1; fillColor: "#09090C"
                startX: 0; startY: 0
                PathLine { x: rim.bend; y: 0 }
                PathCubic { x: 0; y: rim.bend; control1X: rim.tangent; control1Y: 0; control2X: 0; control2Y: rim.tangent }
                PathLine { x: 0; y: 0 }
                PathMove { x: rim.width; y: 0 }
                PathLine { x: rim.width - rim.bend; y: 0 }
                PathCubic { x: rim.width; y: rim.bend; control1X: rim.width - rim.tangent; control1Y: 0; control2X: rim.width; control2Y: rim.tangent }
                PathLine { x: rim.width; y: 0 }
            }
        }
    }

    PageEntrance { id: titleEntrance }
    Column {
        id: legend
        x: hero.margin
        anchors.bottom: parent.bottom
        anchors.bottomMargin: hero.horizontal ? DesktopTokens.px(12) : Math.max(DesktopTokens.px(18), hero.height * 0.053)
        width: hero.horizontal ? hero.width * 0.66 : hero.width - x - hero.margin * 0.6
        spacing: DesktopTokens.px(hero.small ? 6 : 10)
        opacity: titleEntrance.pageOpacity
        transform: Translate { y: titleEntrance.offset }
        Text {
            width: parent.width; elide: Text.ElideRight
            text: (hero.game && hero.game.lastPlayed ? qsTr("Continue playing") : qsTr("Featured game")).toLocaleUpperCase()
            color: "#DADCE2"; font.family: Theme.monoFont; font.pixelSize: DesktopTokens.smallSize; font.letterSpacing: 1.8
        }
        Text {
            width: parent.width
            text: hero.title.replace(/[®™]+$/, "").trim(); textFormat: Text.PlainText
            Accessible.name: hero.title
            color: "#F8F6EF"; font.family: hero.editorialFont
            readonly property int headlineSize: Math.round(Math.min(DesktopTokens.px(122), Math.max(DesktopTokens.px(32),
                Math.min(hero.width * (hero.horizontal ? 0.095 : 0.149), hero.height * (hero.horizontal ? 0.25 : 0.13)))))
            font.pixelSize: headlineSize
            font.letterSpacing: -headlineSize * 0.032
            maximumLineCount: hero.horizontal ? 1 : 2; wrapMode: Text.WordWrap; elide: Text.ElideRight; lineHeight: 0.90
        }
        Text {
            width: parent.width; visible: Boolean(hero.game) && !hero.horizontal; elide: Text.ElideRight; textFormat: Text.PlainText
            text: {
                const stores = hero.game && hero.game.availableStores || []
                return stores.length ? String(stores[0]) + "   ·   " + hero.metadata : hero.metadata
            }
            color: "#B7B8C0"; font.family: Theme.bodyFont; font.pixelSize: DesktopTokens.captionSize
        }
        Item { width: 1; height: hero.small ? 0 : DesktopTokens.px(8) }
        Row {
            visible: !hero.loading; spacing: DesktopTokens.px(14)
            DesktopButton {
                id: playButton; objectName: "homeHeroPlay"
                text: hero.game ? qsTr("Play now") : qsTr("Open library")
                primary: true; onMediaBackground: true
                glyph: hero.game ? "desktop-play-filled.svg" : ""; glyphSize: DesktopTokens.px(13)
                height: DesktopTokens.px(hero.small ? 36 : 44); leftPadding: DesktopTokens.px(17); rightPadding: leftPadding; cornerRadius: height / 2
                Accessible.description: hero.streamDescription
                onClicked: hero.game ? hero.play() : hero.browse()
                Rectangle { anchors.fill: parent; anchors.margins: -3; radius: height / 2; color: "transparent"; border.width: 1; border.color: "white"; visible: hero.selection === 0 && !parent.activeFocus }
            }
            Button {
                id: info; objectName: "homeHeroDetails"; visible: Boolean(hero.game); height: playButton.height; padding: DesktopTokens.px(6)
                text: qsTr("Details"); onClicked: hero.details()
                background: Rectangle { radius: height / 2; color: info.hovered ? "#20FFFFFF" : "transparent"; border.width: info.visualFocus || hero.selection === 1 ? 1 : 0; border.color: "white" }
                contentItem: Text { text: info.text + "  ↗"; color: "#DEDEE3"; font.family: Theme.bodyFont; font.pixelSize: DesktopTokens.captionSize; verticalAlignment: Text.AlignVCenter }
            }
        }
    }

    Row {
        id: pager
        anchors.right: parent.right; anchors.rightMargin: hero.margin
        y: hero.horizontal ? DesktopTokens.px(2) : Math.max(DesktopTokens.px(3), hero.height * 0.009)
        visible: !hero.loading && hero.count > 1
        component Arrow: Button {
            id: arrow
            required property int direction
            width: DesktopTokens.px(30); height: width; padding: 0
            Accessible.name: direction < 0 ? qsTr("Previous game") : qsTr("Next game")
            onClicked: hero.step(direction)
            background: Rectangle { radius: height / 2; color: arrow.hovered ? "#24FFFFFF" : "transparent"; border.width: arrow.visualFocus || hero.selection === (arrow.direction < 0 ? 2 : 3) ? 1 : 0; border.color: "white" }
            contentItem: Text { text: arrow.direction < 0 ? "‹" : "›"; color: "#BABDC4"; font.pixelSize: DesktopTokens.px(19); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
        Arrow { direction: -1; objectName: "homePreviousFeature" }
        Text {
            height: DesktopTokens.px(30); verticalAlignment: Text.AlignVCenter
            text: String(hero.position + 1).padStart(2, "0") + " / " + String(hero.count).padStart(2, "0")
            color: "#AFB0B8"; font.family: Theme.monoFont; font.pixelSize: DesktopTokens.smallSize; font.letterSpacing: 0.7
        }
        Arrow { direction: 1; objectName: "homeNextFeature" }
    }
}
