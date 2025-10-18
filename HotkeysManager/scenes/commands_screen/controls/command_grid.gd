class_name CommandGrid extends GridContainer

var _db: Database = null
var _programgroup_id: int = -1
var rows := 0 # number of table rows, not including the header row
var cols := 0 # number of table columns, including the first command name column


func setup(db: Database, programgroup_id: int, programs: Dictionary[int, String], program_abbreviations: Dictionary[int, String], commands: Dictionary[int, String], program_command_names: Dictionary[int, Dictionary], program_command_hotkeys: Dictionary[int, Dictionary], user_hotkeys: Dictionary[int, Dictionary], user_hotkey_programs: Dictionary[int, Dictionary]) -> void:
    assert(db != null)
    assert(db.is_open())
    assert(programgroup_id > 0)

    _db = db
    _programgroup_id = programgroup_id
    columns = 1 + programs.size() + 1 + programs.size()

    add_header_row(programs, program_abbreviations)

    for command_id in commands:
        rows += add_command_cells(command_id, programs, commands, program_command_names, program_command_hotkeys, user_hotkeys, user_hotkey_programs)

    cols = columns


func add_cell(cell: Control) -> void:
    assert(cell != null)
    add_child(cell)


func add_empty_cell() -> void:
    add_cell(Control.new())


func get_cell(row: int, col: int) -> Control:
    if row < 0 || col < 0 || row >= rows || col >= cols:
        return null

    var children := get_children()
    assert(children.size() == (rows + 1) * cols)
    return children[(row + 1) * cols + col]


func add_header_row(programs: Dictionary[int, String], program_abbreviations: Dictionary[int, String]) -> void:
    add_header_command_label("Commands")

    for program_id: int in programs:
        add_header_program_label(programs[program_id])

    add_header_user_hotkey_label("User Hotkey")

    for program_id: int in programs:
        add_header_program_abbreviation(programs[program_id], program_abbreviations[program_id])


func add_command_cells(command_id: int, programs: Dictionary[int, String], commands: Dictionary[int, String], program_command_names: Dictionary[int, Dictionary], program_command_hotkeys: Dictionary[int, Dictionary], user_hotkeys: Dictionary[int, Dictionary], user_hotkey_programs: Dictionary[int, Dictionary]) -> int:
    var necessary_rows := count_necessary_command_hotkey_rows(command_id, program_command_hotkeys)

    var program_hotkey_cells: Dictionary = {}
    for program_id in programs:
        program_hotkey_cells[program_id] = create_program_command_hotkey_cells(necessary_rows, command_id, program_id, program_command_names, program_command_hotkeys)

    for row in necessary_rows:
        add_command_name_cell(row, command_id, commands[command_id])
        add_program_command_hotkey_cells(row, programs, program_hotkey_cells)
        add_user_hotkey_cell(row, command_id, user_hotkeys)
        add_user_hotkey_program_controls(command_id, programs, user_hotkeys, user_hotkey_programs, row)

    return necessary_rows


func add_label(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.size_flags_vertical = Control.SIZE_FILL
    add_cell(label)
    return label


func add_header_command_label(text: String) -> Label:
    var label := add_label(text)
    label.theme_type_variation = "HeaderCommandLabel"
    return label


func add_header_user_hotkey_label(text: String) -> Label:
    var label := add_label(text)
    label.theme_type_variation = "HeaderUserHotkeyLabel"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return label


func add_header_program_label(text: String) -> Label:
    var label := add_label(text)
    label.theme_type_variation = "HeaderProgramLabel"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return label


func add_header_program_abbreviation(program_name: String, program_abbr: String) -> Label:
    var label := add_label(program_abbr)
    label.theme_type_variation = "HeaderProgramAbbreviation"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.tooltip_text = program_name
    label.mouse_filter = MOUSE_FILTER_PASS
    return label


func add_command_name_cell(row: int, command_id: int, command_name: String) -> void:
    if row == 0:
        var cell := TextCell.new()
        cell.text = command_name
        cell.changed.connect(_on_command_name_cell_changed.bind(command_id))
        add_cell(cell)
    else:
        add_empty_cell()


func add_program_command_hotkey_cells(row: int, programs: Dictionary[int, String], program_hotkey_cells: Dictionary) -> void:
    for program_id in programs:
        var cells: Array[ProgramHotkeyTextCell] = program_hotkey_cells[program_id]
        var cell := cells[row]
        cell.changed.connect(_on_program_command_hotkey_cell_changed)
        add_cell(cell)


func add_user_hotkey_cell(row: int, command_id: int, user_hotkeys: Dictionary[int, Dictionary]) -> void:
    if row == 0:
        var cell := UserHotkeyTextCell.new(command_id)
        cell.changed.connect(_on_user_hotkey_cell_changed)
        if command_id in user_hotkeys:
            var user_hotkey_data: Dictionary = user_hotkeys[command_id]
            var user_hotkey: String = user_hotkey_data["user_hotkey"]
            cell.text = user_hotkey
        add_cell(cell)
    else:
        add_empty_cell()


func add_user_hotkey_program_controls(command_id: int, programs: Dictionary[int, String], user_hotkeys: Dictionary[int, Dictionary], user_hotkey_programs: Dictionary[int, Dictionary], row: int) -> void:
    if command_id in user_hotkeys:
        var user_hotkey_id: int = user_hotkeys[command_id]["user_hotkey_id"]
        var hotkeys: Array = user_hotkey_programs[command_id].get("hotkeys") if command_id in user_hotkey_programs else []

        for program_id in programs:
            if row == 0:
                var s := "✔️" if program_id in hotkeys else "❌"
                var label := add_label(s)
                label.mouse_filter = Control.MOUSE_FILTER_PASS
                label.gui_input.connect(_on_user_hotkey_program_checkbox_gui_input.bind(user_hotkey_id, program_id, label))
            else:
                add_empty_cell()
    else:
        for program_id in programs:
            if row == 0:
                add_label("–")
            else:
                add_empty_cell()


func create_program_command_hotkey_cells(necessary_rows: int, command_id: int, program_id: int, program_command_names: Dictionary[int, Dictionary], program_command_hotkeys: Dictionary[int, Dictionary]) -> Array[ProgramHotkeyTextCell]:
    var cells: Array[ProgramHotkeyTextCell] = []

    if command_id in program_command_names and program_id in program_command_names[command_id]:
        if command_id in program_command_hotkeys and program_id in program_command_hotkeys[command_id]:
            for hotkey: String in program_command_hotkeys[command_id][program_id]:
                var cell := ProgramHotkeyTextCell.new(command_id, program_id, true)
                cell.text = hotkey
                cells.append(cell)
        if cells.size() < necessary_rows:
            for i in necessary_rows - cells.size():
                cells.append(ProgramHotkeyTextCell.new(command_id, program_id, true))
    else:
        if cells.size() < necessary_rows:
            for i in necessary_rows - cells.size():
                cells.append(ProgramHotkeyTextCell.new(command_id, program_id, false))

    return cells


func count_necessary_command_hotkey_rows(command_id: int, program_command_hotkeys: Dictionary[int, Dictionary]) -> int:
    var necessary_rows := 1
    if command_id in program_command_hotkeys:
        var command_data := program_command_hotkeys[command_id]
        for program_id: int in command_data:
            var program_hotkeys: Array = command_data[program_id]
            necessary_rows = maxi(necessary_rows, program_hotkeys.size())
    return necessary_rows


func _on_user_hotkey_program_checkbox_gui_input(event: InputEvent, user_hotkey_id: int, program_id: int, label: Label) -> void:
    if event is InputEventMouseButton:
        var mouse_button_event: InputEventMouseButton = event
        if mouse_button_event.pressed && mouse_button_event.button_index == 1:
            if label.text == "✔️":
                _db.delete_rows("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [user_hotkey_id, program_id])
            elif label.text == "❌":
                _db.insert_row("user_hotkey_program", {"user_hotkey_id": user_hotkey_id, "program_id": program_id})
            Events.switch_to_commands_screen.emit.call_deferred(_programgroup_id)


func _on_command_name_cell_changed(cell: TextCell, old_name: String, new_name: String, command_id: int) -> void:
    if new_name != "":
        _db.update_rows("command", "command_id=%d" % command_id, {"name": new_name})
    else:
        cell.text = old_name
        printerr("Command name must not be empty!")


func _on_program_command_hotkey_cell_changed(cell: ProgramHotkeyTextCell, old_hotkey: String, new_hotkey: String) -> void:
    var success := true
    if cell.is_bound:
        if old_hotkey != "" && new_hotkey != "":
            success = _db.update_rows("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, old_hotkey], {"hotkey": new_hotkey})
        elif old_hotkey == "" && new_hotkey != "":
            success = _db.insert_row("program_command_hotkey", {"program_id": cell.program_id, "command_id": cell.command_id, "hotkey": new_hotkey})
        elif old_hotkey != "" && new_hotkey == "":
            success = _db.delete_rows("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, old_hotkey])
        else:
            printerr("_on_program_command_hotkey_cell_changed error %d: '%s', '%s' (c: %d, p: %d)" % [1, old_hotkey, new_hotkey, cell.command_id, cell.program_id])
    else:
        if old_hotkey == "" && new_hotkey != "":
            success = _db.insert_row("program_command", {"program_id": cell.program_id, "command_id": cell.command_id})
            if success:
                success = _db.insert_row("program_command_hotkey", {"program_id": cell.program_id, "command_id": cell.command_id, "hotkey": new_hotkey})
                cell.is_bound = true
        else:
            printerr("_on_program_command_hotkey_cell_changed error %d: '%s', '%s' (c: %d, p: %d)" % [2, old_hotkey, new_hotkey, cell.command_id, cell.program_id])
    if !success:
        cell.text = old_hotkey


func _on_user_hotkey_cell_changed(cell: UserHotkeyTextCell, old_hotkey: String, new_hotkey: String) -> void:
    assert(cell.command_id > 0)

    if old_hotkey != "" && new_hotkey != "":
        _db.update_rows("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, old_hotkey], {"hotkey": new_hotkey})
    elif old_hotkey == "" && new_hotkey != "":
        _db.insert_row("user_hotkey", {"command_id": cell.command_id, "hotkey": new_hotkey})
    elif old_hotkey != "" && new_hotkey == "":
        _db.delete_rows("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, old_hotkey])
    else:
        printerr("_on_user_hotkey_cell_changed error: %d, '%s', '%s'" % [1, cell.command_id, old_hotkey, new_hotkey])
