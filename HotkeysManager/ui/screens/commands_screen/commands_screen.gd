class_name CommandsScreen extends Control

var _db: Database = null
var _programgroup_id: int = -1


func setup(db: Database, programgroup_id: int) -> void:
    assert(db != null)
    assert(db.is_open())
    assert(programgroup_id > 0)

    _db = db
    _programgroup_id = programgroup_id


func _ready() -> void:
    var programgroup_name: Variant = _db.select_value("programgroup", "programgroup_id=%d" % _programgroup_id, "name")
    if programgroup_name != null:
        ($VBoxContainer/ProgramgroupTitleLabel as Label).text = programgroup_name

    var programs := query_programs()
    var program_abbreviations := query_program_abbreviations()
    var commands := query_commands()
    var program_commands := query_program_commands()
    var program_command_hotkeys := query_program_command_hotkeys()
    var user_hotkeys_by_commands := query_user_hotkeys_by_commands()
    var user_hotkeys_by_programs := query_user_hotkeys_by_programs()
    var user_hotkey_programs := query_user_hotkey_programs()

    var user_hotkeys: Dictionary[int, Dictionary] = {}
    for command_id in user_hotkeys_by_commands:
        user_hotkeys[command_id] = user_hotkeys_by_commands[command_id]
    for command_id in user_hotkeys_by_programs:
        user_hotkeys[command_id] = user_hotkeys_by_programs[command_id]

    var combined_commands: Dictionary[int, String] = {}
    for command_id in commands:
        combined_commands[command_id] = commands[command_id]
    for command_id in user_hotkeys_by_commands:
        combined_commands[command_id] = user_hotkeys_by_commands[command_id]["command_name"]
    for command_id in user_hotkeys_by_programs:
        combined_commands[command_id] = user_hotkeys_by_programs[command_id]["command_name"]

    var command_grid: CommandGrid = $VBoxContainer/ScrollContainer/VBoxContainer/CommandGrid
    command_grid.setup(_db, _programgroup_id, programs, program_abbreviations, combined_commands, program_commands, program_command_hotkeys, user_hotkeys, user_hotkey_programs)


func query_all_commands() -> Dictionary[int, String]:
    var commands: Dictionary[int, String] = {}
    var rows: Variant = _db.select_rows("command", "", ["command_id", "name"])
    if rows:
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var command_name: String = row["name"]
            commands[command_id] = command_name
    return commands


func query_programs() -> Dictionary[int, String]:
    var programs: Dictionary[int, String] = {}
    var sql := "SELECT p.program_id, p.name AS program_name
FROM program p
INNER JOIN programgroup_program pp USING (program_id)
WHERE pp.programgroup_id = ?;"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var program_name: String = row["program_name"]
            programs[program_id] = program_name
    return programs


func query_program_abbreviations() -> Dictionary[int, String]:
    var program_abbreviations: Dictionary[int, String] = {}
    var sql := "SELECT p.program_id, p.abbreviation
FROM program p
INNER JOIN programgroup_program pp USING (program_id)
WHERE pp.programgroup_id = ?;"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var program_abbr: String = row["abbreviation"]
            program_abbreviations[program_id] = program_abbr
    return program_abbreviations


func query_commands() -> Dictionary[int, String]:
    var commands: Dictionary[int, String] = {}
    var sql := "SELECT c.command_id, c.name AS command_name
FROM command c
INNER JOIN program_command pc USING (command_id)
INNER JOIN programgroup_program pp USING (program_id)
WHERE pp.programgroup_id = ?
GROUP BY c.command_id;"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var command_name: String = row["command_name"]
            commands[command_id] = command_name
    return commands


func query_program_commands() -> Dictionary[int, Dictionary]:
    var program_commands: Dictionary[int, Dictionary] = {}
    var sql := "SELECT pc.program_id, pc.command_id, pc.program_command_id, pc.name AS program_command_name
FROM program_command pc
INNER JOIN programgroup_program pp USING (program_id)
WHERE pp.programgroup_id = ?;"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var command_id: int = row["command_id"]
            var program_command_id: int = row["program_command_id"]
            var program_command_name: String = row["program_command_name"]

            var command_data: Dictionary = program_commands.get_or_add(command_id, {})
            command_data[program_id] = {"program_command_id": program_command_id, "program_command_name": program_command_name}
    return program_commands


func query_program_command_hotkeys() -> Dictionary[int, Dictionary]:
    var program_command_hotkeys: Dictionary[int, Dictionary] = {}
    var sql := "SELECT pc.program_id, pc.command_id, pch.hotkey AS program_command_hotkey
FROM program_command pc
INNER JOIN program_command_hotkey pch USING (program_command_id)
INNER JOIN programgroup_program pp USING (program_id)
WHERE pp.programgroup_id = ?;"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var command_id: int = row["command_id"]
            var program_command_hotkey: String = row["program_command_hotkey"]

            var command_data: Dictionary = program_command_hotkeys.get_or_add(command_id, {})
            var program_hotkeys: Array = command_data.get_or_add(program_id, [])
            program_hotkeys.append(program_command_hotkey)
    return program_command_hotkeys


func query_user_hotkeys_by_commands() -> Dictionary[int, Dictionary]:
    var user_hotkeys_by_commands: Dictionary[int, Dictionary] = {}
    var sql := "SELECT uh.user_hotkey_id, uh.hotkey AS user_hotkey, uh.command_id, c.command_name
FROM user_hotkey uh
INNER JOIN (
	SELECT c.command_id, c.name AS command_name
	FROM command c
	INNER JOIN program_command pc USING (command_id)
	INNER JOIN programgroup_program pp USING (program_id)
	WHERE pp.programgroup_id = ?
	GROUP BY c.command_id
) c USING (command_id);"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var command_name: String = row["command_name"]
            var user_hotkey_id: int = row["user_hotkey_id"]
            var user_hotkey: String = row["user_hotkey"]

            user_hotkeys_by_commands[command_id] = {"user_hotkey_id": user_hotkey_id, "user_hotkey": user_hotkey, "command_name": command_name}
    return user_hotkeys_by_commands


func query_user_hotkeys_by_programs() -> Dictionary[int, Dictionary]:
    var user_hotkeys_by_programs: Dictionary[int, Dictionary] = {}
    var sql := "SELECT DISTINCT uh.user_hotkey_id, uh.hotkey AS user_hotkey, uh.command_id, c.name AS command_name
FROM user_hotkey uh
INNER JOIN user_hotkey_program uhp USING (user_hotkey_id)
INNER JOIN programgroup_program pp USING (program_id)
INNER JOIN command c USING (command_id)
WHERE pp.programgroup_id = ?;"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var command_name: String = row["command_name"]
            var user_hotkey_id: int = row["user_hotkey_id"]
            var user_hotkey: String = row["user_hotkey"]

            user_hotkeys_by_programs[command_id] = {"user_hotkey_id": user_hotkey_id, "user_hotkey": user_hotkey, "command_name": command_name}
    return user_hotkeys_by_programs


func query_user_hotkey_programs() -> Dictionary[int, Dictionary]:
    var user_hotkey_programs: Dictionary[int, Dictionary] = {}
    var sql := "SELECT uhp.user_hotkey_id, uh.command_id, uhp.program_id
FROM user_hotkey uh
INNER JOIN user_hotkey_program uhp USING (user_hotkey_id)
INNER JOIN programgroup_program pp USING (program_id)
WHERE pp.programgroup_id = ?;"

    if _db.select(sql, [_programgroup_id]):
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


func query_available_commands() -> Dictionary[int, String]:
    var commands: Dictionary[int, String] = {}
    var sql := "SELECT command_id, name AS command_name
FROM command
WHERE command_id NOT IN (
    SELECT pc.command_id
    FROM program_command pc
    INNER JOIN programgroup_program pp USING (program_id)
    WHERE pp.programgroup_id = ?
    GROUP BY pc.command_id)
ORDER BY name;"

    if _db.select(sql, [_programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var command_name: String = row["command_name"]
            commands[command_id] = command_name
    return commands


func _on_back_button_pressed() -> void:
    Events.switch_to_main_screen.emit()


func _on_quit_button_pressed() -> void:
    get_tree().quit()


func _on_new_command_button_pressed() -> void:
    EnterTextDialog.open_dialog(self, "New Command", "Enter the name of the new Command.", _on_new_command_dialog_submitted)


func _on_delete_command_button_pressed() -> void:
    SelectionDialog.open_dialog(self, "Delete Command", "Select the Commands that you want to delete.\n\nNote: This will completely delete the Commands and also all associated program and user Hotkeys!", _on_delete_command_dialog_submitted, query_all_commands())


func _on_add_command_button_pressed() -> void:
    AddCommandDialog.open_dialog(self, "Select a Command and assign it to at least one Program.", _on_add_command_dialog_submitted, query_programs(), query_available_commands())


func _on_new_command_dialog_submitted(_dialog: EnterTextDialog, text: String) -> void:
    if _db.insert_row("command", {"name": text}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_delete_command_dialog_submitted(_dialog: SelectionDialog, selection: Array) -> void:
    for id: Variant in selection:
        var command_id: int = id
        if !_db.delete_rows("command", "command_id=%d" % command_id):
            return
    Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_add_command_dialog_submitted(_dialog: AddCommandDialog, options: Dictionary[String, Variant]) -> void:
    var command_id: int = options["command"]
    for program_command: Dictionary[String, Variant] in options["program_commands"]:
        if _db.insert_row("program_command", {"command_id": command_id, "program_id": program_command["program_id"], "name": program_command["title"]}):
            var program_command_id := _db.last_insert_rowid()
            if !_db.insert_row("program_command_hotkey", {"program_command_id": program_command_id, "hotkey": program_command["hotkey"]}):
                return
    Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)
