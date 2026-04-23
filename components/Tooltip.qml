import QtQuick
import QtQuick.Templates as T
import ".."

T.ToolTip {
    id: root

    delay: 500
    timeout: -1

    padding: Theme.spacing
    leftPadding: Theme.spacingMd
    rightPadding: Theme.spacingMd
    topPadding: Theme.spacing
    bottomPadding: Theme.spacing

    y: -implicitHeight - 6

    Accessible.role: Accessible.ToolTip
    Accessible.name: root.text

    contentItem: Text {
        text: root.text
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSizeSmall
        font.family: Theme.fontFamily
    }

    background: Rectangle {
        color: Theme.surface2
        radius: Theme.radiusSm
        border.width: 1
        border.color: Qt.rgba(Theme.textPrimary.r,
                              Theme.textPrimary.g,
                              Theme.textPrimary.b,
                              0.10)
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"
                              from: 0.0; to: 1.0
                              duration: 150; easing.type: Easing.OutQuad }
            NumberAnimation { property: "y"
                              from: root.y + 4; to: root.y
                              duration: 150; easing.type: Easing.OutQuad }
        }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"
                          from: 1.0; to: 0.0
                          duration: 100; easing.type: Easing.InQuad }
    }
}
