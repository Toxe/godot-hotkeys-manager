class_name CommandGrid extends GridContainer

const command_label_scene: PackedScene = preload("uid://b14stqo0vtq6l")
const user_hotkey_label_scene: PackedScene = preload("uid://cb5pwsvxmxh33")
const icon_label_scene: PackedScene = preload("uid://cdjuh5d5w4a3y")

var _db: Database = null
var _programgroup_id: int = -1
var _programs: Dictionary[int, String]
var _rows := 0 # number of table rows, not including the header and bottom row
var _cols := 0 # number of table columns, including the first command name column


func setup(db: Database, programgroup_id: int, programs: Dictionary[int, String], program_abbreviations: Dictionary[int, String], program_icons: Dictionary[int, Dictionary], sorted_command_names: Array[Dictionary], program_command_hotkeys: Dictionary[int, Dictionary], user_hotkeys: Dictionary[int, Dictionary], user_hotkey_programs: Dictionary[int, Dictionary]) -> void:
    assert(db != null)
    assert(db.is_open())
    assert(programgroup_id > 0)

    _db = db
    _programgroup_id = programgroup_id
    _programs = programs
    _cols = 1 + programs.size() + 1 + programs.size()
    columns = _cols

    add_header_row(programs, program_abbreviations, program_icons)

    for command in sorted_command_names:
        var command_id: int = command["command_id"]
        var command_name: String = command["command_name"]
        _rows += add_command_cells(command_id, command_name, programs, program_command_hotkeys, user_hotkeys, user_hotkey_programs)

    add_bottom_row()


func add_cell(cell: Control) -> void:
    assert(cell != null)
    var panel_container := PanelContainer.new()
    panel_container.add_child(cell)
    add_child(panel_container)


func add_sibling_cell(sibling: Control, cell: Control) -> Control:
    assert(sibling != null)
    assert(cell != null)
    var panel_container := PanelContainer.new()
    panel_container.add_child(cell)
    sibling.add_sibling(panel_container)
    return panel_container


func add_empty_cell() -> void:
    add_cell(Control.new())


func add_empty_sibling_cell(sibling: Control) -> Control:
    return add_sibling_cell(sibling, Control.new())


func get_cell(row: int, col: int) -> Control:
    if row < 0 || col < 0 || row >= _rows || col >= _cols:
        return null
    assert(get_child_count() == (_rows + 2) * _cols) # +2 == header + bottom row
    var panel_container: PanelContainer = get_child((row + 1) * _cols + col)
    return panel_container.get_child(0)


func get_focus_cell() -> Control:
    var focus_control := get_viewport().gui_get_focus_owner()
    if !focus_control:
        return null
    var parent_panel_container := focus_control.get_parent_control() as PanelContainer
    if !parent_panel_container:
        return null
    var command_grid := parent_panel_container.get_parent_control() as CommandGrid
    if !command_grid:
        return null
    return focus_control


## Return table index without the header controls.
func _get_cell_index(cell: Control) -> int:
    assert(cell != null)
    var parent_panel_container := cell.get_parent_control() as PanelContainer
    assert(parent_panel_container != null)
    var index_without_header_controls := parent_panel_container.get_index() - _cols
    assert(index_without_header_controls >= 0)
    return index_without_header_controls


func get_cell_coords(cell: Control) -> Vector2i:
    assert(cell != null)
    var index_without_header_controls := _get_cell_index(cell)
    @warning_ignore("integer_division")
    var row := index_without_header_controls / _cols
    var col := index_without_header_controls - row * _cols
    return Vector2i(col, row)


func get_add_command_cell() -> TextCell:
    var panel_container: PanelContainer = get_child((_rows + 1) * _cols)
    return panel_container.get_child(0)


func get_number_of_programs() -> int:
    assert(_programs != null)
    return _programs.size()


func get_user_hotkey_column() -> int:
    return get_first_program_hotkey_column() + get_number_of_programs() + 1


func get_first_program_hotkey_column() -> int:
    return 1


func get_first_user_hotkey_program_checkbox_column() -> int:
    return get_user_hotkey_column() + 1


func find_command_row(command_name: String) -> int:
    for row in _rows:
        var cell: TextCell = get_cell(row, 0) as TextCell
        if cell && cell.text.nocasecmp_to(command_name) == 0:
            return row
    return -1


func add_header_row(programs: Dictionary[int, String], program_abbreviations: Dictionary[int, String], program_icons: Dictionary[int, Dictionary]) -> void:
    add_header_command_label("Commands")

    for program_id: int in programs:
        add_header_program_label(program_id, programs, program_icons)

    add_header_user_hotkey_label("User Hotkey")

    for program_id: int in programs:
        add_header_program_abbreviation_label(program_id, programs, program_abbreviations, program_icons)


func add_bottom_row() -> void:
    # input field
    var cell := TextCell.new()
    cell.placeholder_text = "Add Command…"
    cell.theme_type_variation = "CommandNameLineEdit"
    cell.changed.connect(_on_add_command_cell_changed)
    cell.add_row.connect(_on_add_row)
    add_cell(cell)
    # empty cells
    for i in range(1, _cols):
        add_empty_cell()


func add_command_cells(command_id: int, command_name: String, programs: Dictionary[int, String], program_command_hotkeys: Dictionary[int, Dictionary], user_hotkeys: Dictionary[int, Dictionary], user_hotkey_programs: Dictionary[int, Dictionary]) -> int:
    var necessary_rows := count_necessary_command_hotkey_rows(command_id, program_command_hotkeys)

    var program_hotkey_cells: Dictionary = {}
    for program_id in programs:
        program_hotkey_cells[program_id] = create_program_command_hotkey_cells(necessary_rows, command_id, program_id, program_command_hotkeys)

    for row in necessary_rows:
        add_command_name_cell(row, command_id, command_name)
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


func add_header_command_label(text: String) -> void:
    var control: Control = command_label_scene.instantiate()
    var label: Label = control.get_node("%Label")
    label.text = text
    add_cell(control)


func add_header_user_hotkey_label(text: String) -> void:
    var control: Control = user_hotkey_label_scene.instantiate()
    var label: Label = control.get_node("%Label")
    label.text = text
    add_cell(control)


func add_header_icon_label(program_id: int, program_icons: Dictionary[int, Dictionary], icon_size: int, label_text: String, tooltip: String, label_theme_type_variation: String) -> void:
    var control: Control = icon_label_scene.instantiate()
    control.tooltip_text = tooltip

    var label: Label = control.get_node("%Label")
    label.text = label_text
    label.theme_type_variation = label_theme_type_variation

    var texture_rect: TextureRect = control.get_node("%TextureRect")
    var program_icon: Texture2D = program_icons[program_id][icon_size]
    texture_rect.texture = program_icon

    add_cell(control)


func add_header_program_label(program_id: int, programs: Dictionary[int, String], program_icons: Dictionary[int, Dictionary]) -> void:
    var program_name := programs[program_id]
    add_header_icon_label(program_id, program_icons, 64, program_name, program_name, "ProgramLabel")


func add_header_program_abbreviation_label(program_id: int, programs: Dictionary[int, String], program_abbreviations: Dictionary[int, String], program_icons: Dictionary[int, Dictionary]) -> void:
    var program_name := programs[program_id]
    var program_abbreviation := program_abbreviations[program_id]
    add_header_icon_label(program_id, program_icons, 32, program_abbreviation, program_name, "ProgramAbbreviationLabel")


func create_command_name_cell(command_id: int, command_name: String) -> TextCell:
    var cell := TextCell.new()
    cell.text = command_name
    cell.theme_type_variation = "CommandNameLineEdit"
    cell.changed.connect(_on_command_name_cell_changed.bind(command_id))
    cell.add_row.connect(_on_add_row)
    return cell


func add_command_name_cell(row: int, command_id: int, command_name: String) -> void:
    if row == 0:
        add_cell(create_command_name_cell(command_id, command_name))
    else:
        add_empty_cell()


func add_program_command_hotkey_cells(row: int, programs: Dictionary[int, String], program_hotkey_cells: Dictionary) -> void:
    for program_id in programs:
        var cells: Array[ProgramHotkeyTextCell] = program_hotkey_cells[program_id]
        var cell := cells[row]
        cell.changed.connect(_on_program_command_hotkey_cell_changed)
        cell.add_row.connect(_on_add_row)
        add_cell(cell)


func add_user_hotkey_cell(row: int, command_id: int, user_hotkeys: Dictionary[int, Dictionary]) -> void:
    if row == 0:
        var cell := UserHotkeyTextCell.new(command_id)
        cell.changed.connect(_on_user_hotkey_cell_changed)
        cell.add_row.connect(_on_add_row)
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
            var checkbox := UserHotkeyProgramCheckboxCell.new(program_id) # automatically disabled
            checkbox.toggled.connect(_on_user_hotkey_program_checkbox_toggled.bind(checkbox))
            checkbox.add_row.connect(_on_add_row)
            if command_id in user_hotkeys:
                checkbox.user_hotkey_id = user_hotkeys[command_id]["user_hotkey_id"]
                var hotkeys: Array = user_hotkey_programs[command_id].get("hotkeys") if command_id in user_hotkey_programs else []
                checkbox.set_pressed_no_signal(program_id in hotkeys)
            add_cell(checkbox)
        else:
            add_empty_cell()


func add_command_row(command_name: String, programs: Dictionary[int, String]) -> void:
    var command_id: int = _db.select_value("command", "command_id", "name=?", [command_name])
    var user_hotkey_id := 0
    var user_hotkey := ""
    var row: Variant = _db.select_row("user_hotkey", ["user_hotkey_id", "hotkey"], "command_id=?", [command_id])
    if row:
        user_hotkey_id = row["user_hotkey_id"]
        user_hotkey = row["hotkey"]

    # add command name cell
    var sibling: Control = get_child((_rows + 1) * _cols - 1)
    sibling = add_sibling_cell(sibling, create_command_name_cell(command_id, command_name))

    # add program hotkey cells
    for program_id in programs:
        var program_hotkey_cell := ProgramHotkeyTextCell.new(command_id, program_id)
        program_hotkey_cell.changed.connect(_on_program_command_hotkey_cell_changed)
        program_hotkey_cell.add_row.connect(_on_add_row)
        sibling = add_sibling_cell(sibling, program_hotkey_cell)

    # add user hotkey cell
    var user_hotkey_cell := UserHotkeyTextCell.new(command_id, user_hotkey_id)
    user_hotkey_cell.text = user_hotkey
    user_hotkey_cell.changed.connect(_on_user_hotkey_cell_changed)
    user_hotkey_cell.add_row.connect(_on_add_row)
    sibling = add_sibling_cell(sibling, user_hotkey_cell)

    # add user hotkey program assignment checkboxes
    var assigned_programs: Array[int]
    if _db.select_rows("user_hotkey_program", ["program_id"], "user_hotkey_id=?", [user_hotkey_id]):
        for d: Dictionary in _db.query_result():
            var program_id: int = d["program_id"]
            assigned_programs.append(program_id)

    for program_id in programs:
        var checkbox := UserHotkeyProgramCheckboxCell.new(program_id, user_hotkey_id)
        checkbox.button_pressed = program_id in assigned_programs
        checkbox.toggled.connect(_on_user_hotkey_program_checkbox_toggled.bind(checkbox))
        checkbox.add_row.connect(_on_add_row)
        sibling = add_sibling_cell(sibling, checkbox)

    _rows += 1


func insert_row_after(previous_row: int, programs: Dictionary[int, String]) -> void:
    assert(previous_row >= 0)

    # get the first program hotkey cell of the previous_row
    var previous_row_program_hotkey_cell: ProgramHotkeyTextCell = get_cell(previous_row, 1) as ProgramHotkeyTextCell
    assert(previous_row_program_hotkey_cell != null)

    # the command_id of the added row
    var command_id := previous_row_program_hotkey_cell.command_id

    # add empty command name cell
    var sibling: Control = get_cell(previous_row, _cols - 1).get_parent_control()
    sibling = add_empty_sibling_cell(sibling)

    # add program hotkey cells
    for program_id in programs:
        var program_hotkey_cell := ProgramHotkeyTextCell.new(command_id, program_id)
        program_hotkey_cell.changed.connect(_on_program_command_hotkey_cell_changed)
        program_hotkey_cell.add_row.connect(_on_add_row)
        sibling = add_sibling_cell(sibling, program_hotkey_cell)

    # add empty user hotkey cell
    sibling = add_empty_sibling_cell(sibling)

    # add empty user hotkey program assignment checkboxes
    for program_id in programs:
        sibling = add_empty_sibling_cell(sibling)

    _rows += 1


func create_program_command_hotkey_cells(necessary_rows: int, command_id: int, program_id: int, program_command_hotkeys: Dictionary[int, Dictionary]) -> Array[ProgramHotkeyTextCell]:
    var cells: Array[ProgramHotkeyTextCell] = []

    if command_id in program_command_hotkeys and program_id in program_command_hotkeys[command_id]:
        for hotkey: String in program_command_hotkeys[command_id][program_id]:
            var cell := ProgramHotkeyTextCell.new(command_id, program_id)
            cell.text = hotkey
            cells.append(cell)
        if cells.size() < necessary_rows:
            for i in necessary_rows - cells.size():
                cells.append(ProgramHotkeyTextCell.new(command_id, program_id))
    else:
        if cells.size() < necessary_rows:
            for i in necessary_rows - cells.size():
                cells.append(ProgramHotkeyTextCell.new(command_id, program_id))

    return cells


func count_necessary_command_hotkey_rows(command_id: int, program_command_hotkeys: Dictionary[int, Dictionary]) -> int:
    var necessary_rows := 1
    if command_id in program_command_hotkeys:
        var command_data := program_command_hotkeys[command_id]
        for program_id: int in command_data:
            var program_hotkeys: Array = command_data[program_id]
            necessary_rows = maxi(necessary_rows, program_hotkeys.size())
    return necessary_rows


func update_user_hotkey_program_checkboxes(user_hotkey_id: int, button_pressed: bool, new_id: int) -> void:
    assert(user_hotkey_id > 0)
    assert(new_id >= 0)

    # find row of the user hotkey cell user_hotkey_id
    for row in range(0, _rows):
        var cell: UserHotkeyTextCell = get_cell(row, get_user_hotkey_column()) as UserHotkeyTextCell
        if cell:
            if cell.user_hotkey_id == user_hotkey_id:
                # update checkboxes of this row
                for i in get_number_of_programs():
                    var checkbox: UserHotkeyProgramCheckboxCell = get_cell(row, get_first_user_hotkey_program_checkbox_column() + i)
                    checkbox.user_hotkey_id = new_id
                    checkbox.set_pressed_no_signal(button_pressed)
                return


func _on_user_hotkey_program_checkbox_toggled(toggled_on: bool, checkbox: UserHotkeyProgramCheckboxCell) -> void:
    var success := true
    if toggled_on:
        success = _db.insert_row("user_hotkey_program", {"user_hotkey_id": checkbox.user_hotkey_id, "program_id": checkbox.program_id})
    else:
        success = _db.delete_rows("user_hotkey_program", "user_hotkey_id=? AND program_id=?", [checkbox.user_hotkey_id, checkbox.program_id])
    if !success:
        checkbox.set_pressed_no_signal(!toggled_on)


func _on_command_name_cell_changed(cell: TextCell, old_name: String, new_name: String, command_id: int) -> void:
    if new_name != "":
        _db.update_rows("command", "command_id=?", [command_id], {"name": new_name})
    else:
        cell.text = old_name
        printerr("Command name must not be empty!")


func _on_program_command_hotkey_cell_changed(cell: ProgramHotkeyTextCell, old_hotkey: String, new_hotkey: String) -> void:
    var success := true
    if old_hotkey == "" && new_hotkey != "":
        success = _db.insert_row("program_command_hotkey", {"program_id": cell.program_id, "command_id": cell.command_id, "hotkey": new_hotkey})
    elif old_hotkey != "" && new_hotkey != "":
        success = _db.update_rows("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell.program_id, cell.command_id, old_hotkey], {"hotkey": new_hotkey})
    elif old_hotkey != "" && new_hotkey == "":
        success = _db.delete_rows("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell.program_id, cell.command_id, old_hotkey])
    if !success:
        cell.text = old_hotkey


func _on_user_hotkey_cell_changed(cell: UserHotkeyTextCell, old_hotkey: String, new_hotkey: String) -> void:
    if old_hotkey != "" && new_hotkey != "":
        _db.update_rows("user_hotkey", "command_id=? AND hotkey=?", [cell.command_id, old_hotkey], {"hotkey": new_hotkey})
    elif old_hotkey == "" && new_hotkey != "":
        if _db.insert_row("user_hotkey", {"command_id": cell.command_id, "hotkey": new_hotkey}):
            cell.user_hotkey_id = _db.last_insert_rowid()
            update_user_hotkey_program_checkboxes(cell.user_hotkey_id, false, cell.user_hotkey_id)
    elif old_hotkey != "" && new_hotkey == "":
        if _db.delete_rows("user_hotkey", "command_id=? AND hotkey=?", [cell.command_id, old_hotkey]):
            update_user_hotkey_program_checkboxes(cell.user_hotkey_id, false, 0)
            cell.user_hotkey_id = 0
    else:
        printerr("_on_user_hotkey_cell_changed error: %d, '%s', '%s'" % [1, cell.command_id, old_hotkey, new_hotkey])


func _on_add_command_cell_changed(cell: TextCell, old_text: String, new_text: String) -> void:
    if old_text == "" && new_text != "":
        cell.text = ""
        var row := find_command_row(new_text)
        if row >= 0:
            return # command already in the table
        # create a new command if it doesn't already exist in the database
        var command_name := new_text
        var result: Variant = _db.select_value("command", "name", "name=?", [new_text])
        if result:
            command_name = result
        else:
            if !_db.insert_row("command", {"name": command_name}):
                return
        add_command_row(command_name, _programs)


func _on_add_row(cell: Control, add_above: bool) -> void:
    if _rows == 0:
        return

    var cell_coords := get_cell_coords(cell)
    var cell_row := cell_coords.y
    var next_focus_text_cell: TextCell = null

    if add_above:
        if cell_row > 0:
            insert_row_after(cell_row - 1, _programs)
            next_focus_text_cell = get_cell(cell_coords.y, cell_coords.x) as TextCell
    else:
        if cell != get_add_command_cell():
            insert_row_after(cell_row, _programs)
            next_focus_text_cell = get_cell(cell_coords.y + 1, cell_coords.x) as TextCell

    # move focus to cell in new row, if it's a TextCell
    if next_focus_text_cell:
        next_focus_text_cell.grab_focus_without_entering_edit_mode()
