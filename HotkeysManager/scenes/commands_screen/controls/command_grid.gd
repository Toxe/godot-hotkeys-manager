class_name CommandGrid extends GridContainer

var _db: Database = null
var _programgroup_id: int = -1
var _num_programs := 0
var rows := 0 # number of table rows, not including the header row
var cols := 0 # number of table columns, including the first command name column


func setup(db: Database, programgroup_id: int, programs: Dictionary[int, String], program_abbreviations: Dictionary[int, String], commands: Dictionary[int, String], program_command_names: Dictionary[int, Dictionary], program_command_hotkeys: Dictionary[int, Dictionary], user_hotkeys: Dictionary[int, Dictionary], user_hotkey_programs: Dictionary[int, Dictionary]) -> void:
    assert(db != null)
    assert(db.is_open())
    assert(programgroup_id > 0)

    _db = db
    _programgroup_id = programgroup_id
    _num_programs = programs.size()
    columns = 1 + programs.size() + 1 + programs.size()

    add_header_row(programs, program_abbreviations)

    for command_id in commands:
        rows += add_command_cells(command_id, programs, commands, program_command_names, program_command_hotkeys, user_hotkeys, user_hotkey_programs)

    cols = columns


func add_cell(cell: Control) -> void:
    assert(cell != null)
    var panel_container := PanelContainer.new()
    panel_container.add_child(cell)
    add_child(panel_container)


func add_empty_cell() -> void:
    add_cell(Control.new())


func get_cell(row: int, col: int) -> Control:
    if row < 0 || col < 0 || row >= rows || col >= cols:
        return null

    var children := get_children()
    assert(children.size() == (rows + 1) * cols)
    var panel_container: PanelContainer = children[(row + 1) * cols + col]
    return panel_container.get_child(0)


func add_header_row(programs: Dictionary[int, String], program_abbreviations: Dictionary[int, String]) -> void:
    add_header_command_label("Commands")

    for program_id: int in programs:
        add_header_program_label(programs[program_id])

    add_header_user_hotkey_label("User Hotkey")

    for program_id: int in programs:
        add_header_program_abbreviation_label(programs[program_id], program_abbreviations[program_id])


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


func add_header_label(text: String, label_theme_type_variation: String, label_horizontal_alignment: HorizontalAlignment) -> Label:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = label_horizontal_alignment
    label.theme_type_variation = label_theme_type_variation

    var margin_container := MarginContainer.new()
    margin_container.add_child(label)
    add_cell(margin_container)

    return label


func add_header_command_label(text: String) -> Label:
    return add_header_label(text, "HeaderCommandLabel", HORIZONTAL_ALIGNMENT_LEFT)


func add_header_user_hotkey_label(text: String) -> Label:
    return add_header_label(text, "HeaderUserHotkeyLabel", HORIZONTAL_ALIGNMENT_CENTER)


func add_header_program_label(text: String) -> Label:
    return add_header_label(text, "HeaderProgramLabel", HORIZONTAL_ALIGNMENT_CENTER)


func add_header_program_abbreviation_label(program_name: String, program_abbr: String) -> Label:
    var label := add_header_label(program_abbr, "HeaderProgramAbbreviation", HORIZONTAL_ALIGNMENT_CENTER)
    label.tooltip_text = program_name
    label.mouse_filter = MOUSE_FILTER_PASS
    return label


func add_command_name_cell(row: int, command_id: int, command_name: String) -> void:
    if row == 0:
        var cell := TextCell.new()
        cell.text = command_name
        cell.theme_type_variation = "CommandNameLineEdit"
        cell.changed.connect(_on_command_name_cell_changed.bind(command_id))
        add_cell(cell)
    else:
        add_empty_cell()


func add_program_command_hotkey_cells(row: int, programs: Dictionary[int, String], program_hotkey_cells: Dictionary) -> void:
    for program_id in programs:
        var cells: Array[ProgramHotkeyTextCell] = program_hotkey_cells[program_id]
        var cell := cells[row]
        cell.expand_to_text_length = true
        cell.changed.connect(_on_program_command_hotkey_cell_changed)
        add_cell(cell)


func add_user_hotkey_cell(row: int, command_id: int, user_hotkeys: Dictionary[int, Dictionary]) -> void:
    if row == 0:
        var cell := UserHotkeyTextCell.new(command_id)
        cell.changed.connect(_on_user_hotkey_cell_changed)
        if command_id in user_hotkeys:
            var user_hotkey_data: Dictionary = user_hotkeys[command_id]
            cell.text = user_hotkey_data["user_hotkey"]
            cell.user_hotkey_id = user_hotkey_data["user_hotkey_id"]
        add_cell(cell)
    else:
        add_empty_cell()


func add_user_hotkey_program_controls(command_id: int, programs: Dictionary[int, String], user_hotkeys: Dictionary[int, Dictionary], user_hotkey_programs: Dictionary[int, Dictionary], row: int) -> void:
    for program_id in programs:
        if row == 0:
            var checkbox := UserHotkeyProgramCheckbox.new(program_id)

            if command_id in user_hotkeys:
                checkbox.user_hotkey_id = user_hotkeys[command_id]["user_hotkey_id"]
                var hotkeys: Array = user_hotkey_programs[command_id].get("hotkeys") if command_id in user_hotkey_programs else []
                checkbox.set_pressed_no_signal(program_id in hotkeys)
                checkbox.toggled.connect(_on_user_hotkey_program_checkbox_toggled.bind(checkbox))
            else:
                checkbox.disabled = true

            add_cell(checkbox)
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


func bind_program_command_cells(program_id: int, command_id: int) -> void:
    assert(program_id > 0)
    assert(command_id > 0)

    var cells := find_children("*", "ProgramHotkeyTextCell", true, false)
    for cell: ProgramHotkeyTextCell in cells:
        if cell.program_id == program_id && cell.command_id && !cell.is_bound:
            cell.is_bound = true


func update_user_hotkey_program_checkboxes(user_hotkey_id: int, disabled: bool, button_pressed: bool, new_id: int) -> void:
    assert(user_hotkey_id > 0)
    assert(new_id >= 0)

    # find row of the user hotkey cell user_hotkey_id
    for row in range(0, rows):
        var cell: UserHotkeyTextCell = get_cell(row, _num_programs + 1) as UserHotkeyTextCell
        if cell:
            if cell.user_hotkey_id == user_hotkey_id:
                # update checkboxes of this row
                for col in range(_num_programs + 2, cols):
                    var checkbox: UserHotkeyProgramCheckbox = get_cell(row, col)
                    checkbox.user_hotkey_id = new_id
                    checkbox.disabled = disabled
                    checkbox.set_pressed_no_signal(button_pressed)
                return


func _on_user_hotkey_program_checkbox_toggled(toggled_on: bool, checkbox: UserHotkeyProgramCheckbox) -> void:
    var success := true
    if toggled_on:
        success = _db.insert_row("user_hotkey_program", {"user_hotkey_id": checkbox.user_hotkey_id, "program_id": checkbox.program_id})
    else:
        success = _db.delete_rows("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [checkbox.user_hotkey_id, checkbox.program_id])
    if !success:
        checkbox.set_pressed_no_signal(!toggled_on)


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
                if success:
                    bind_program_command_cells(cell.program_id, cell.command_id)
        else:
            printerr("_on_program_command_hotkey_cell_changed error %d: '%s', '%s' (c: %d, p: %d)" % [2, old_hotkey, new_hotkey, cell.command_id, cell.program_id])
    if !success:
        cell.text = old_hotkey


func _on_user_hotkey_cell_changed(cell: UserHotkeyTextCell, old_hotkey: String, new_hotkey: String) -> void:
    if old_hotkey != "" && new_hotkey != "":
        _db.update_rows("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, old_hotkey], {"hotkey": new_hotkey})
    elif old_hotkey == "" && new_hotkey != "":
        if _db.insert_row("user_hotkey", {"command_id": cell.command_id, "hotkey": new_hotkey}):
            cell.user_hotkey_id = _db.last_insert_rowid()
            update_user_hotkey_program_checkboxes(cell.user_hotkey_id, false, false, cell.user_hotkey_id)
    elif old_hotkey != "" && new_hotkey == "":
        if _db.delete_rows("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, old_hotkey]):
            update_user_hotkey_program_checkboxes(cell.user_hotkey_id, true, false, 0)
            cell.user_hotkey_id = 0
    else:
        printerr("_on_user_hotkey_cell_changed error: %d, '%s', '%s'" % [1, cell.command_id, old_hotkey, new_hotkey])
