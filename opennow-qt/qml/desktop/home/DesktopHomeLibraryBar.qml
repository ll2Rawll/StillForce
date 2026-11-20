pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import OpenNOW

Item {
    id: bar
    required property var filters
    required property int selected
    required property int focused
    required property int count
    required property string editorialFont
    required property bool compact
    property bool searching: false
    readonly property string query: search.text
    signal filterSelected(int index)
    signal openLibrary()
    signal searchClosed()
    function openSearch() { searching = true; search.forceActiveFocus(); search.selectAll() }
    function closeSearch() { search.clear(); searching = false; searchClosed() }
    implicitHeight: DesktopTokens.px(compact ? 60 : 120)

    Row {
        id: heading; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
        spacing: DesktopTokens.px(8); visible: !bar.searching
        Text {
            id: headingTitle; text: qsTr("Library"); color: "#F2F1ED"
            font.family: bar.editorialFont; font.pixelSize: DesktopTokens.px(bar.compact ? 38 : 66)
            font.letterSpacing: -DesktopTokens.px(bar.compact ? 38 : 66) * 0.032
        }
        Text {
            anchors.baseline: headingTitle.baseline; text: String(bar.count).padStart(2, "0")
            color: "#B4B5C0"; font.pixelSize: DesktopTokens.smallSize; font.family: Theme.monoFont
        }
    }
    TextMetrics { id: filterMeasure; font.family: Theme.bodyFont; font.pixelSize: DesktopTokens.captionSize; text: filter.text }
    Button {
        id: filter; objectName: "homeShelfPicker"
        anchors.right: lens.left; anchors.rightMargin: DesktopTokens.px(7); anchors.verticalCenter: parent.verticalCenter
        visible: !bar.searching
        width: Math.max(DesktopTokens.px(36), Math.min(filterMeasure.advanceWidth + DesktopTokens.px(33), bar.width - heading.width - lens.width - DesktopTokens.px(25)))
        height: DesktopTokens.px(36); leftPadding: 7; rightPadding: 7
        text: bar.filters[bar.focused >= 0 ? bar.focused : bar.selected]
        Accessible.name: qsTr("Filter library") + " · " + text
        onClicked: menu.open()
        background: Rectangle { radius: height / 2; color: filter.hovered || menu.opened ? "#22FFFFFF" : "transparent"; border.width: filter.visualFocus || bar.focused >= 0 ? 1 : 0; border.color: "#A4A6AF" }
        contentItem: Row {
            spacing: DesktopTokens.px(5)
            Text { width: Math.max(0, parent.width - marker.implicitWidth - parent.spacing); text: filter.text; elide: Text.ElideRight; color: "#D4D4DC"; font.family: Theme.bodyFont; font.pixelSize: DesktopTokens.captionSize; anchors.verticalCenter: parent.verticalCenter }
            Text { id: marker; text: "⌄"; color: "#C2C3CA"; font.pixelSize: DesktopTokens.px(15); anchors.verticalCenter: parent.verticalCenter }
        }
    }
    Button {
        id: lens; objectName: "homeSearch"
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: DesktopTokens.px(bar.compact ? 33 : 39); height: width; padding: 0
        Accessible.name: bar.searching ? qsTr("Close search") : qsTr("Search your library")
        onClicked: bar.searching ? bar.closeSearch() : bar.openSearch()
        background: Rectangle { radius: height / 2; color: lens.hovered ? "#32FFFFFF" : "#15151A"; border.width: 1; border.color: lens.visualFocus ? "white" : "#414148" }
        contentItem: Item {
            DesktopGlyph { anchors.centerIn: parent; width: DesktopTokens.px(14); height: width; icon: "desktop-search.svg"; visible: !bar.searching }
            Text { anchors.centerIn: parent; visible: bar.searching; text: "×"; color: "#EAEAF0"; font.pixelSize: DesktopTokens.px(21) }
        }
    }
    TextField {
        id: search; objectName: "homeGalleryQuery"
        visible: bar.searching; anchors.left: parent.left; anchors.right: lens.left; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
        height: DesktopTokens.px(40); leftPadding: 2; color: "#F2F2F6"; placeholderTextColor: "#9595A0"
        placeholderText: qsTr("Search your library"); font.family: Theme.bodyFont; font.pixelSize: DesktopTokens.bodySize
        background: Item { Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#83848E" } }
        Keys.onEscapePressed: bar.closeSearch()
    }
    Menu {
        id: menu; objectName: "homeGalleryMenu"; y: filter.y + filter.height + 3
        width: Math.min(bar.width, DesktopTokens.px(208)); x: Math.max(0, Math.min(bar.width - width, filter.x))
        padding: 5; modal: false
        background: Rectangle { radius: DesktopTokens.px(13); color: "#F51B1B21"; border.color: "#505059" }
        component Choice: MenuItem {
            id: choice
            property bool marked: false
            implicitHeight: DesktopTokens.px(34); leftPadding: DesktopTokens.px(15); rightPadding: DesktopTokens.px(12)
            contentItem: Text { text: choice.text; color: choice.marked || choice.highlighted ? "#FFFFFF" : "#CBCBD3"; font.family: Theme.bodyFont; font.pixelSize: DesktopTokens.captionSize; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { radius: DesktopTokens.px(8); color: choice.highlighted ? "#42434C" : choice.marked ? "#2D2E36" : "transparent" }
        }
        Instantiator {
            model: bar.filters
            delegate: Choice {
                required property int index
                required property string modelData
                text: modelData; marked: index === bar.selected
                onTriggered: bar.filterSelected(index)
            }
            onObjectAdded: (index, object) => menu.insertItem(index, object)
            onObjectRemoved: (index, object) => menu.removeItem(object)
        }
        MenuSeparator { contentItem: Rectangle { implicitHeight: 1; color: "#42424A" } }
        Choice { objectName: "desktopHomeIconGuide"; text: qsTr("What the icons mean"); onTriggered: AppController.showOverlay("desktop-icon-guide") }
        Choice { text: qsTr("Open library"); onTriggered: bar.openLibrary() }
    }
}
