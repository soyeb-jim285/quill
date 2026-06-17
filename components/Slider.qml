import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property string label: ""
    property bool showValue: false
    property int decimals: 0
    property color trackColor: Theme.primary
    property real displayValue: sliderMouse.dragging ? sliderMouse.dragValue : root.value
    signal moved(real value)
    spacing: Theme.spacingMd
    opacity: root.enabled ? 1.0 : 0.5
    Layout.fillWidth: true
    Accessible.role: Accessible.Slider
    Accessible.name: root.label
    Accessible.description: root.value.toString()
    Text {
        visible: root.label !== ""
        text: root.label
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        Layout.preferredWidth: 140
    }
    Item {
        Layout.fillWidth: true
        height: 24
        property real ratio: Math.max(0, Math.min(1, (root.displayValue - root.from) / (root.to - root.from)))
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 4; radius: 2
            color: Theme.surface1
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * parent.ratio
            height: 4; radius: 2
            color: root.trackColor
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width * parent.ratio - 7
            width: 14; height: 14; radius: 7
            color: sliderMouse.pressed ? Qt.lighter(root.trackColor, 1.2) : root.trackColor
            Behavior on color { ColorAnimation { duration: 80 } }
        }
        MouseArea {
            id: sliderMouse
            property bool dragging: false
            property real dragValue: root.value
            anchors.fill: parent
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: (event) => {
                if (root.enabled) {
                    dragging = true;
                    dragValue = root.value;
                    updateValue(event);
                }
            }
            onPositionChanged: (event) => { if (pressed && root.enabled) updateValue(event); }
            onReleased: dragging = false
            onCanceled: dragging = false
            function updateValue(event) {
                let r = Math.max(0, Math.min(1, event.x / width));
                let raw = root.from + r * (root.to - root.from);
                let step = root.stepSize;
                let val = Math.round(raw / step) * step;
                if (root.decimals > 0) val = parseFloat(val.toFixed(root.decimals));
                dragValue = val;
                root.moved(val);
            }
        }
    }
    Rectangle {
        visible: root.showValue
        width: 52; height: 24; radius: Theme.radiusSm
        color: Theme.surface0
        Text {
            anchors.centerIn: parent
            text: root.decimals > 0 ? root.displayValue.toFixed(root.decimals) : Math.round(root.displayValue)
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
        }
    }
}
