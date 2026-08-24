import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import ".."

Item {
    id: root
    property var model: []
    property int currentIndex: 0
    property string label: ""
    signal selected(int index, string value)
    implicitHeight: 34
    implicitWidth: 200
    Layout.fillWidth: true
    property bool dropdownOpen: false

    // Long lists get a filter box. Short ones do not need one, so this stays
    // automatic and call sites do not have to opt in.
    property bool searchable: (root.model ? root.model.length : 0) > 12
    // Font pickers render each entry in the family it names.
    property bool previewFont: false
    property string searchText: ""

    readonly property var _visibleModel: {
        const all = root.model ?? [];
        const needle = root.searchText.trim().toLowerCase();
        if (needle === "")
            return all;
        return all.filter(entry => String(entry).toLowerCase().indexOf(needle) >= 0);
    }

    Accessible.role: Accessible.ComboBox
    Accessible.name: root.label !== "" ? root.label : (root.model[root.currentIndex] ?? "")
    Accessible.description: root.model[root.currentIndex] ?? ""

    // The host window the dropdown lives in. Close the popup whenever the
    // host moves, resizes, or loses focus so the popup never detaches from
    // its anchor.
    readonly property var _hostWindow: root.Window.window
    Connections {
        target: root._hostWindow
        ignoreUnknownSignals: true
        function onXChanged() { root.dropdownOpen = false }
        function onYChanged() { root.dropdownOpen = false }
        function onWidthChanged() { root.dropdownOpen = false }
        function onHeightChanged() { root.dropdownOpen = false }
        function onActiveChanged() {
            if (root._hostWindow && !root._hostWindow.active)
                root.dropdownOpen = false
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        height: 34
        spacing: Theme.spacingMd
        Text {
            visible: root.label !== ""
            text: root.label
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            Layout.preferredWidth: 140
        }
        Rectangle {
            id: buttonRect
            Layout.fillWidth: true
            height: 34
            radius: Theme.radius
            color: Theme.surface0
            border.color: root.dropdownOpen ? Theme.primary : Theme.surface1
            border.width: 1
            opacity: root.enabled ? 1.0 : 0.5
            Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }
            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing
                anchors.rightMargin: Theme.spacing
                Text {
                    text: root.model[root.currentIndex] ?? ""
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - chevron.width
                    elide: Text.ElideRight
                }
                Text {
                    id: chevron
                    text: root.dropdownOpen ? "\uf077" : "\uf078"
                    color: Theme.textTertiary
                    font.family: Theme.iconFont
                    font.pixelSize: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (!root.enabled) return;
                    root.dropdownOpen = !root.dropdownOpen;
                }
            }
        }
    }

    // The popup is its own native Window. That avoids every class of
    // clipping / culling / z-order problem inside ancestor Flickables or
    // child Qt Windows (settings dialogs, frameless tool popups, etc.):
    // the compositor places it on top unconditionally. The earlier approach
    // of reparenting an Item to the window's contentItem was fragile — on
    // some hosts (notably a Qt.Dialog SettingsPanel) the popup children
    // got culled and the list never painted.
    Window {
        id: popupWindow
        flags: Qt.Popup | Qt.FramelessWindowHint | Qt.NoDropShadowWindowHint
        color: "transparent"
        transientParent: root._hostWindow ? root._hostWindow : null
        visible: root.dropdownOpen

        readonly property int _searchHeight: root.searchable ? 38 : 0
        width: buttonRect.width
        height: Math.min(root._visibleModel.length * 34 + 8, 300) + _searchHeight

        // Anchor to the button in global screen coords. The explicit
        // geometry reads register buttonRect's x/y/w/h as dependencies, so
        // the binding re-evaluates when the button moves or is resized —
        // mapToItem() alone isn't reactive to geometry.
        readonly property point _anchor: {
            if (!buttonRect) return Qt.point(0, 0);
            var _bx = buttonRect.x, _by = buttonRect.y;
            var _bw = buttonRect.width, _bh = buttonRect.height;
            var hx = root._hostWindow ? root._hostWindow.x : 0;
            var hy = root._hostWindow ? root._hostWindow.y : 0;
            var local = buttonRect.mapToItem(null, 0, _bh + 4);
            return Qt.point(hx + local.x, hy + local.y);
        }
        x: _anchor.x
        y: _anchor.y

        Rectangle {
            id: dropdownList
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.surface0
            border.color: Theme.surface1
            border.width: 1
            clip: true
            opacity: root.dropdownOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }

            // Filter field. Only built for long lists; short ones keep the
            // popup as compact as it was.
            Rectangle {
                id: searchRow
                visible: root.searchable
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 4
                height: visible ? 30 : 0
                radius: Theme.radiusSm
                color: Theme.surface1
                border.color: searchInput.activeFocus ? Theme.primary : "transparent"
                border.width: 1

                Text {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf002"
                    color: Theme.textTertiary
                    font.family: Theme.iconFont
                    font.pixelSize: 10
                }

                TextInput {
                    id: searchInput
                    anchors.left: searchIcon.right
                    anchors.leftMargin: Theme.spacing
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    selectByMouse: true
                    selectionColor: Theme.primary
                    clip: true
                    onTextChanged: root.searchText = text
                    Keys.onEscapePressed: {
                        if (text !== "")
                            text = "";
                        else
                            root.dropdownOpen = false;
                    }
                    Keys.onDownPressed: listView.incrementCurrentIndex()
                    Keys.onUpPressed: listView.decrementCurrentIndex()
                    Keys.onReturnPressed: root._commit(listView.currentIndex)

                    Text {
                        anchors.fill: parent
                        visible: searchInput.text === ""
                        verticalAlignment: Text.AlignVCenter
                        text: "Search\u2026"
                        color: Theme.textTertiary
                        font: searchInput.font
                    }
                }
            }

            ListView {
                id: listView
                anchors.top: root.searchable ? searchRow.bottom : parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 4
                model: root._visibleModel
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                highlightMoveDuration: 0

                // Nothing matched the filter — say so instead of showing an
                // empty box that reads as a broken popup.
                Text {
                    anchors.centerIn: parent
                    visible: listView.count === 0
                    text: "No matches"
                    color: Theme.textTertiary
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                }

                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    readonly property bool isCurrent: modelData === (root.model[root.currentIndex] ?? "")
                    width: listView.width
                    height: 30
                    radius: Theme.radiusSm
                    color: isCurrent
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                        : (itemMouse.containsMouse || index === listView.currentIndex) ? Theme.surface1 : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing
                        anchors.right: tick.left
                        anchors.rightMargin: Theme.spacing
                        text: modelData
                        elide: Text.ElideRight
                        color: parent.isCurrent ? Theme.primary : Theme.textPrimary
                        font.pixelSize: Theme.fontSize
                        // A font picker is far easier to use when each row is
                        // drawn in the family it names.
                        font.family: root.previewFont ? modelData : Theme.fontFamily
                    }

                    Text {
                        id: tick
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacing
                        visible: parent.isCurrent
                        text: "\uf00c"
                        color: Theme.primary
                        font.family: Theme.iconFont
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._commit(index)
                    }
                }
            }
        }

        // Qt.Popup normally auto-closes on outside click, but be explicit
        // so losing focus (Escape, Alt-Tab) also closes the popup.
        onActiveChanged: {
            if (!active)
                root.dropdownOpen = false
        }
    }

    // Rows are addressed by their position in the filtered list, so map back
    // to the caller's model index before reporting a selection.
    function _commit(visibleIndex) {
        const value = root._visibleModel[visibleIndex];
        if (value === undefined)
            return;
        const modelIndex = (root.model ?? []).indexOf(value);
        if (modelIndex >= 0)
            root.currentIndex = modelIndex;
        root.selected(modelIndex, value);
        root.dropdownOpen = false;
    }

    onDropdownOpenChanged: {
        if (dropdownOpen) {
            searchText = "";
            searchInput.text = "";
            // Start on the selected entry so the list opens where the user
            // left it rather than scrolled to the top.
            listView.currentIndex = Math.max(0, root._visibleModel.indexOf(root.model[root.currentIndex] ?? ""));
            listView.positionViewAtIndex(listView.currentIndex, ListView.Center);
            if (searchable)
                searchInput.forceActiveFocus();
            else
                forceActiveFocus();
        }
    }

    Keys.onEscapePressed: dropdownOpen = false
    Keys.onUpPressed: { if (dropdownOpen) listView.decrementCurrentIndex(); }
    Keys.onDownPressed: { if (dropdownOpen) listView.incrementCurrentIndex(); }
    Keys.onReturnPressed: { if (dropdownOpen) root._commit(listView.currentIndex); }
}
