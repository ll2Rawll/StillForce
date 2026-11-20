pragma ComponentBehavior: Bound

import QtQuick
import OpenNOW

FocusScope {
    id: root
    objectName: "desktopHomeScreen"
    anchors.fill: parent
    clip: true
    property bool active: true
    property string externalQuery: ""
    focus: active
    Accessible.role: Accessible.Pane
    Accessible.name: pageTitle
    readonly property string pageTitle: qsTr("Home")
    readonly property string pageSubtitle: ShellStore.catalogTotalCount ? qsTr("%1 games").arg(ShellStore.catalogTotalCount) : qsTr("Your library")
    signal routeRequested(string route)
    signal gameRequested(var game)
    signal playRequested(var game)

    readonly property var games: ShellStore.catalogGames || []
    readonly property bool catalogLoading: ShellStore.catalogInitialLoading
    readonly property var recentGames: {
        const played = []
        for (const game of games) {
            const time = game && game.lastPlayed ? Date.parse(String(game.lastPlayed)) : NaN
            if (Number.isFinite(time)) played.push({game, time})
        }
        return played.sort((a, b) => b.time - a.time).map(entry => entry.game)
    }
    readonly property var filters: [qsTr("All games"), qsTr("Recently played"), qsTr("Favourites"), qsTr("Recently added")]
    property int selectedFilter: 0
    readonly property var filteredGames: {
        switch (selectedFilter) {
        case 1: return recentGames
        case 2:
            const pins = new Set(ShellStore.settings.favoriteGameIds || [])
            return games.filter(game => pins.has(ShellStore.gameIdentity(game)))
        case 3: return games.slice(-12).reverse()
        default: return games
        }
    }
    readonly property string query: String(bar.query || externalQuery).trim().toLocaleLowerCase()
    readonly property var visibleGames: query ? filteredGames.filter(game => String(game.title || "").toLocaleLowerCase().includes(query)) : filteredGames
    property string selectedKey: ""
    readonly property int heroIndex: {
        if (!visibleGames.length) return -1
        const key = selectedKey || (recentGames.length ? ShellStore.gameIdentity(recentGames[0]) : "")
        const index = visibleGames.findIndex(game => ShellStore.gameIdentity(game) === key)
        return Math.max(0, index)
    }
    readonly property var heroGame: visibleGames[heroIndex] || null
    readonly property int heroActionCount: !heroGame ? 1 : visibleGames.length > 1 ? 4 : 2
    property double lastPlayedNowMs: Date.now()
    Timer {
        interval: 60000; repeat: true; triggeredOnStart: true
        running: root.active && root.visible && Boolean(root.heroGame && root.heroGame.lastPlayed) && Qt.application.state === Qt.ApplicationActive
        onTriggered: root.lastPlayedNowMs = Date.now()
    }
    FontLoader { id: displayFace; source: "qrc:/qt/qml/OpenNOW/res/fonts/InstrumentSerif-Regular.ttf" }
    readonly property string editorialFont: displayFace.status === FontLoader.Ready ? displayFace.name : Theme.displayFont
    readonly property bool stacked: width < DesktopTokens.px(615)
    readonly property int margin: Math.max(DesktopTokens.px(10), Math.min(DesktopTokens.px(47), Math.round(width * 0.028)))
    readonly property int stageWidth: stacked ? width : Math.round(width * (width > DesktopTokens.px(1210) ? 0.455 : 0.405))
    readonly property int railGap: Math.max(DesktopTokens.px(8), Math.min(DesktopTokens.px(15), Math.round(width * 0.009)))
    readonly property int railInnerWidth: Math.max(1, library.width - 2 * grid.gutter)
    readonly property int homeTileCount: Math.max(1, Math.min(6, Math.floor((railInnerWidth + railGap) / (DesktopTokens.px(stacked ? 103 : 142) + railGap))))
    readonly property int homeTileWidth: Math.max(1, Math.floor((railInnerWidth - railGap * (homeTileCount - 1)) / homeTileCount))
    readonly property int homeTileHeight: Math.round(homeTileWidth * 1.5)
    readonly property int stagger: homeTileCount < 2 ? 0 : Math.round(homeTileHeight * 0.18)
    property int focusZone: 0
    property int focusIndex: 0
    readonly property int rows: Math.ceil(visibleGames.length / homeTileCount)
    readonly property bool keyboardFocus: active && activeFocus && AppController.inputMode !== "pointer"
    onHomeTileCountChanged: clampSelection()
    onVisibleGamesChanged: { hoverPreview.stop(); clampSelection() }
    Timer {
        id: hoverPreview
        property string key: ""
        interval: 90
        onTriggered: if (root.active && !grid.moving) root.selectedKey = key
    }
    function showPreview(index, pointer) {
        const game = visibleGames[index]
        if (!game || (pointer && grid.moving)) return
        const key = ShellStore.gameIdentity(game)
        hoverPreview.stop()
        if (pointer) {
            hoverPreview.key = key
            hoverPreview.restart()
        } else selectedKey = key
    }
    function openSearch() { bar.openSearch() }
    function heroMeta() {
        const game = root.heroGame
        if (!game)
            return qsTr("Sign in and sync your library to continue a game.")
        const last = DesktopTokens.relativeLastPlayed(game.lastPlayed, root.lastPlayedNowMs)
        const hours = game.hoursPlayed ? qsTr("%1 h played").arg(game.hoursPlayed) : ""
        if (last !== "" && hours !== "")
            return last + " · " + hours
        if (last !== "")
            return last
        if (hours !== "")
            return hours
        return qsTr("Ready to stream from your library")
    }

    function streamChip() {
        const res = String(ShellStore.settings.resolution || "")
        const fps = Number(ShellStore.settings.fps || 0)
        const codec = String(ShellStore.settings.codec || "auto").toUpperCase()
        const parts = []
        if (res.indexOf("x") > 0)
            parts.push(res.split("x")[1] + "p")
        if (fps > 0)
            parts.push(fps + " fps")
        if (codec !== "")
            parts.push(codec)
        return parts.length ? parts.join(" · ") : qsTr("Stream ready")
    }

    function clampSelection() {
        if (focusZone > rows) focusZone = rows || -1
        focusIndex = Math.max(0, Math.min(focusIndex, zoneSize(focusZone) - 1))
    }
    function zoneSize(zone) {
        if (zone === 0) return heroActionCount
        if (zone < 0) return filters.length
        return Math.max(0, Math.min(homeTileCount, visibleGames.length - (zone - 1) * homeTileCount))
    }
    function reveal(index) {
        if (index < 0 || !grid) return
        grid.positionViewAtIndex(index, GridView.Contain)
        const bottom = grid.originY + Math.floor(index / homeTileCount) * grid.cellHeight + grid.gutter
            + (index % homeTileCount % 2 ? stagger : 0) + homeTileHeight + grid.gutter
        if (bottom > grid.contentY + grid.height)
            grid.contentY = Math.min(grid.originY + Math.max(0, grid.contentHeight - grid.height), bottom - grid.height)
    }
    function setSelection(zone, index, scroll = true) {
        focusZone = zone
        focusIndex = index
        clampSelection()
        if (focusZone <= 0) return
        const gameIndex = (focusZone - 1) * homeTileCount + focusIndex
        showPreview(gameIndex, !scroll)
        if (scroll) reveal(gameIndex)
    }
    function moveHorizontal(delta) { setSelection(focusZone, focusIndex + delta) }
    function moveVertical(delta) {
        if (focusZone === 0) { if (delta > 0) setSelection(-1, selectedFilter); return }
        if (focusZone === -1) { if (delta < 0) setSelection(0, 0); else if (rows) setSelection(1, 0); return }
        if (focusZone === 1 && delta < 0) setSelection(-1, selectedFilter)
        else setSelection(Math.max(1, Math.min(rows, focusZone + delta)), focusIndex)
    }
    function stepFeature(direction) {
        const count = visibleGames.length
        if (count < 2) return
        const next = (heroIndex + direction + count) % count
        showPreview(next, false)
        reveal(next)
    }
    function startHero() {
        if (!heroGame) { routeRequested("library"); return }
        if (ShellStore.signedIn) playRequested(heroGame)
        else AppController.navigate("sign-in")
    }
    function activateSelection() {
        if (focusZone === -1) { chooseFilter(focusIndex); return }
        if (focusZone === 0) {
            if (focusIndex === 0) startHero()
            else if (focusIndex === 1 && heroGame) gameRequested(heroGame)
            else stepFeature(focusIndex === 2 ? -1 : 1)
            return
        }
        const selected = visibleGames[(focusZone - 1) * homeTileCount + focusIndex]
        if (selected) gameRequested(selected)
    }
    property real galleryProgress: 1
    function chooseFilter(index) {
        if (index < 0 || index >= filters.length) return
        const changed = index !== selectedFilter
        if (changed) selectedKey = ""
        selectedFilter = index
        setSelection(-1, index)
        grid.positionViewAtBeginning()
        if (changed) {
            galleryEntrance.stop()
            galleryProgress = AppController.reducedMotion ? 1 : 0
            if (!AppController.reducedMotion) galleryEntrance.start()
        }
    }
    NumberAnimation { id: galleryEntrance; target: root; property: "galleryProgress"; to: 1; duration: 260; easing.type: Easing.OutCubic }
    Connections { target: AppController; function onReducedMotionChanged() { if (AppController.reducedMotion) { galleryEntrance.stop(); root.galleryProgress = 1 } } }
    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Left: moveHorizontal(-1); break
        case Qt.Key_Right: moveHorizontal(1); break
        case Qt.Key_Up: moveVertical(-1); break
        case Qt.Key_Down: moveVertical(1); break
        case Qt.Key_Space: case Qt.Key_Return: case Qt.Key_Enter: activateSelection(); break
        default: return
        }
        event.accepted = true
    }

    Rectangle { anchors.fill: parent; color: "#09090C" }
    DesktopHomeHero {
        id: feature
        width: root.stageWidth
        height: root.stacked ? Math.round(Math.min(parent.height * 0.34, DesktopTokens.px(225))) : parent.height
        horizontal: root.stacked
        game: root.heroGame; loading: root.catalogLoading; active: root.active
        metadata: root.heroMeta(); streamDescription: root.streamChip()
        position: root.heroIndex; count: root.visibleGames.length; editorialFont: root.editorialFont
        selection: root.keyboardFocus && root.focusZone === 0 ? root.focusIndex : -1
        onStep: direction => root.stepFeature(direction)
        onDetails: if (root.heroGame) root.gameRequested(root.heroGame)
        onPlay: root.startHero()
        onBrowse: root.routeRequested("library")
    }
    Item {
        id: library
        clip: true
        x: root.stacked ? root.margin : root.stageWidth + root.margin
        y: root.stacked ? feature.height : Math.min(DesktopTokens.px(32), root.height * 0.025)
        width: Math.max(1, parent.width - x - root.margin)
        height: Math.max(1, parent.height - y)
        DesktopHomeLibraryBar {
            id: bar
            x: grid.gutter; width: root.railInnerWidth
            compact: root.stacked || width < DesktopTokens.px(560) || root.height < DesktopTokens.px(600)
            count: root.visibleGames.length; selected: root.selectedFilter; filters: root.filters
            focused: root.keyboardFocus && root.focusZone === -1 ? root.focusIndex : -1
            editorialFont: root.editorialFont
            onFilterSelected: (index) => { root.chooseFilter(index); root.forceActiveFocus() }
            onOpenLibrary: root.routeRequested("library")
            onSearchClosed: root.forceActiveFocus()
        }
        GridView {
            id: grid; objectName: "homeGameGrid"
            readonly property int gutter: DesktopTokens.px(4)
            y: bar.height + DesktopTokens.px(root.stacked ? 1 : 4)
            width: root.homeTileCount * cellWidth + gutter
            height: Math.max(1, parent.height - y); clip: true
            cellWidth: root.homeTileWidth + root.railGap
            cellHeight: root.homeTileHeight + root.railGap
            keyNavigationEnabled: false; currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 4100; maximumFlickVelocity: 2400
            cacheBuffer: cellHeight
            model: root.catalogLoading ? new Array(root.homeTileCount * 3).fill(null) : root.visibleGames
            Accessible.name: qsTr("Your library")
            delegate: Item {
                id: cell
                required property int index
                required property var modelData
                width: grid.cellWidth; height: grid.cellHeight
                readonly property DesktopHomePoster card: poster.item as DesktopHomePoster
                z: card && card.highlighted ? 2 : 0
                opacity: 0.72 + 0.28 * root.galleryProgress
                transform: Translate { y: (1 - root.galleryProgress) * DesktopTokens.px(9) }
                Loader {
                    id: poster
                    x: grid.gutter; y: grid.gutter + (cell.index % root.homeTileCount % 2 ? root.stagger : 0)
                    width: root.homeTileWidth; height: root.homeTileHeight
                    sourceComponent: cell.modelData ? gameCard : placeholder
                }
                Component {
                    id: gameCard
                    DesktopHomePoster {
                        game: cell.modelData; tileWidth: root.homeTileWidth; tileHeight: root.homeTileHeight
                        featured: cell.index === root.heroIndex
                        current: root.keyboardFocus && root.focusZone === Math.floor(cell.index / root.homeTileCount) + 1 && root.focusIndex === cell.index % root.homeTileCount
                        onPointed: if (!grid.moving) root.setSelection(Math.floor(cell.index / root.homeTileCount) + 1, cell.index % root.homeTileCount, false)
                        onActivated: root.gameRequested(cell.modelData)
                        onPlayRequested: root.playRequested(cell.modelData)
                    }
                }
                Component { id: placeholder; DesktopPosterSkeleton { captionHeight: 0; cornerRadius: DesktopTokens.px(6) } }
            }
            footer: Item {
                width: grid.width; height: noGames.visible ? noGames.implicitHeight + DesktopTokens.px(40) : root.stagger + DesktopTokens.px(22)
                Column {
                    id: noGames; x: grid.gutter; y: DesktopTokens.px(18); width: parent.width - x * 2; spacing: DesktopTokens.px(12)
                    visible: !root.catalogLoading && root.visibleGames.length === 0
                    Text {
                        width: parent.width; wrapMode: Text.Wrap; textFormat: Text.PlainText
                        text: root.query ? qsTr("No games found") : root.selectedFilter === 2 ? qsTr("No favourites yet") : root.selectedFilter === 1 ? qsTr("No recently played games") : ShellStore.catalogError || qsTr("Your library is empty")
                        color: "#C3C3CB"; font.family: Theme.bodyFont; font.pixelSize: DesktopTokens.bodySize
                    }
                    DesktopButton { visible: !root.query && root.selectedFilter === 0; text: ShellStore.catalogError ? qsTr("Try again") : qsTr("Open library"); onClicked: ShellStore.catalogError ? ShellStore.refreshCatalog("") : root.routeRequested("library") }
                }
            }
        }
    }
    Component.onCompleted: {
        focusIndex = Math.max(0, Math.min(1, ShellStore.focusIndex("desktop-home")))
        if (active) Qt.callLater(root.forceActiveFocus)
    }
    onFocusIndexChanged: if (focusZone === 0) ShellStore.rememberFocus("desktop-home", focusIndex)
}
