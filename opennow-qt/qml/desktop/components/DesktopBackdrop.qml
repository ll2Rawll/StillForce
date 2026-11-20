import QtQuick
import OpenNOW

Item {
    id: root
    objectName: root.signIn ? "signInBackdrop" : "desktopBackdrop"
    property string artwork: ShellStore.catalogGames.length
        ? DesktopTokens.artworkUrl(ShellStore.catalogGames[0], true) : ""
    property bool signIn: false
    readonly property string backgroundMode: String(ShellStore.settings.desktopBackground || "satin")
    readonly property bool satin: signIn || backgroundMode === "satin"
    readonly property bool customBackground: !root.signIn && ShellStore.settings.desktopBackground === "custom"
    readonly property string normalizedArtwork: root.artwork !== ""
        ? DesktopTokens.decodeArtworkUrl(root.artwork)
        : "qrc:/qt/qml/OpenNOW/res/brand/desktop-renew.jpg"

    ArtworkSource {
        id: artworkSource
        sourceUrl: root.normalizedArtwork
        active: root.visible && !root.satin && root.backgroundMode === "art"
    }

    Rectangle { anchors.fill: parent; color: root.signIn ? Theme.shell : DesktopTokens.shell }
    Image {
        anchors.fill: parent
        source: root.satin ? "qrc:/qt/qml/OpenNOW/res/brand/stillforce-satin.png" : ""
        sourceSize: Qt.size(1280, 720)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: Theme.lightMode ? 0.14 : 0.84
    }

    Item {
        anchors.fill: parent
        clip: true
        Image {
            id: art
            visible: !root.satin
            width: parent.width
            height: parent.height
            source: root.satin ? "" : artworkSource.resolvedUrl
            onStatusChanged: artworkSource.reportImageStatus(status, source)
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(1440, 900)
            opacity: status === Image.Ready && root.backgroundMode === "art" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: DesktopTokens.revealDuration } }
        }
    }

    Image {
        objectName: "customDesktopBackground"
        anchors.fill: parent
        source: root.visible && root.customBackground ? String(ShellStore.settings.desktopBackgroundImage || "") : ""
        sourceSize: Qt.size(1920, 1080)
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        opacity: status === Image.Ready ? Number(ShellStore.settings.desktopBackgroundOpacity ?? 30) / 100 : 0
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.signIn && !root.satin && !root.customBackground && root.backgroundMode !== "solid"
        // A gradient-only background must remain visible above the darkening
        // layers used for artwork. Solid mode has neither artwork nor tint.
        z: root.backgroundMode === "gradient" ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(Theme.focus.r,Theme.focus.g,Theme.focus.b,
                root.backgroundMode === "gradient" ? 0.22 : 0.07) }
            GradientStop { position: 0.4; color: "transparent" }
        }
    }
    Rectangle {
        visible: !root.signIn && !root.satin
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(Theme.shell.r, Theme.shell.g, Theme.shell.b, root.customBackground ? 0.82 : 0.92) }
            GradientStop { position: 0.34; color: Qt.rgba(Theme.shell.r, Theme.shell.g, Theme.shell.b, root.customBackground ? 0.12 : 0.78) }
            GradientStop { position: 1; color: Qt.rgba(Theme.shell.r, Theme.shell.g, Theme.shell.b, root.customBackground ? 0.24 : 0.94) }
        }
    }
    Rectangle {
        visible: !root.signIn && !root.satin
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#00000000" }
            GradientStop { position: 1; color: Qt.rgba(Theme.shell.r, Theme.shell.g, Theme.shell.b, root.customBackground ? 0.18 : 0.55) }
        }
    }
}
