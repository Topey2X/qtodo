import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    
    Layout.preferredHeight: Kirigami.Units.gridUnit * 20 // About 300px
    Layout.preferredWidth: Kirigami.Units.gridUnit * 16  // About 240px
    Layout.minimumHeight: Kirigami.Units.gridUnit * 12   // About 200px
    Layout.minimumWidth: Kirigami.Units.gridUnit * 10     // About 160px

    // Model to store todo items
    ListModel {
        id: todoModel
    }
    
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    
    // Main layout
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing
        
        // ScrollView for todo items
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ListView {
                model: todoModel
                spacing: Kirigami.Units.smallSpacing
                clip: true
                
                delegate: Rectangle {
                    width: parent.width
                    height: todoRow.height
                    color: model.completed ? Qt.darker(Kirigami.Theme.backgroundColor, 1.1) : Kirigami.Theme.backgroundColor
                    radius: 4
                    border.color: model.completed ? 
                        Qt.darker(Kirigami.Theme.disabledTextColor, 1.1) : 
                        Kirigami.Theme.disabledTextColor
                    border.width: 1
                    opacity: model.completed ? 0.7 : 1.0

                    // Add a smooth transition
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: model.completed = !model.completed
                    }

                    RowLayout {
                        id: todoRow
                        width: parent.width - 10  // Add some padding from the borders
                        height: implicitHeight + Kirigami.Units.smallSpacing
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.smallSpacing
                    
                        // Checkbox
                        CheckBox {
                            checked: model.completed
                            enabled: false
                        }
                        
                        // Todo text
                        Label {
                            Layout.fillWidth: true
                            text: model.text
                            font.strikeout: model.completed
                            elide: Text.ElideRight
                        }
                        
                        // Delete button
                        PlasmaComponents.Button {
                            icon.name: "edit-delete"
                            onClicked: todoModel.remove(index)
                            flat: true
                        }
                    }
                }

                footer: ColumnLayout {
                    width: parent.width
                    spacing: 0
            
                    Item {
                        width: 1
                        height: Kirigami.Units.smallSpacing
                    }

                    PlasmaComponents.Button { // Add button
                        id: addButton
                        Layout.alignment: Qt.AlignHCenter
                        icon.name: "list-add"
                        text: ""
                        visible: !textInput.visible
                        onClicked: {
                            textInput.visible = true
                            textInput.forceActiveFocus()
                        }
                    }

                    TextField {
                        id: textInput
                        Layout.fillWidth: true
                        visible: false
                        placeholderText: "Enter todo item..."
                        
                        onAccepted: {
                            if (text.trim() !== "") {
                                todoModel.append({
                                    "text": text.trim(),
                                    "completed": false
                                })
                                text = ""
                                visible = false
                            }
                        }
                        
                        // Hide on focus loss
                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                visible = false
                                text = ""
                            }
                        }

                        Keys.onEscapePressed: {
                            visible = false
                            text = ""
                        }
                    }
                }
            }
        }       
    }
}