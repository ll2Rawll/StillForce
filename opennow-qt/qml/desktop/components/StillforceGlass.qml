import QtQuick
import OpenNOW

Rectangle {
    id: panel
    property bool dense: false
    radius: DesktopTokens.px(24)
    color: Theme.shell
    border.width: 1
    border.color: Theme.lightMode ? "#3265748B" : "#40DCE5FA"
    gradient: Gradient {
        GradientStop { position: 0; color: Theme.lightMode ? "#F5F6F8FA" : (panel.dense ? "#FA2A2D36" : "#E72A2D36") }
        GradientStop { position: 0.25; color: Theme.lightMode ? "#F0E9ECF1" : (panel.dense ? "#FB191B22" : "#E4191B22") }
        GradientStop { position: 1; color: Theme.lightMode ? "#EBE2E6EC" : (panel.dense ? "#FB101117" : "#ED101117") }
    }
    Rectangle {
        x: panel.radius
        y: 1
        width: Math.max(0, parent.width - 2 * x)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.31; color: Theme.lightMode ? "#A6FFFFFF" : "#6CE4ECFF" }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
