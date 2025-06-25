class_name CommandsScreen extends Control

const program_hotkeys_control_scene: PackedScene = preload("uid://dq4m5hd12nvxh")
const user_hotkey_control_scene: PackedScene = preload("uid://brad514ehxj7r")

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
    var program_commands := query_program_commands(_programgroup_id)
    var program_command_hotkeys := query_program_command_hotkeys(_programgroup_id)
    var user_hotkeys := query_user_hotkeys(_programgroup_id)
    var user_hotkey_programs := query_user_hotkey_programs(_programgroup_id)

    setup_command_grid(programs)
    add_header_row(programs)
    add_command_rows(programs, commands, program_commands, program_command_hotkeys, user_hotkeys, user_hotkey_programs)


func query_programs(programgroup_id: int) -> Dictionary[int, String]:
    var programs: Dictionary[int, String] = {}
    var sql := "SELECT p.id AS program_id, p.name AS program_name
FROM program p
INNER JOIN programgroup_program pp ON p.id = pp.program_id AND pp.programgroup_id = ?;"

    if _db.select(sql, [programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var program_name: String = row["program_name"]
            programs[program_id] = program_name
    return programs


func query_commands(programgroup_id: int) -> Dictionary[int, String]:
    var commands: Dictionary[int, String] = {}
    var sql := "SELECT c.id AS command_id, c.name AS command_name
FROM command c
INNER JOIN program_command pc ON c.id = pc.command_id
INNER JOIN programgroup_program pp ON pc.program_id = pp.program_id AND pp.programgroup_id = ?
GROUP BY c.id;"

    if _db.select(sql, [programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var command_name: String = row["command_name"]
            commands[command_id] = command_name
    return commands


func query_program_commands(programgroup_id: int) -> Dictionary[int, Dictionary]:
    var program_commands: Dictionary[int, Dictionary] = {}
    var sql := "SELECT pc.program_id, pc.command_id, pc.id AS program_command_id, pc.name AS program_command_name
FROM program_command pc
INNER JOIN programgroup_program pp ON pc.program_id = pp.program_id AND pp.programgroup_id = ?;"

    if _db.select(sql, [programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var command_id: int = row["command_id"]
            var program_command_id: int = row["program_command_id"]
            var program_command_name: String = row["program_command_name"]

            var command_data: Dictionary = program_commands.get_or_add(command_id, {})
            command_data[program_id] = {"program_command_id": program_command_id, "program_command_name": program_command_name}
    return program_commands


func query_program_command_hotkeys(programgroup_id: int) -> Dictionary[int, Dictionary]:
    var program_command_hotkeys: Dictionary[int, Dictionary] = {}
    var sql := "SELECT pc.program_id, pc.command_id, pch.id AS program_command_hotkey_id, pch.hotkey AS program_command_hotkey
FROM program_command pc
INNER JOIN program_command_hotkey pch ON pc.id = pch.program_command_id
INNER JOIN programgroup_program pp ON pc.program_id = pp.program_id AND pp.programgroup_id = ?;"

    if _db.select(sql, [programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var command_id: int = row["command_id"]
            var program_command_hotkey_id: int = row["program_command_hotkey_id"]
            var program_command_hotkey: String = row["program_command_hotkey"]

            var command_data: Dictionary = program_command_hotkeys.get_or_add(command_id, {})
            var program_data: Dictionary = command_data.get_or_add(program_id, {})
            program_data.get_or_add(program_command_hotkey_id, program_command_hotkey)
    return program_command_hotkeys


func query_user_hotkeys(programgroup_id: int) -> Dictionary[int, Dictionary]:
    var user_hotkeys: Dictionary[int, Dictionary] = {}
    var sql := "SELECT uh.command_id, uh.id AS user_hotkey_id, uh.hotkey AS user_hotkey
FROM user_hotkey uh
INNER JOIN (
	SELECT pc.command_id
	FROM program_command pc
	INNER JOIN programgroup_program pp ON pc.program_id = pp.program_id AND pp.programgroup_id = ?
	GROUP BY pc.command_id) c ON uh.command_id = c.command_id;"

    if _db.select(sql, [programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var user_hotkey_id: int = row["user_hotkey_id"]
            var user_hotkey: String = row["user_hotkey"]

            user_hotkeys[command_id] = {"user_hotkey_id": user_hotkey_id, "user_hotkey": user_hotkey}
    return user_hotkeys


func query_user_hotkey_programs(programgroup_id: int) -> Dictionary[int, Dictionary]:
    var user_hotkey_programs: Dictionary[int, Dictionary] = {}
    var sql := "SELECT uh.command_id, uhp.program_id, uhp.user_hotkey_id
FROM user_hotkey_program uhp
INNER JOIN user_hotkey uh ON uhp.user_hotkey_id = uh.id
INNER JOIN (
	SELECT pc.command_id
	FROM program_command pc
	INNER JOIN programgroup_program pp ON pc.program_id = pp.program_id AND pp.programgroup_id = ?
	GROUP BY pc.command_id) c ON uh.command_id = c.command_id;"

    if _db.select(sql, [programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var program_id: int = row["program_id"]
            var user_hotkey_id: int = row["user_hotkey_id"]

            if command_id not in user_hotkey_programs:
                user_hotkey_programs[command_id] = {"user_hotkey_id": user_hotkey_id, "hotkeys": []}

            var programs: Array = user_hotkey_programs[command_id]["hotkeys"]
            programs.append(program_id)
    return user_hotkey_programs


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


func add_command_grid_program_hotkeys_control(command_id: int, program_id: int, program_commands: Dictionary[int, Dictionary], program_command_hotkeys: Dictionary[int, Dictionary]) -> ProgramHotkeysControl:
    var control: ProgramHotkeysControl = program_hotkeys_control_scene.instantiate()
    control.setup(_db, _programgroup_id, command_id, program_id, program_commands, program_command_hotkeys)
    command_grid.add_child(control)
    return control


func add_command_grid_user_hotkey_control(command_id: int, user_hotkeys: Dictionary[int, Dictionary]) -> UserHotkeyControl:
    var control: UserHotkeyControl = user_hotkey_control_scene.instantiate()
    control.setup(_db, _programgroup_id, command_id, user_hotkeys)
    command_grid.add_child(control)
    return control


func add_header_row(programs: Dictionary[int, String]) -> void:
    add_command_grid_label("Commands")

    for program_id: int in programs:
        add_command_grid_label(programs[program_id])

    add_command_grid_label("User Hotkey")

    for program_id: int in programs:
        add_command_grid_label("%d" % program_id)


func add_command_rows(programs: Dictionary[int, String], commands: Dictionary[int, String], program_commands: Dictionary[int, Dictionary], program_command_hotkeys: Dictionary[int, Dictionary], user_hotkeys: Dictionary[int, Dictionary], user_hotkey_programs: Dictionary[int, Dictionary]) -> void:
    for command_id: int in commands:
        var command_name: String = commands[command_id]

        var button := add_command_grid_button(command_name)
        button.pressed.connect(_on_rename_command_button_pressed.bind(command_name, command_id))

        for program_id: int in programs:
            add_command_grid_program_hotkeys_control(command_id, program_id, program_commands, program_command_hotkeys)

        add_command_grid_user_hotkey_control(command_id, user_hotkeys)

        if command_id in user_hotkeys:
            var user_hotkey_id: int = user_hotkeys[command_id]["user_hotkey_id"]
            var hotkeys: Array = user_hotkey_programs[command_id].get("hotkeys") if command_id in user_hotkey_programs else []

            for program_id: int in programs:
                var s := "✔️" if program_id in hotkeys else "❌"
                var label := add_command_grid_label(s)
                label.mouse_filter = Control.MOUSE_FILTER_PASS
                label.gui_input.connect(_on_user_hotkey_program_checkbox_gui_input.bind(user_hotkey_id, program_id, label))
        else:
            for program_id: int in programs:
                add_command_grid_label("–")


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
