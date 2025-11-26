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
    prepare_actions_label()

    var programgroup_name: Variant = _db.select_value("programgroup", "name", "programgroup_id=?", [_programgroup_id])
    if programgroup_name != null:
        ($VBoxContainer/ProgramgroupTitleLabel as Label).text = programgroup_name

    var programs := query_programs(_db, _programgroup_id)
    var program_abbreviations := query_program_abbreviations(_db, _programgroup_id)
    var commands := query_commands(_db, _programgroup_id)
    var program_command_hotkeys := query_program_command_hotkeys(_db, _programgroup_id)
    var user_hotkeys_by_commands := query_user_hotkeys_by_commands(_db, _programgroup_id)
    var user_hotkeys_by_programs := query_user_hotkeys_by_programs(_db, _programgroup_id)
    var user_hotkey_programs := query_user_hotkey_programs(_db, _programgroup_id)

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

    var command_grid: CommandGrid = $VBoxContainer/ScrollContainer/CommandGrid
    command_grid.setup(_db, _programgroup_id, programs, program_abbreviations, combined_commands, program_command_hotkeys, user_hotkeys, user_hotkey_programs)


static func query_all_commands(db: Database) -> Dictionary[int, String]:
    var commands: Dictionary[int, String] = {}
    var rows: Variant = db.select_rows("command", ["command_id", "name"])
    if rows:
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var command_name: String = row["name"]
            commands[command_id] = command_name
    return commands


static func query_programs(db: Database, programgroup_id: int) -> Dictionary[int, String]:
    var programs: Dictionary[int, String] = {}
    var sql := "SELECT p.program_id, p.name AS program_name
FROM program p
INNER JOIN programgroup_program pp USING (program_id)
WHERE pp.programgroup_id = ?;"

    if db.select(sql, [programgroup_id]):
        var rows := db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var program_name: String = row["program_name"]
            programs[program_id] = program_name
    return programs


static func query_program_abbreviations(db: Database, programgroup_id: int) -> Dictionary[int, String]:
    var program_abbreviations: Dictionary[int, String] = {}
    var sql := "SELECT p.program_id, p.abbreviation
FROM program p
INNER JOIN programgroup_program pp USING (program_id)
WHERE pp.programgroup_id = ?;"

    if db.select(sql, [programgroup_id]):
        var rows := db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var program_abbr: String = row["abbreviation"]
            program_abbreviations[program_id] = program_abbr
    return program_abbreviations


static func query_commands(db: Database, programgroup_id: int) -> Dictionary[int, String]:
    var commands: Dictionary[int, String] = {}
    var sql := "SELECT c.command_id, c.name AS command_name
FROM command c
INNER JOIN program_command_hotkey pch USING (command_id)
INNER JOIN programgroup_program pp USING (program_id)
WHERE pp.programgroup_id = ?
GROUP BY c.command_id;"

    if db.select(sql, [programgroup_id]):
        var rows := db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var command_name: String = row["command_name"]
            commands[command_id] = command_name
    return commands


static func query_program_command_hotkeys(db: Database, programgroup_id: int) -> Dictionary[int, Dictionary]:
    var program_command_hotkeys: Dictionary[int, Dictionary] = {}
    var sql := "SELECT pch.program_id, pch.command_id, pch.hotkey AS program_command_hotkey
FROM program_command_hotkey pch
INNER JOIN programgroup_program pp USING (program_id)
WHERE pp.programgroup_id = ?;"

    if db.select(sql, [programgroup_id]):
        var rows := db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var command_id: int = row["command_id"]
            var program_command_hotkey: String = row["program_command_hotkey"]

            var command_data: Dictionary = program_command_hotkeys.get_or_add(command_id, {})
            var program_hotkeys: Array = command_data.get_or_add(program_id, [])
            program_hotkeys.append(program_command_hotkey)
    return program_command_hotkeys


static func query_user_hotkeys_by_commands(db: Database, programgroup_id: int) -> Dictionary[int, Dictionary]:
    var user_hotkeys_by_commands: Dictionary[int, Dictionary] = {}
    var sql := "SELECT uh.user_hotkey_id, uh.hotkey AS user_hotkey, uh.command_id, c.command_name
FROM user_hotkey uh
INNER JOIN (
	SELECT c.command_id, c.name AS command_name
	FROM command c
	INNER JOIN program_command_hotkey pch USING (command_id)
	INNER JOIN programgroup_program pp USING (program_id)
	WHERE pp.programgroup_id = ?
	GROUP BY c.command_id
) c USING (command_id);"

    if db.select(sql, [programgroup_id]):
        var rows := db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var command_name: String = row["command_name"]
            var user_hotkey_id: int = row["user_hotkey_id"]
            var user_hotkey: String = row["user_hotkey"]

            user_hotkeys_by_commands[command_id] = {"user_hotkey_id": user_hotkey_id, "user_hotkey": user_hotkey, "command_name": command_name}
    return user_hotkeys_by_commands


static func query_user_hotkeys_by_programs(db: Database, programgroup_id: int) -> Dictionary[int, Dictionary]:
    var user_hotkeys_by_programs: Dictionary[int, Dictionary] = {}
    var sql := "SELECT DISTINCT uh.user_hotkey_id, uh.hotkey AS user_hotkey, uh.command_id, c.name AS command_name
FROM user_hotkey uh
INNER JOIN user_hotkey_program uhp USING (user_hotkey_id)
INNER JOIN programgroup_program pp USING (program_id)
INNER JOIN command c USING (command_id)
WHERE pp.programgroup_id = ?;"

    if db.select(sql, [programgroup_id]):
        var rows := db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var command_name: String = row["command_name"]
            var user_hotkey_id: int = row["user_hotkey_id"]
            var user_hotkey: String = row["user_hotkey"]

            user_hotkeys_by_programs[command_id] = {"user_hotkey_id": user_hotkey_id, "user_hotkey": user_hotkey, "command_name": command_name}
    return user_hotkeys_by_programs


static func query_user_hotkey_programs(db: Database, programgroup_id: int) -> Dictionary[int, Dictionary]:
    var user_hotkey_programs: Dictionary[int, Dictionary] = {}
    var sql := "SELECT uhp.user_hotkey_id, uh.command_id, uhp.program_id
FROM user_hotkey uh
INNER JOIN user_hotkey_program uhp USING (user_hotkey_id)
INNER JOIN programgroup_program pp USING (program_id)
WHERE pp.programgroup_id = ?;"

    if db.select(sql, [programgroup_id]):
        var rows := db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var program_id: int = row["program_id"]
            var user_hotkey_id: int = row["user_hotkey_id"]

            if command_id not in user_hotkey_programs:
                user_hotkey_programs[command_id] = {"user_hotkey_id": user_hotkey_id, "hotkeys": []}

            var programs: Array = user_hotkey_programs[command_id]["hotkeys"]
            programs.append(program_id)
    return user_hotkey_programs


static func query_available_commands(db: Database, programgroup_id: int) -> Dictionary[int, String]:
    var commands: Dictionary[int, String] = {}
    var sql := "SELECT command_id, name AS command_name
FROM command
WHERE command_id NOT IN (
	SELECT pch.command_id
	FROM program_command_hotkey pch
	INNER JOIN programgroup_program pp USING (program_id)
	WHERE pp.programgroup_id = ?
	GROUP BY pch.command_id
)
ORDER BY name;"

    if db.select(sql, [programgroup_id]):
        var rows := db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var command_name: String = row["command_name"]
            commands[command_id] = command_name
    return commands


func prepare_actions_label() -> void:
    var lines: Array[String]
    for action in InputMap.get_actions():
        if !action.begins_with("ui_"):
            var parts: Array[String]
            for event in InputMap.action_get_events(action):
                var text := event.as_text()
                var pos := text.find(" (Physical)")
                if pos > 0:
                    text = text.substr(0, pos)
                parts.append(text)
            lines.append("%s: [code]%s[/code]" % [action.capitalize(), ", ".join(parts)])
    ($VBoxContainer/ActionsLabel as RichTextLabel).text = "\n".join(lines)

func _on_back_button_pressed() -> void:
    Events.switch_to_main_screen.emit()


func _on_quit_button_pressed() -> void:
    get_tree().quit()


func _on_new_command_button_pressed() -> void:
    EnterTextDialog.open_dialog(self, "New Command", "Enter the name of the new Command.", {"name": "Name"}, _on_new_command_dialog_submitted)


func _on_delete_command_button_pressed() -> void:
    SelectionDialog.open_dialog(self, "Delete Command", "Select the Commands that you want to delete.\n\nNote: This will completely delete the Commands and also all associated program and user Hotkeys!", _on_delete_command_dialog_submitted, query_all_commands(_db))


func _on_new_command_dialog_submitted(_dialog: EnterTextDialog, values: Dictionary[String, String]) -> void:
    if _db.insert_row("command", {"name": values["name"]}):
        Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_delete_command_dialog_submitted(_dialog: SelectionDialog, selection: Array) -> void:
    for id: Variant in selection:
        var command_id: int = id
        if !_db.delete_rows("command", "command_id=?", [command_id]):
            return
    Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)
