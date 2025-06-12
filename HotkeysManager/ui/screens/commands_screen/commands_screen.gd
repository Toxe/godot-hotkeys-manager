class_name CommandsScreen extends Control

var _db: Database = null
var _programgroup_id: int = -1

@onready var command_grid: GridContainer = $VBoxContainer/ScrollContainer/CommandGrid


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

    setup_command_grid(programs)
    add_header_row(programs)
    add_command_rows(programs, commands)


func query_programs(programgroup_id: int) -> Dictionary[int, String]:
    var programs: Dictionary[int, String] = {}
    var sql := "SELECT pp.program_id, p.name
FROM programgroup_program pp
INNER JOIN program p ON pp.program_id = p.id
WHERE pp.programgroup_id=?;"

    if _db.select(sql, [programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var program_id: int = row["program_id"]
            var program_name: String = row["name"]
            programs[program_id] = program_name
    return programs


func query_commands(programgroup_id: int) -> Dictionary[int, Dictionary]:
    var sql := "SELECT pc.command_id, c.name AS command_name, pc.program_id, pc.name AS program_command_name, pch.hotkey AS program_hotkey, uh.hotkey AS user_hotkey
FROM program_command pc
INNER JOIN programgroup_program pp ON pc.program_id = pp.program_id AND pp.programgroup_id = ?
INNER JOIN program_command_hotkey pch ON pc.id = pch.program_command_id
INNER JOIN command c ON pc.command_id = c.id
INNER JOIN user_hotkey uh ON pc.command_id = uh.command_id
ORDER BY pc.command_id, pc.program_id;"

    var commands: Dictionary[int, Dictionary] = {}

    if _db.select(sql, [programgroup_id]):
        var rows := _db.query_result()
        for row: Dictionary in rows:
            var command_id: int = row["command_id"]
            var program_id: int = row["program_id"]
            var command_name: String = row["command_name"]
            var program_command_name: String = row["program_command_name"]
            var program_hotkey: String = row["program_hotkey"]
            var user_hotkey: String = row["user_hotkey"]

            if command_id not in commands:
                commands[command_id] = {"name": command_name, "program_commands": {}, "user_hotkey": user_hotkey}

            var command_data: Dictionary = commands[command_id]
            var command_data_program_commands: Dictionary = command_data["program_commands"]

            if program_id not in command_data_program_commands:
                command_data_program_commands[program_id] = {"name": program_command_name, "hotkeys": []}

            var command_data_program_commands_data: Dictionary = command_data_program_commands[program_id]
            var command_data_program_commands_hotkeys: Array = command_data_program_commands_data["hotkeys"]
            command_data_program_commands_hotkeys.append(program_hotkey)

    return commands


func setup_command_grid(programs: Dictionary[int, String]) -> void:
    command_grid.columns = 1 + programs.size() + 1 + programs.size()


func add_command_grid_label(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.size_flags_vertical = Control.SIZE_FILL
    command_grid.add_child(label)
    return label


func add_header_row(programs: Dictionary[int, String]) -> void:
    add_command_grid_label("Commands")

    for program_id: int in programs:
        add_command_grid_label(programs[program_id])

    add_command_grid_label("User Hotkey")

    for program_id: int in programs:
        add_command_grid_label("%d" % program_id)


func add_command_rows(programs: Dictionary[int, String], commands: Dictionary) -> void:
    for command_id: int in commands:
        var command_data: Dictionary = commands[command_id]
        var command_data_program_commands: Dictionary = command_data["program_commands"]
        var command_name: String = command_data["name"]
        var user_hotkey: String = command_data["user_hotkey"]

        add_command_grid_label(command_name)

        for program_id: int in programs.keys():
            var command_data_program_commands_data: Dictionary = command_data_program_commands[program_id]
            var command_data_program_commands_hotkeys: Array = command_data_program_commands_data["hotkeys"]
            var program_hotkeys_label := add_command_grid_label("")

            if !command_data_program_commands_hotkeys.is_empty():
                program_hotkeys_label.text = "\n".join(command_data_program_commands_hotkeys)

        add_command_grid_label(user_hotkey)

        for program_id: int in programs.keys():
            add_command_grid_label("-")


func _on_back_button_pressed() -> void:
    Events.switch_to_main_screen.emit()
