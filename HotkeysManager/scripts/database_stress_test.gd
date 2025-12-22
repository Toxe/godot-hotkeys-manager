class_name DatabaseStressTest extends Node


static func generate_data(db: Database, num_programs: int, num_programgroups: int, num_commands: int, random_seed: int) -> void:
    seed(random_seed)

    var programs: Array
    var programgroups: Array
    var commands: Array

    # programs
    var values: Array = range(num_programs).map(func(i: int) -> Dictionary: return {"name": "Program %d" % (i + 1), "abbreviation": "Prg%d" % (i + 1)})
    values.shuffle()

    if db.insert_rows("program", values):
        if db.select("SELECT program_id FROM program ORDER BY program_id DESC LIMIT ?;", [num_programs]):
            programs = db.query_result().map(func(row: Dictionary) -> int: return row["program_id"])

    # program icons
    var existing_program_icons: Array

    if db.select("SELECT DISTINCT icon FROM program_icon;"):
        existing_program_icons = db.query_result().map(func(row: Dictionary) -> PackedByteArray: return row["icon"])

    existing_program_icons.append(null)
    values = []

    for program_id: int in programs:
        var icon: Variant = existing_program_icons.pick_random()
        if icon:
            values.append({"program_id": program_id, "icon": icon})

    values.shuffle()

    if !values.is_empty():
        db.insert_rows("program_icon", values)

    # programgroups
    values = range(num_programgroups).map(func(i: int) -> Dictionary: return {"name": "Programgroup %d" % (i + 1)})
    values.shuffle()

    if db.insert_rows("programgroup", values):
        if db.select("SELECT programgroup_id FROM programgroup ORDER BY programgroup_id DESC LIMIT ?;", [num_programgroups]):
            programgroups = db.query_result().map(func(row: Dictionary) -> int: return row["programgroup_id"])

    # commands
    values = range(num_commands).map(func(i: int) -> Dictionary: return {"name": "Command %d" % (i + 1)})
    values.shuffle()

    if db.insert_rows("command", values):
        if db.select("SELECT command_id FROM command ORDER BY command_id DESC LIMIT ?;", [num_commands]):
            commands = db.query_result().map(func(row: Dictionary) -> int: return row["command_id"])

    assert(programs.size() == num_programs)
    assert(programgroups.size() == num_programgroups)
    assert(commands.size() == num_commands)

    # add programs to programgroups
    for programgroup_id: int in programgroups:
        values = programs.map(func(program_id: int) -> Dictionary: return {"programgroup_id": programgroup_id, "program_id": program_id})
        values.shuffle()
        db.insert_rows("programgroup_program", values)

    # add program command hotkeys and user hotkeys
    var user_hotkeys: Array[Dictionary]
    values = []

    for command_id: int in commands:
        var command_hotkeys: Array[String]
        for program_id: int in programs:
            var hotkeys: Array[String]
            for i in randi_range(0, 3):
                var c := char(randi_range(ord("A"), ord("Z")))
                var parts: Array[String]
                if randi() % 2 == 1: parts.append("Ctrl")
                if randi() % 2 == 1: parts.append("Shift")
                if randi() % 2 == 1: parts.append("Alt")
                parts.append(c)
                var hotkey := "+".join(parts)
                if hotkey not in hotkeys:
                    hotkeys.append(hotkey)
            for hotkey in hotkeys:
                values.append({"program_id": program_id, "command_id": command_id, "hotkey": hotkey})
                command_hotkeys.append(hotkey)
        if !command_hotkeys.is_empty():
            user_hotkeys.append({"command_id": command_id, "hotkey": command_hotkeys.pick_random()})

    values.shuffle()
    user_hotkeys.shuffle()
    db.insert_rows("program_command_hotkey", values)
    db.insert_rows("user_hotkey", user_hotkeys)

    # user hotkey programs
    var user_hotkey_ids: Array

    if db.select("SELECT user_hotkey_id FROM user_hotkey ORDER BY user_hotkey_id DESC LIMIT ?;", [user_hotkeys.size()]):
        user_hotkey_ids = db.query_result().map(func(row: Dictionary) -> int: return row["user_hotkey_id"])

    assert(user_hotkey_ids.size() == user_hotkeys.size())
    values = []

    for user_hotkey_id: int in user_hotkey_ids:
        var program_ids := programs.duplicate()
        program_ids.shuffle()
        @warning_ignore("integer_division")
        program_ids.resize(randi_range(roundi(programs.size() / 2), programs.size()))
        for program_id: int in program_ids:
            values.append({"user_hotkey_id": user_hotkey_id, "program_id": program_id})

    values.shuffle()
    db.insert_rows("user_hotkey_program", values)
