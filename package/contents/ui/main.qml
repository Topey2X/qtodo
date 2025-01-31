import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.LocalStorage 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    
    Layout.preferredHeight: Kirigami.Units.gridUnit * 20
    Layout.preferredWidth: Kirigami.Units.gridUnit * 16
    Layout.minimumHeight: Kirigami.Units.gridUnit * 12
    Layout.minimumWidth: Kirigami.Units.gridUnit * 10

    // Database handling
    property var db: null

    function initDatabase() {
        db = LocalStorage.openDatabaseSync("TodoDatabase", "1.0", "Todo Database", 1000000);
        db.transaction(function(tx) {
            // Create the table if it doesn't exist
            tx.executeSql('CREATE TABLE IF NOT EXISTS todos(id INTEGER PRIMARY KEY AUTOINCREMENT, 
                          text TEXT, comment TEXT, completed BOOLEAN)');
        });
    }

    function loadTodos() {
        if (!db) return;
        db.transaction(function(tx) {
            var results = tx.executeSql('SELECT * FROM todos ORDER BY id DESC');
            todoModel.clear();
            for (var i = 0; i < results.rows.length; i++) {
                todoModel.append({
                    text: results.rows.item(i).text,
                    comment: results.rows.item(i).comment,
                    completed: results.rows.item(i).completed === 1
                });
            }
        });
    }

    function saveTodo(text, comment, completed) {
        if (!db) return;
        db.transaction(function(tx) {
            tx.executeSql('INSERT INTO todos(text, comment, completed) VALUES(?, ?, ?)',
                         [text, comment, completed ? 1 : 0]);
        });
    }

    function updateTodoStatus(index, completed) {
        if (!db) return;
        db.transaction(function(tx) {
            // Get the corresponding database ID for the index
            var results = tx.executeSql('SELECT id FROM todos ORDER BY id DESC LIMIT 1 OFFSET ?', [index]);
            if (results.rows.length > 0) {
                var id = results.rows.item(0).id;
                tx.executeSql('UPDATE todos SET completed = ? WHERE id = ?', 
                             [completed ? 1 : 0, id]);
            }
        });
    }

    function deleteTodo(index) {
        if (!db) return;
        db.transaction(function(tx) {
            // Get the corresponding database ID for the index
            var results = tx.executeSql('SELECT id FROM todos ORDER BY id DESC LIMIT 1 OFFSET ?', [index]);
            if (results.rows.length > 0) {
                var id = results.rows.item(0).id;
                tx.executeSql('DELETE FROM todos WHERE id = ?', [id]);
            }
        });
    }

    Component.onCompleted: {
        initDatabase();
        loadTodos();
    }

    ListModel {
        id: todoModel
    }
    
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing
        
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ListView {
                model: todoModel
                spacing: Kirigami.Units.largeSpacing
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

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            model.completed = !model.completed;
                            updateTodoStatus(index, model.completed);
                        }
                    }

                    RowLayout {
                        id: todoRow
                        width: parent.width - 10
                        height: implicitHeight + Kirigami.Units.largeSpacing
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.largeSpacing
                    
                        CheckBox {
                            checked: model.completed
                            enabled: false
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            
                            Label {
                                Layout.fillWidth: true
                                text: model.text
                                font.strikeout: model.completed
                                elide: Text.ElideRight
                            }
                            
                            Label {
                                Layout.fillWidth: true
                                text: model.comment
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                                opacity: 0.7
                                visible: model.comment !== ""
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                            }
                        }
                        
                        PlasmaComponents.Button {
                            icon.name: "edit-delete"
                            onClicked: {
                                deleteTodo(index);
                                todoModel.remove(index);
                            }
                            flat: true
                        }
                    }
                }

                footer: ColumnLayout {
                    width: parent.width
                    spacing: 0
            
                    Item {
                        width: 1
                        height: Kirigami.Units.largeSpacing
                    }

                    Rectangle {
                        id: addButton
                        Layout.alignment: Qt.AlignHCenter
                        width: Kirigami.Units.gridUnit * 1.8
                        height: Kirigami.Units.gridUnit * 1.8
                        radius: 4
                        color: addMouseArea.containsMouse ? Qt.darker(Kirigami.Theme.backgroundColor, 1.1) : Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.disabledTextColor
                        border.width: 1
                        visible: !inputLayout.visible

                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: addMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                inputLayout.visible = true
                                textInput.forceActiveFocus()
                            }
                        }

                        Label {
                            anchors {
                                centerIn: parent
                                verticalCenterOffset: 0
                                horizontalCenterOffset: 0.5
                            }
                            text: "+"
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
                        }
                    }

                    ColumnLayout {
                        id: inputLayout
                        Layout.fillWidth: true
                        visible: false
                        spacing: Kirigami.Units.largeSpacing

                        TextField {
                            id: textInput
                            Layout.fillWidth: true
                            placeholderText: "Enter todo item..."
                            
                            onAccepted: {
                                if (text.trim() !== "") {
                                    commentInput.visible = true
                                    commentInput.forceActiveFocus()
                                }
                            }

                            Keys.onEscapePressed: {
                                inputLayout.visible = false
                                text = ""
                                commentInput.text = ""
                                commentInput.visible = false
                            }
                        }

                        TextArea {
                            id: commentInput
                            Layout.fillWidth: true
                            visible: false
                            placeholderText: "Add a comment (optional)..."
                            wrapMode: TextArea.Wrap
                            height: Math.min(implicitHeight, Kirigami.Units.gridUnit * 3)
                            
                            Keys.onReturnPressed: {
                                if (textInput.text.trim() !== "") {
                                    var todoText = textInput.text.trim();
                                    var todoComment = text.trim();
                                    
                                    // Save to database first
                                    saveTodo(todoText, todoComment, false);
                                    
                                    // Then update the model
                                    todoModel.append({
                                        "text": todoText,
                                        "comment": todoComment,
                                        "completed": false
                                    });
                                    
                                    textInput.text = ""
                                    text = ""
                                    inputLayout.visible = false
                                    visible = false
                                }
                            }

                            onActiveFocusChanged: {
                                if (!activeFocus && !textInput.activeFocus) {
                                    inputLayout.visible = false
                                    textInput.text = ""
                                    text = ""
                                    visible = false
                                }
                            }

                            Keys.onEscapePressed: {
                                inputLayout.visible = false
                                textInput.text = ""
                                text = ""
                                visible = false
                            }
                        }
                    }
                }
            }
        }       
    }
}