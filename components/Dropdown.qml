import QtQuick
import QtQuick.Layouts
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
    Accessible.role: Accessible.ComboBox
    Accessible.name: root.label !== "" ? root.label : (root.model[root.currentIndex] ?? "")
    Accessible.description: root.model[root.currentIndex] ?? ""

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

    // Popup reparented to the window root so it's never clipped
    Item {
        id: dropdownPopup
        visible: root.dropdownOpen
        parent: root.Window.window ? root.Window.window.contentItem : root
        z: 10000

        // Click-outside overlay
        MouseArea {
            anchors.fill: parent
            onClicked: root.dropdownOpen = false
        }

        Rectangle {
            id: dropdownList
            x: _mappedPos.x
            y: _mappedPos.y
            width: buttonRect.width
            height: Math.min(root.model.length * 34, 200)
            radius: Theme.radius
            color: Theme.surface0
            border.color: Theme.surface1
            border.width: 1
            clip: true

            property point _mappedPos: {
                if (!root.dropdownOpen || !buttonRect) return Qt.point(0, 0);
                var globalPos = buttonRect.mapToItem(dropdownPopup.parent, 0, buttonRect.height + 4);
                return globalPos;
            }

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 4
                model: root.model
                currentIndex: root.currentIndex
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    width: listView.width
                    height: 30
                    radius: Theme.radiusSm
                    color: index === root.currentIndex
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                        : itemMouse.containsMouse ? Theme.surface1 : "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing
                        text: modelData
                        color: index === root.currentIndex ? Theme.primary : Theme.textPrimary
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentIndex = index;
                            root.selected(index, modelData);
                            root.dropdownOpen = false;
                        }
                    }
                }
            }
        }
    }

    onDropdownOpenChanged: { if (dropdownOpen) forceActiveFocus(); }
    Keys.onEscapePressed: dropdownOpen = false
    Keys.onUpPressed: { if (dropdownOpen && currentIndex > 0) currentIndex--; }
    Keys.onDownPressed: { if (dropdownOpen && currentIndex < model.length - 1) currentIndex++; }
    Keys.onReturnPressed: {
        if (dropdownOpen) {
            selected(currentIndex, model[currentIndex]);
            dropdownOpen = false;
        }
    }
}
