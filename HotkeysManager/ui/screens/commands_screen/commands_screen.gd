class_name CommandsScreen extends Control

var _db: Database = null
var _programgroup_id: int = -1

@onready var command_grid: GridContainer = $VBoxContainer/ScrollContainer/VBoxContainer/CommandGrid


func setup(db: Database, programgroup_id: int) -> void:
    _db = db
    _programgroup_id = programgroup_id


func _ready() -> void:
    assert(_db.is_open())

    var programgroup_name: Variant = _db.select_value("programgroup", "id=%d" % _programgroup_id, "name")
    if programgroup_name != null:
        ($VBoxContainer/HBoxContainer/ProgramgroupTitleLabel as Label).text = programgroup_name

    var programs := query_programs(_programgroup_id)
    var commands := query_commands(_programgroup_id)
    var user_hotkey_by_commands := query_user_hotkey_by_commands(_programgroup_id)

    setup_command_grid(programs)
    add_header_row(programs)
    add_command_rows(programs, commands, user_hotkey_by_commands)


func query_programs(programgroup_id: int) -> Dictionary[int, String]:
    var programs: Dictionary[int, String] = {}
    var sql := "SELECT pp.program_id, p.name
FROM programgroup_program pp
INNER JOIN program p ON pp.program_id = p.id
WHERE pp.programgroup_id = ?;"

    if _db.select(sql, [programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var program_name: String = row["name"]
            programs[program_id] = program_name
    return programs


func query_commands(programgroup_id: int) -> Dictionary[int, Dictionary]:
    var sql := "SELECT pc.command_id, c.name AS command_name, pc.program_id, pc.id AS program_command_id, pc.name AS program_command_name, pch.hotkey AS program_hotkey
FROM program_command pc
INNER JOIN programgroup_program pp ON pc.program_id = pp.program_id AND pp.programgroup_id = ?
INNER JOIN program_command_hotkey pch ON pc.id = pch.program_command_id
INNER JOIN command c ON pc.command_id = c.id;"

    var commands: Dictionary[int, Dictionary] = {}

    if _db.select(sql, [programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var program_id: int = row["program_id"]
            var command_name: String = row["command_name"]
            var program_command_id: int = row["program_command_id"]
            var program_command_name: String = row["program_command_name"]
            var program_hotkey: String = row["program_hotkey"]

            if command_id not in commands:
                commands[command_id] = {"name": command_name, "program_commands": {}}

            var command_data: Dictionary = commands[command_id]
            var command_data_program_commands: Dictionary = command_data["program_commands"]

            if program_id not in command_data_program_commands:
                command_data_program_commands[program_id] = {"id": program_command_id, "name": program_command_name, "hotkeys": []}

            var command_data_program_commands_data: Dictionary = command_data_program_commands[program_id]
            var command_data_program_commands_hotkeys: Array = command_data_program_commands_data["hotkeys"]
            command_data_program_commands_hotkeys.append(program_hotkey)

    return commands


func query_user_hotkey_by_commands(programgroup_id: int) -> Dictionary[int, Dictionary]:
    var sql := "SELECT uh.id AS user_hotkey_id, uh.hotkey AS user_hotkey, uh.command_id, c.name AS command_name, p.id AS program_id, p.name AS program_name, uhp.program_id IS NOT NULL AS is_user_hotkey_assigned_to_program
FROM user_hotkey uh
INNER JOIN command c ON uh.command_id = c.id
INNER JOIN program_command pc ON c.id = pc.command_id
INNER JOIN program p ON pc.program_id = p.id
INNER JOIN programgroup_program pp ON p.id = pp.program_id AND pp.programgroup_id = ?
LEFT JOIN user_hotkey_program uhp ON uh.id = uhp.user_hotkey_id AND p.id = uhp.program_id;"

    var user_hotkey_by_commands: Dictionary[int, Dictionary] = {}

    if _db.select(sql, [programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var program_id: int = row["program_id"]
            var user_hotkey_id: int = row["user_hotkey_id"]
            var user_hotkey: String = row["user_hotkey"]
            var is_user_hotkey_assigned_to_program: bool = row["is_user_hotkey_assigned_to_program"] != 0

            if command_id not in user_hotkey_by_commands:
                user_hotkey_by_commands[command_id] = {"user_hotkey_id": user_hotkey_id, "user_hotkey": user_hotkey, "programs": []}

            var command_data: Dictionary = user_hotkey_by_commands[command_id]
            var programs: Array = command_data["programs"]

            if is_user_hotkey_assigned_to_program && program_id not in programs:
                programs.append(program_id)

    return user_hotkey_by_commands


func setup_command_grid(programs: Dictionary[int, String]) -> void:
    command_grid.columns = 1 + programs.size() + 1 + programs.size()


func add_command_grid_label(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.size_flags_vertical = Control.SIZE_FILL
    command_grid.add_child(label)
    return label


func add_command_grid_button(text: String) -> Button:
    var button := Button.new()
    button.text = text
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    command_grid.add_child(button)
    return button


func add_header_row(programs: Dictionary[int, String]) -> void:
    add_command_grid_label("Commands")

    for program_id: int in programs:
        add_command_grid_label(programs[program_id])

    add_command_grid_label("User Hotkey")

    for program_id: int in programs:
        add_command_grid_label("%d" % program_id)


func add_command_rows(programs: Dictionary[int, String], commands: Dictionary[int, Dictionary], user_hotkey_by_commands: Dictionary[int, Dictionary]) -> void:
    for command_id: int in commands:
        var command_data: Dictionary = commands[command_id]
        var command_data_program_commands: Dictionary = command_data["program_commands"]
        var command_name: String = command_data["name"]

        var button := add_command_grid_button(command_name)
        button.pressed.connect(_on_rename_command_button_pressed.bind(command_name, command_id))

        for program_id: int in programs.keys():
            var program_hotkeys_label := add_command_grid_button("")

            if program_id in command_data_program_commands:
                var command_data_program_commands_data: Dictionary = command_data_program_commands[program_id]
                var command_data_program_commands_hotkeys: Array = command_data_program_commands_data["hotkeys"]

                program_hotkeys_label.text = command_data_program_commands_data["name"]

                if !command_data_program_commands_hotkeys.is_empty():
                    program_hotkeys_label.text += ":\n" + "\n".join(command_data_program_commands_hotkeys)

        var user_hotkey := ""

        if command_id in user_hotkey_by_commands:
            var command_user_hotkey_data: Dictionary = user_hotkey_by_commands[command_id]
            user_hotkey = command_user_hotkey_data["user_hotkey"]

        add_command_grid_button(user_hotkey)

        for program_id: int in programs.keys():
            var user_hotkey_id: int = 0
            var s: String = "–"
            if command_id in user_hotkey_by_commands:
                var command_user_hotkey_data: Dictionary = user_hotkey_by_commands[command_id]
                user_hotkey_id = command_user_hotkey_data["user_hotkey_id"]
                s = "✔️" if program_id in command_user_hotkey_data["programs"] else "❌"
            var label := add_command_grid_label(s)
            if label.text != "–":
                label.mouse_filter = Control.MOUSE_FILTER_PASS
                label.gui_input.connect(_on_user_hotkey_program_checkbox_gui_input.bind(user_hotkey_id, program_id, label))


func _on_back_button_pressed() -> void:
    Events.switch_to_main_screen.emit()


func _on_quit_button_pressed() -> void:
    get_tree().quit()


func _on_new_command_button_pressed() -> void:
    ($NewCommandDialog as EnterTextDialog).show()


func _on_new_command_dialog_submitted(text: String) -> void:
    if _db.insert_row("command", {"name": text}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_rename_command_button_pressed(command_name: String, command_id: int) -> void:
    var rename_command_dialog: EnterTextDialog = $RenameCommandDialog
    rename_command_dialog.get_text_field().text = command_name
    rename_command_dialog.set_meta("command_id", command_id)
    rename_command_dialog.show()


func _on_rename_command_dialog_submitted(text: String) -> void:
    var rename_command_dialog: EnterTextDialog = $RenameCommandDialog
    var command_id: int = rename_command_dialog.get_meta("command_id")
    if _db.update_rows("command", "id=%d" % command_id, {"name": text}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_add_command_button_pressed() -> void:
    var sql := "SELECT c.id AS command_id, c.name AS command_name, pc.program_id, pc.name AS program_command_name, pp.programgroup_id
FROM command c
LEFT JOIN program_command pc ON c.id = pc.command_id
LEFT JOIN programgroup_program pp ON pc.program_id = pp.program_id AND pp.programgroup_id = ?
WHERE pc.command_id IS NULL
ORDER BY c.name;"

    if !_db.select(sql, [_programgroup_id]):
        return

    var add_command_dialog: AddCommandDialog = $AddCommandDialog
    var commands: Dictionary[int, String] = {}
    var rows := _db.query_result()

    for row: Dictionary in rows:
        var command_id: int = row["command_id"]
        var command_name: String = row["command_name"]
        commands[command_id] = command_name

    add_command_dialog.setup(query_programs(_programgroup_id), commands)
    add_command_dialog.show()


func _on_add_command_dialog_submitted(options: Dictionary[String, Variant]) -> void:
    var command_id: int = options["command"]
    for program_command: Dictionary[String, Variant] in options["program_commands"]:
        if _db.insert_row("program_command", {"command_id": command_id, "program_id": program_command["program_id"], "name": program_command["title"]}):
            var program_command_id := _db.last_insert_rowid()
            if !_db.insert_row("program_command_hotkey", {"program_command_id": program_command_id, "hotkey": program_command["hotkey"]}):
                return
    Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_user_hotkey_program_checkbox_gui_input(event: InputEvent, user_hotkey_id: int, program_id: int, label: Label) -> void:
    if event is InputEventMouseButton:
        var mouse_button_event: InputEventMouseButton = event
        if mouse_button_event.pressed && mouse_button_event.button_index == 1:
            if label.text == "✔️":
                _db.delete_rows("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [user_hotkey_id, program_id])
            elif label.text == "❌":
                _db.insert_row("user_hotkey_program", {"user_hotkey_id": user_hotkey_id, "program_id": program_id})
            Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)
