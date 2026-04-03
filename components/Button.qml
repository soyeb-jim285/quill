import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    property string text: ""
    property string icon: ""
    property string variant: "primary"
    property string size: "medium"
    property bool enabled: true
    signal clicked()
    activeFocusOnTab: enabled
    implicitWidth: contentRow.implicitWidth + (size === "small" ? 16 : size === "large" ? 32 : 24)
    implicitHeight: size === "small" ? 28 : size === "large" ? 40 : 34
    radius: Theme.radius
    border.width: activeFocus ? 2 : 0
    border.color: {
        if (variant === "danger")
            return Qt.lighter(Theme.error, 1.6)
        if (variant === "ghost")
            return Theme.textPrimary
        return Qt.lighter(Theme.primary, 1.5)
    }
    color: {
        if (!enabled) return Theme.surface0;
        let base;
        switch (variant) {
            case "primary": base = Theme.primary; break;
            case "secondary": base = Theme.surface1; break;
            case "ghost": base = "transparent"; break;
            case "danger": base = Theme.error; break;
            default: base = Theme.primary;
        }
        if (mouse.pressed && enabled) return Qt.darker(base, 1.2);
        if (activeFocus && enabled) {
            if (variant === "ghost") return Theme.surface1;
            if (variant === "danger") return Qt.lighter(base, 1.25);
            return Qt.lighter(base, 1.08);
        }
        if (mouse.containsMouse && enabled) {
            if (variant === "ghost") return Theme.surface0;
            return Qt.lighter(base, 1.15);
        }
        return base;
    }
    opacity: enabled ? 1.0 : 0.5
    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

    Accessible.role: Accessible.Button
    Accessible.name: root.text !== "" ? root.text : root.icon
    Accessible.description: root.text

    Keys.onPressed: (event) => {
        if (!root.enabled)
            return
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            event.accepted = true
            root.clicked()
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: root.text && root.icon ? 6 : 0
        Text {
            visible: root.icon !== ""
            text: root.icon
            color: {
                if (root.variant === "ghost" || root.variant === "secondary") return Theme.textPrimary;
                return Theme.backgroundDeep;
            }
            font.family: Theme.iconFont
            font.pixelSize: root.size === "small" ? 12 : root.size === "large" ? 16 : 14
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: root.text !== ""
            text: root.text
            color: {
                if (root.variant === "ghost" || root.variant === "secondary") return Theme.textPrimary;
                return Theme.backgroundDeep;
            }
            font.family: Theme.fontFamily
            font.pixelSize: root.size === "small" ? 11 : root.size === "large" ? 15 : 13
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: if (root.enabled) root.forceActiveFocus()
        onClicked: if (root.enabled) root.clicked()
    }
}
