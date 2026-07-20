import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

ApplicationWindow {
    id: root
    width: 420
    height: 640
    minimumWidth: 380
    minimumHeight: 580
    visible: true
    title: "WageTick"
    color: "#0b0f1a"

    // ── Animated gradient backdrop ──────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0b0f1a" }
            GradientStop { position: 0.55; color: "#121a2e" }
            GradientStop { position: 1.0; color: "#0d1525" }
        }
    }

    // Soft floating orbs (give depth behind glass)
    Item {
        id: ambience
        anchors.fill: parent
        clip: true

        Rectangle {
            id: orb1
            width: 280; height: 280; radius: 140
            x: -60; y: -40
            color: "#5b6cff"
            opacity: 0.28
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 64
            }

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: 40; duration: 9000; easing.type: Easing.InOutSine }
                NumberAnimation { to: -60; duration: 9000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: 80; duration: 11000; easing.type: Easing.InOutSine }
                NumberAnimation { to: -40; duration: 11000; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            id: orb2
            width: 240; height: 240; radius: 120
            x: ambience.width - 160; y: ambience.height - 260
            color: "#c44dff"
            opacity: 0.22
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 64
            }

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: ambience.width - 280; duration: 10000; easing.type: Easing.InOutSine }
                NumberAnimation { to: ambience.width - 160; duration: 10000; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            id: orb3
            width: 180; height: 180; radius: 90
            x: ambience.width * 0.35; y: ambience.height * 0.42
            color: "#2ec5ff"
            opacity: 0.16
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 48
            }

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: ambience.height * 0.55; duration: 8000; easing.type: Easing.InOutSine }
                NumberAnimation { to: ambience.height * 0.42; duration: 8000; easing.type: Easing.InOutSine }
            }
        }
    }

    // ── Main content ────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 18

        // Header
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "WageTick"
                color: "#ffffff"
                font.pixelSize: 28
                font.weight: Font.DemiBold
                font.letterSpacing: 0.5
            }
            Text {
                text: "Watch your earnings tick up — every second."
                color: "#9aa3b8"
                font.pixelSize: 13
            }
        }

        // ── Glass: Rate & currency ──────────────────────────────────────────
        GlassCard {
            Layout.fillWidth: true
            Layout.preferredHeight: rateColumn.implicitHeight + 36

            ColumnLayout {
                id: rateColumn
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Text {
                    text: "HOURLY RATE"
                    color: "#8b93a7"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.letterSpacing: 1.2
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Currency pills
                    CurrencyPill {
                        code: "USD"
                        symbol: "$"
                        selected: wageTimer.currency === "USD"
                        onClicked: wageTimer.currency = "USD"
                    }
                    CurrencyPill {
                        code: "EUR"
                        symbol: "€"
                        selected: wageTimer.currency === "EUR"
                        onClicked: wageTimer.currency = "EUR"
                    }
                    CurrencyPill {
                        code: "GBP"
                        symbol: "£"
                        selected: wageTimer.currency === "GBP"
                        onClicked: wageTimer.currency = "GBP"
                    }

                    Item { Layout.fillWidth: true }
                }

                // Rate input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 14
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.color: rateField.activeFocus
                                  ? Qt.rgba(0.45, 0.55, 1.0, 0.55)
                                  : Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 8

                        Text {
                            text: wageTimer.currencySymbol
                            color: "#c8cfe0"
                            font.pixelSize: 20
                            font.weight: Font.Medium
                        }

                        TextField {
                            id: rateField
                            Layout.fillWidth: true
                            text: wageTimer.hourlyRate.toFixed(2)
                            color: "#ffffff"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            placeholderText: "0.00"
                            placeholderTextColor: "#5a6278"
                            selectByMouse: true
                            enabled: !wageTimer.running
                            background: Item {}
                            validator: DoubleValidator {
                                bottom: 0
                                top: 1000000
                                decimals: 2
                                notation: DoubleValidator.StandardNotation
                            }
                            onEditingFinished: {
                                const v = parseFloat(text)
                                if (!isNaN(v)) {
                                    wageTimer.hourlyRate = v
                                    text = wageTimer.hourlyRate.toFixed(2)
                                } else {
                                    text = wageTimer.hourlyRate.toFixed(2)
                                }
                            }
                            Keys.onReturnPressed: editingFinished()
                            Keys.onEnterPressed: editingFinished()
                        }

                        Text {
                            text: "/ hr"
                            color: "#7a8298"
                            font.pixelSize: 14
                        }
                    }
                }

                Text {
                    text: wageTimer.formattedPerSecond + "  ·  live accrual"
                    color: "#6d758c"
                    font.pixelSize: 12
                }
            }
        }

        // ── Glass: Earnings display ─────────────────────────────────────────
        GlassCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 220

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "EARNED"
                        color: "#8b93a7"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.letterSpacing: 1.2
                    }
                    Item { Layout.fillWidth: true }
                    // Status chip
                    Rectangle {
                        radius: 10
                        color: wageTimer.running
                               ? Qt.rgba(0.2, 0.85, 0.55, 0.15)
                               : Qt.rgba(1, 1, 1, 0.06)
                        border.color: wageTimer.running
                                      ? Qt.rgba(0.3, 0.95, 0.6, 0.35)
                                      : Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                        implicitWidth: statusRow.implicitWidth + 16
                        implicitHeight: 24

                        Row {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                width: 7; height: 7; radius: 3.5
                                anchors.verticalCenter: parent.verticalCenter
                                color: wageTimer.running ? "#3dff9a" : "#6a7288"

                                SequentialAnimation on opacity {
                                    running: wageTimer.running
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.35; duration: 700 }
                                    NumberAnimation { to: 1.0; duration: 700 }
                                }
                            }
                            Text {
                                text: wageTimer.statusText
                                color: wageTimer.running ? "#9bffc9" : "#9aa3b8"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Big money number
                Text {
                    id: earnedLabel
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: wageTimer.formattedEarned
                    color: "#ffffff"
                    font.pixelSize: 48
                    font.weight: Font.Bold
                    font.letterSpacing: -0.5
                    elide: Text.ElideRight

                    // Subtle pulse when earning
                    scale: 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                    }
                }

                // Tick flash when seconds change
                Connections {
                    target: wageTimer
                    function onTick() {
                        // only pulse on whole-second boundaries while running
                        if (wageTimer.running && wageTimer.elapsedSeconds >= 0) {
                            // no-op visual handled by continuous update
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Elapsed  " + wageTimer.formattedElapsed
                    color: "#8b93a7"
                    font.pixelSize: 15
                    font.family: "Menlo"
                }

                Item { Layout.fillHeight: true }

                // Mini stats row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    MiniStat {
                        Layout.fillWidth: true
                        label: "Per second"
                        value: wageTimer.currencySymbol + wageTimer.perSecond.toFixed(5)
                    }
                    MiniStat {
                        Layout.fillWidth: true
                        label: "Per minute"
                        value: wageTimer.currencySymbol + (wageTimer.hourlyRate / 60.0).toFixed(3)
                    }
                }
            }
        }

        // ── Controls ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Start / Stop
            GlassButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                primary: true
                accent: wageTimer.running ? "#ff5c7a" : "#5b8cff"
                label: wageTimer.running ? "Stop" : "Start"
                enabled: wageTimer.running || wageTimer.hourlyRate > 0
                onClicked: wageTimer.toggle()
            }

            // Reset
            GlassButton {
                Layout.preferredWidth: 110
                Layout.preferredHeight: 54
                primary: false
                accent: "#ffffff"
                label: "Reset"
                enabled: wageTimer.elapsedSeconds > 0 || wageTimer.running
                onClicked: wageTimer.reset()
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "Rate is locked while the timer runs"
            color: "#4e566c"
            font.pixelSize: 11
            opacity: wageTimer.running ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // ── Reusable components ─────────────────────────────────────────────────
    component GlassCard: Item {
        id: card
        default property alias contentData: body.data

        // Soft shadow
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            radius: 22
            color: Qt.rgba(0, 0, 0, 0.35)
            opacity: 0.5
        }

        // Glass body
        Rectangle {
            id: glass
            anchors.fill: parent
            radius: 22
            color: Qt.rgba(1, 1, 1, 0.07)
            border.color: Qt.rgba(1, 1, 1, 0.16)
            border.width: 1

            // Top highlight edge
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 1
                height: parent.height * 0.45
                radius: 22
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }
        }

        Item {
            id: body
            anchors.fill: parent
        }
    }

    component CurrencyPill: Rectangle {
        id: pill
        property string code
        property string symbol
        property bool selected: false
        signal clicked()

        implicitWidth: pillRow.implicitWidth + 20
        implicitHeight: 34
        radius: 17
        color: selected ? Qt.rgba(0.36, 0.48, 1.0, 0.28) : Qt.rgba(1, 1, 1, 0.05)
        border.color: selected ? Qt.rgba(0.45, 0.55, 1.0, 0.55) : Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 5
            Text {
                text: pill.symbol
                color: selected ? "#dce3ff" : "#9aa3b8"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Text {
                text: pill.code
                color: selected ? "#ffffff" : "#9aa3b8"
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    component MiniStat: Rectangle {
        property string label
        property string value

        radius: 12
        color: Qt.rgba(1, 1, 1, 0.04)
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        implicitHeight: 54

        Column {
            anchors.centerIn: parent
            spacing: 3
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: label
                color: "#6d758c"
                font.pixelSize: 10
                font.letterSpacing: 0.6
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: value
                color: "#d0d6e4"
                font.pixelSize: 13
                font.weight: Font.Medium
                font.family: "Menlo"
            }
        }
    }

    component GlassButton: Rectangle {
        id: btn
        property string label
        property bool primary: true
        property color accent: "#5b8cff"
        signal clicked()

        radius: 16
        opacity: enabled ? 1.0 : 0.4

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: primary
                       ? Qt.rgba(accent.r, accent.g, accent.b, 0.85)
                       : Qt.rgba(1, 1, 1, 0.08)
            }
            GradientStop {
                position: 1.0
                color: primary
                       ? Qt.rgba(accent.r * 0.75, accent.g * 0.75, accent.b * 0.95, 0.9)
                       : Qt.rgba(1, 1, 1, 0.05)
            }
        }

        border.color: primary
                      ? Qt.rgba(1, 1, 1, 0.22)
                      : Qt.rgba(1, 1, 1, 0.14)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: btn.label
            color: "#ffffff"
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }

        // Shine
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: parent.height * 0.45
            radius: 16
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, primary ? 0.18 : 0.08) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPressed: btn.scale = 0.97
            onReleased: btn.scale = 1.0
            onCanceled: btn.scale = 1.0
            onClicked: btn.clicked()
        }

        Behavior on scale { NumberAnimation { duration: 80 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        scale: 1.0
    }
}
