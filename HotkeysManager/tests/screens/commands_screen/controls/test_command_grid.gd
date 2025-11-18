extends GutTest


func create_command_grid(programgroup_id: int) -> CommandGrid:
    var db: Database = Database.new()
    db.open(":memory:")

    var programs := CommandsScreen.query_programs(db, programgroup_id)
    var program_abbreviations := CommandsScreen.query_program_abbreviations(db, programgroup_id)
    var commands := CommandsScreen.query_commands(db, programgroup_id)
    var program_command_names := CommandsScreen.query_program_command_names(db, programgroup_id)
    var program_command_hotkeys := CommandsScreen.query_program_command_hotkeys(db, programgroup_id)
    var user_hotkeys_by_commands := CommandsScreen.query_user_hotkeys_by_commands(db, programgroup_id)
    var user_hotkeys_by_programs := CommandsScreen.query_user_hotkeys_by_programs(db, programgroup_id)
    var user_hotkey_programs := CommandsScreen.query_user_hotkey_programs(db, programgroup_id)

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

    var command_grid := CommandGrid.new()
    command_grid.setup(db, programgroup_id, programs, program_abbreviations, combined_commands, program_command_names, program_command_hotkeys, user_hotkeys, user_hotkey_programs)
    return add_child_autofree(command_grid)


func enter_text_and_emit_changed_signal(cell: TextCell, new_text: String) -> void:
    var old_text := cell.text
    cell.text = new_text
    cell.changed.emit(cell, old_text, new_text)


func test_no_cell_has_input_focus_by_default() -> void:
    var command_grid := create_command_grid(3)
    assert_null(command_grid.get_focus_cell())


func test_grid_child_count() -> void:
    var command_grid := create_command_grid(3)
    assert_eq(command_grid.get_child_count(), (4 + 2) * 10) # 4 cell rows + header + bottom


func test_number_of_rows() -> void:
    var command_grid := create_command_grid(3)
    assert_eq(command_grid._rows, 4)


func test_number_of_columns() -> void:
    var command_grid := create_command_grid(3)
    assert_eq(command_grid._cols, 10)


func test_number_of_programs() -> void:
    var command_grid := create_command_grid(3)
    assert_eq(command_grid._num_programs, 4)


func test_get_cell_returns_grid_controls() -> void:
    var command_grid := create_command_grid(3)
    assert_is(command_grid.get_cell(0, 0), TextCell)
    assert_is(command_grid.get_cell(1, 0), TextCell)
    assert_is(command_grid.get_cell(2, 0), Control)
    assert_is(command_grid.get_cell(3, 0), TextCell)
    assert_is(command_grid.get_cell(0, 9), UserHotkeyProgramCheckbox)
    assert_is(command_grid.get_cell(1, 9), UserHotkeyProgramCheckbox)
    assert_is(command_grid.get_cell(2, 9), Control)
    assert_is(command_grid.get_cell(3, 9), UserHotkeyProgramCheckbox)


func test_get_cell_returns_null_for_non_existing_cells() -> void:
    var command_grid := create_command_grid(3)
    assert_null(command_grid.get_cell(-1, 0))
    assert_null(command_grid.get_cell(0, -1))
    assert_null(command_grid.get_cell(command_grid._rows, 0))
    assert_null(command_grid.get_cell(command_grid._rows + 1, 0))
    assert_null(command_grid.get_cell(0, command_grid._cols))
    assert_null(command_grid.get_cell(0, command_grid._cols + 1))


func test_get_add_command_cell() -> void:
    var command_grid := create_command_grid(3)
    var cell := command_grid.get_add_command_cell()
    assert_not_null(cell)
    if cell != null:
        assert_eq(cell.placeholder_text, "Add Command…")


func test_command_name_cell_titles() -> void:
    var command_grid := create_command_grid(3)
    var expected_titles: Array[String] = ["New Tab", "Close Tab", "New Window"]
    var command_name_cell_titles: Array[String] = []

    for row in command_grid._rows:
        var cell := command_grid.get_cell(row, 0)
        if cell is TextCell:
            command_name_cell_titles.append((cell as TextCell).text)

    assert_eq_deep(command_name_cell_titles, expected_titles)


func test_find_command_row() -> void:
    var command_grid := create_command_grid(3)
    assert_eq(command_grid.find_command_row("New Tab"), 0)
    assert_eq(command_grid.find_command_row("new tab"), 0)
    assert_eq(command_grid.find_command_row("Close Tab"), 1)
    assert_eq(command_grid.find_command_row("close tab"), 1)
    assert_eq(command_grid.find_command_row("New Window"), 3)
    assert_eq(command_grid.find_command_row("new window"), 3)
    assert_lt(command_grid.find_command_row("unknown command"), 0)


func test_get_focus_cell() -> void:
    var command_grid := create_command_grid(3)
    var text_cell: TextCell = command_grid.get_cell(0, 0)
    text_cell.grab_focus()
    assert_eq(command_grid.get_focus_cell(), text_cell)

    var program_hotkey_text_cell: ProgramHotkeyTextCell = command_grid.get_cell(1, 2)
    program_hotkey_text_cell.grab_focus()
    assert_eq(command_grid.get_focus_cell(), program_hotkey_text_cell)

    var user_hotkey_text_cell: UserHotkeyTextCell = command_grid.get_cell(3, 5)
    user_hotkey_text_cell.grab_focus()
    assert_eq(command_grid.get_focus_cell(), user_hotkey_text_cell)

    var user_hotkey_program_checkbox: UserHotkeyProgramCheckbox = command_grid.get_cell(3, 6)
    user_hotkey_program_checkbox.grab_focus()
    assert_eq(command_grid.get_focus_cell(), user_hotkey_program_checkbox)


func test_get_focus_cell_returns_null_if_no_cell_has_input_focus() -> void:
    var command_grid := create_command_grid(3)
    var cell: Control = command_grid.get_cell(1, 1)
    cell.grab_focus() # grab and release focus
    cell.release_focus()
    assert_null(command_grid.get_focus_cell())


func test_get_cell_coords() -> void:
    var command_grid := create_command_grid(3)
    assert_eq(command_grid.get_cell_coords(command_grid.get_cell(0, 3)), Vector2i(3, 0))
    assert_eq(command_grid.get_cell_coords(command_grid.get_cell(1, 3)), Vector2i(3, 1))
    assert_eq(command_grid.get_cell_coords(command_grid.get_cell(2, 3)), Vector2i(3, 2))
    assert_eq(command_grid.get_cell_coords(command_grid.get_cell(3, 3)), Vector2i(3, 3))


func test_can_enter_and_save_a_new_command_name() -> void:
    var command_grid := create_command_grid(3)
    var cell: TextCell = command_grid.get_cell(1, 0)
    enter_text_and_emit_changed_signal(cell, "New Command Name")
    @warning_ignore("unsafe_call_argument")
    assert_eq(command_grid._db.select_value("command", "command_id=5", "name"), "New Command Name")


func test_cannot_save_an_empty_command_name() -> void:
    var command_grid := create_command_grid(3)
    var cell: TextCell = command_grid.get_cell(1, 0)
    enter_text_and_emit_changed_signal(cell, "")
    @warning_ignore("unsafe_call_argument")
    assert_eq(command_grid._db.select_value("command", "command_id=5", "name"), "Close Tab")


func test_entering_an_empty_command_name_will_change_the_cell_text_back_to_the_old_name() -> void:
    var command_grid := create_command_grid(3)
    var cell: TextCell = command_grid.get_cell(1, 0)
    enter_text_and_emit_changed_signal(cell, "")
    assert_eq(cell.text, "Close Tab")


func test_can_change_and_save_a_program_command_hotkey() -> void:
    var command_grid := create_command_grid(3)
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(1, 4)
    enter_text_and_emit_changed_signal(cell, "Ctrl+F4")
    # new, saved hotkey
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+F4"]))
    # old, deleted hotkey
    assert_false(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+W"]))


func test_cannot_change_a_program_command_hotkey_to_an_already_existing_one() -> void:
    var command_grid := create_command_grid(3)
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(1, 3)
    enter_text_and_emit_changed_signal(cell, "Ctrl+W")
    # database error
    assert_engine_error("UNIQUE constraint failed")
    # cell text changed back to the old hotkey
    assert_eq(cell.text, "Ctrl+F4")
    # old and new hotkeys still exist
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+W"]))
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+F4"]))


func test_can_delete_an_existing_program_command_hotkey_by_removing_all_text_from_a_cell_belonging_to_an_existing_program_command() -> void:
    var command_grid := create_command_grid(3)
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(1, 4)
    enter_text_and_emit_changed_signal(cell, "")
    # deleted hotkey
    assert_false(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+W"]))
    # making sure no empty hotkey was created
    assert_false(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, ""]))


func test_can_create_a_new_program_command_hotkey_by_entering_text_into_an_empty_cell_belonging_to_an_existing_program_command() -> void:
    var command_grid := create_command_grid(3)
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(2, 4)
    enter_text_and_emit_changed_signal(cell, "Ctrl+F4")
    # new hotkey was added
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+F4"]))


func test_can_create_a_new_program_command_hotkey_by_entering_text_into_an_empty_cell_that_doesnt_belong_to_an_existing_program_command() -> void:
    var command_grid := create_command_grid(3)
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(3, 4)
    enter_text_and_emit_changed_signal(cell, "Ctrl+F4")
    # new proggram command was added
    assert_true(command_grid._db.rows_exist("program_command", "program_id=%d AND command_id=%d" % [cell.program_id, cell.command_id]))
    # new hotkey was added
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+F4"]))


func test_can_add_a_second_hotkey_after_creating_a_new_program_command_hotkey() -> void:
    var command_grid := create_command_grid(3)
    var cell1: ProgramHotkeyTextCell = command_grid.get_cell(1, 1)
    var cell2: ProgramHotkeyTextCell = command_grid.get_cell(2, 1)
    enter_text_and_emit_changed_signal(cell1, "Shift+1")
    enter_text_and_emit_changed_signal(cell2, "Shift+2")
    # new proggram command was added
    assert_true(command_grid._db.rows_exist("program_command", "program_id=%d AND command_id=%d" % [cell1.program_id, cell1.command_id]))
    # new hotkeys were added
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell1.program_id, cell1.command_id, "Shift+1"]))
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell2.program_id, cell2.command_id, "Shift+2"]))


func test_cannot_create_a_new_program_command_hotkey_if_it_already_exists_for_this_program_command() -> void:
    var command_grid := create_command_grid(3)
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(2, 4)
    enter_text_and_emit_changed_signal(cell, "Ctrl+W")
    # database error
    assert_engine_error("UNIQUE constraint failed")
    # cell text changed back to being empty
    assert_eq(cell.text, "")
    # hotkey was not added
    var rows: Array = command_grid._db.select_rows("program_command_hotkey", "program_id=%d AND command_id=%d" % [cell.program_id, cell.command_id], ["hotkey"])
    assert_eq(rows.size(), 1)


func test_can_change_a_user_hotkey() -> void:
    var command_grid := create_command_grid(3)
    var cell: UserHotkeyTextCell = command_grid.get_cell(1, 5)
    var old_user_hotkey_id := cell.user_hotkey_id
    enter_text_and_emit_changed_signal(cell, "Ctrl+W")
    # user_hotkey_id of the cell has not changed
    assert_gt(cell.user_hotkey_id, 0)
    assert_eq(cell.user_hotkey_id, old_user_hotkey_id)
    # new, saved hotkey
    assert_true(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, "Ctrl+W"]))
    # old, deleted hotkey
    assert_false(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, "Ctrl+F4"]))


func test_can_delete_a_user_hotkey_by_clearing_the_cell() -> void:
    var command_grid := create_command_grid(3)
    var cell: UserHotkeyTextCell = command_grid.get_cell(1, 5)
    enter_text_and_emit_changed_signal(cell, "")
    # user_hotkey_id of the cell is now zero
    assert_eq(cell.user_hotkey_id, 0)
    # deleted hotkey
    assert_false(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, "Ctrl+F4"]))
    # making sure no empty hotkey was created
    assert_false(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, ""]))


func test_can_create_a_user_hotkey_by_entering_text_into_an_empty_cell() -> void:
    var command_grid := create_command_grid(3)
    var cell: UserHotkeyTextCell = command_grid.get_cell(0, 5)
    enter_text_and_emit_changed_signal(cell, "Ctrl+T")
    # assign new user_hotkey_id to cell
    assert_gt(cell.user_hotkey_id, 0)
    # new hotkey
    assert_true(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, "Ctrl+T"]))


func test_can_assign_user_hotkey_program() -> void:
    var command_grid := create_command_grid(3)
    var checkbox: UserHotkeyProgramCheckbox = command_grid.get_cell(1, 8)
    checkbox.button_pressed = true
    assert_true(checkbox.button_pressed)
    assert_true(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [checkbox.user_hotkey_id, checkbox.program_id]))


func test_can_unassign_user_hotkey_program() -> void:
    var command_grid := create_command_grid(3)
    var checkbox: UserHotkeyProgramCheckbox = command_grid.get_cell(1, 7)
    checkbox.button_pressed = false
    assert_false(checkbox.button_pressed)
    assert_false(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [checkbox.user_hotkey_id, checkbox.program_id]))


func test_after_creating_a_new_user_hotkey_the_program_assignment_checkboxes_are_enabled_and_unchecked() -> void:
    var command_grid := create_command_grid(3)
    var cell: UserHotkeyTextCell = command_grid.get_cell(0, 5)
    enter_text_and_emit_changed_signal(cell, "Ctrl+Space")
    for col in range(6, 10):
        var checkbox: UserHotkeyProgramCheckbox = command_grid.get_cell(0, col)
        assert_eq(checkbox.user_hotkey_id, cell.user_hotkey_id)
        assert_false(checkbox.disabled)
        assert_false(checkbox.button_pressed)


func test_after_creating_a_new_user_hotkey_the_program_assignment_checkboxes_work() -> void:
    var command_grid := create_command_grid(3)
    var cell: UserHotkeyTextCell = command_grid.get_cell(0, 5)
    enter_text_and_emit_changed_signal(cell, "Ctrl+Space")
    for col in range(6, 10):
        var checkbox: UserHotkeyProgramCheckbox = command_grid.get_cell(0, col)
        checkbox.button_pressed = true
        assert_true(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [checkbox.user_hotkey_id, checkbox.program_id]))


func test_after_deleting_a_user_hotkey_the_program_assignment_checkboxes_are_disabled_and_unchecked() -> void:
    var command_grid := create_command_grid(3)
    var cell: UserHotkeyTextCell = command_grid.get_cell(1, 5)
    enter_text_and_emit_changed_signal(cell, "")
    for col in range(6, 10):
        var checkbox: UserHotkeyProgramCheckbox = command_grid.get_cell(1, col)
        assert_eq(checkbox.user_hotkey_id, 0)
        assert_true(checkbox.disabled)
        assert_false(checkbox.button_pressed)


func test_after_changing_a_user_hotkey_the_program_assignment_checkboxes_dont_change() -> void:
    var command_grid := create_command_grid(3)
    @warning_ignore_start("unsafe_call_argument")
    var cell: UserHotkeyTextCell = command_grid.get_cell(1, 5)
    var old_state: Dictionary[int, Dictionary]
    for col in range(6, 10):
        var checkbox: UserHotkeyProgramCheckbox = command_grid.get_cell(1, col)
        old_state[col] = {"user_hotkey_id": checkbox.user_hotkey_id, "disabled": checkbox.disabled, "button_pressed": checkbox.button_pressed}
    enter_text_and_emit_changed_signal(cell, "Ctrl+Space")
    for col in range(6, 10):
        var checkbox: UserHotkeyProgramCheckbox = command_grid.get_cell(1, col)
        assert_eq(checkbox.user_hotkey_id, old_state[col]["user_hotkey_id"])
        assert_eq(checkbox.disabled, old_state[col]["disabled"])
        assert_eq(checkbox.button_pressed, old_state[col]["button_pressed"])
    @warning_ignore_restore("unsafe_call_argument")


var test_entering_a_command_into_the_add_command_cell_params := [
    {
        "_": "entering a new command creates a new command and adds it to the table",
        "assign_programs_to_user_hotkey": [],
        "command_name_input": "New Command",
        "command_name_expected": "New Command",
        "check_that_a_new_command_has_been_added_to_the_database": true,
        "check_that_no_new_command_has_been_added_to_the_database": false,
        "expected_user_hotkey": "",
        "expected_user_hotkey_id": 0,
        "expect_checkboxes_to_be_disabled": true,
        "expected_checked_checkboxes": {7: false, 8: false, 9: false, 10: false},
    },
    {
        "_": "entering an existing command without an assigned user hotkey adds it to the table and disables the checkboxes",
        "assign_programs_to_user_hotkey": [],
        "command_name_input": "Quit",
        "command_name_expected": "Quit",
        "check_that_a_new_command_has_been_added_to_the_database": false,
        "check_that_no_new_command_has_been_added_to_the_database": true,
        "expected_user_hotkey": "",
        "expected_user_hotkey_id": 0,
        "expect_checkboxes_to_be_disabled": true,
        "expected_checked_checkboxes": {7: false, 8: false, 9: false, 10: false},
    },
    {
        "_": "entering an existing command with an assigned user hotkey but no assigned programs adds it to the table and enables the checkboxes without checking them",
        "assign_programs_to_user_hotkey": [],
        "command_name_input": "go to file",
        "command_name_expected": "Go to File",
        "check_that_a_new_command_has_been_added_to_the_database": false,
        "check_that_no_new_command_has_been_added_to_the_database": true,
        "expected_user_hotkey": "Ctrl+P",
        "expected_user_hotkey_id": 1,
        "expect_checkboxes_to_be_disabled": false,
        "expected_checked_checkboxes": {7: false, 8: false, 9: false, 10: false},
    },
    {
        "_": "entering an existing command with an assigned user hotkey and assigned programs adds it to the table and enables the checkboxes and checks some of them",
        "assign_programs_to_user_hotkey": [ {"user_hotkey_id": 1, "program_id": 8}, {"user_hotkey_id": 1, "program_id": 9}],
        "command_name_input": "go to file",
        "command_name_expected": "Go to File",
        "check_that_a_new_command_has_been_added_to_the_database": false,
        "check_that_no_new_command_has_been_added_to_the_database": true,
        "expected_user_hotkey": "Ctrl+P",
        "expected_user_hotkey_id": 1,
        "expect_checkboxes_to_be_disabled": false,
        "expected_checked_checkboxes": {7: false, 8: true, 9: true, 10: false},
    },
]

func test_entering_a_command_into_the_add_command_cell(params: Dictionary = use_parameters(test_entering_a_command_into_the_add_command_cell_params)) -> void:
    @warning_ignore_start("unsafe_call_argument")
    var command_grid := create_command_grid(3)
    var add_command_cell: TextCell = command_grid.get_add_command_cell()
    var old_num_rows := command_grid._rows
    var old_num_children := command_grid.get_child_count()
    var old_command_table_row_count := command_grid._db.count_rows("command")

    # assign some programs to the user hotkey
    var assign_programs_to_user_hotkey: Array = params["assign_programs_to_user_hotkey"]
    if !assign_programs_to_user_hotkey.is_empty():
        assert_true(command_grid._db.insert_rows("user_hotkey_program", assign_programs_to_user_hotkey))

    enter_text_and_emit_changed_signal(add_command_cell, params["command_name_input"])
    assert_eq(add_command_cell.text, "") # the AddCommand text field is once again empty

    if params["check_that_a_new_command_has_been_added_to_the_database"]: assert_eq(command_grid._db.count_rows("command"), old_command_table_row_count + 1)
    if params["check_that_no_new_command_has_been_added_to_the_database"]: assert_eq(command_grid._db.count_rows("command"), old_command_table_row_count)

    # a new row has been added to the grid
    assert_eq(command_grid._rows, old_num_rows + 1)
    assert_eq(command_grid.get_child_count(), old_num_children + command_grid._cols)

    # the new row of cells has been added to the bottom of the table, above the final row with the AddCommand button
    var command_grid_row := command_grid.find_command_row(params["command_name_input"])
    assert_eq(command_grid_row, command_grid._rows - 1)

    # query command data
    var row: Variant = command_grid._db.select_row("command", "name='%s'" % params["command_name_input"], ["command_id", "name"])
    var command_id: int = row["command_id"]
    var command_name: String = row["name"]
    assert_gt(command_id, 0)
    assert_eq(command_name, params["command_name_expected"])

    # check the new, added command cells
    var command_name_cell: TextCell = command_grid.get_cell(command_grid_row, 0)
    var user_hotkey_cell: UserHotkeyTextCell = command_grid.get_cell(command_grid_row, command_grid._num_programs + 1)
    assert_not_null(command_name_cell)
    assert_not_null(user_hotkey_cell)
    assert_eq(command_name_cell.text, command_name)
    assert_eq(user_hotkey_cell.command_id, command_id)
    assert_eq(user_hotkey_cell.user_hotkey_id, params["expected_user_hotkey_id"])
    assert_eq(user_hotkey_cell.text, params["expected_user_hotkey"])

    for col in range(1, command_grid._num_programs + 1):
        var cell: ProgramHotkeyTextCell = command_grid.get_cell(command_grid_row, col)
        assert_not_null(cell)
        assert_eq(cell.command_id, command_id)
        assert_gt(cell.program_id, 0)

    for col in range(command_grid._num_programs + 2, command_grid._num_programs + 2 + command_grid._num_programs):
        var checkbox: UserHotkeyProgramCheckbox = command_grid.get_cell(command_grid_row, col)
        assert_not_null(checkbox)
        assert_gt(checkbox.program_id, 0)
        assert_eq(checkbox.user_hotkey_id, params["expected_user_hotkey_id"])
        assert_eq(checkbox.disabled, params["expect_checkboxes_to_be_disabled"])
        assert_eq(checkbox.button_pressed, params["expected_checked_checkboxes"][checkbox.program_id])
    @warning_ignore_restore("unsafe_call_argument")


func test_entering_a_command_that_is_already_in_the_table_doesnt_add_a_new_row() -> void:
    var command_grid := create_command_grid(3)
    var add_command_cell: TextCell = command_grid.get_add_command_cell()
    var old_num_rows := command_grid._rows
    var old_num_children := command_grid.get_child_count()
    var old_command_row := command_grid.find_command_row("Close Tab")
    var old_command_table_row_count := command_grid._db.count_rows("command")
    enter_text_and_emit_changed_signal(add_command_cell, "Close Tab")
    # the AddCommand text field is once again empty
    assert_eq(add_command_cell.text, "")
    # no new command has been added to the database
    assert_eq(command_grid._db.count_rows("command"), old_command_table_row_count)
    # no new row has been added to the grid
    assert_eq(command_grid._rows, old_num_rows)
    assert_eq(command_grid.get_child_count(), old_num_children)
    assert_eq(command_grid.find_command_row("Close Tab"), old_command_row)


func test_can_use_the_newly_added_command_cells_after_adding_a_command() -> void:
    var command_grid := create_command_grid(3)
    var add_command_cell: TextCell = command_grid.get_add_command_cell()

    # assign some programs to the "Go to File" command and add it
    var command_id := 1
    var user_hotkey_id := 1
    var row := 4
    command_grid._db.insert_rows("user_hotkey_program", [ {"user_hotkey_id": user_hotkey_id, "program_id": 8}, {"user_hotkey_id": user_hotkey_id, "program_id": 9}])
    enter_text_and_emit_changed_signal(add_command_cell, "Go to File")

    var command_name_cell: TextCell = command_grid.get_cell(row, 0)
    enter_text_and_emit_changed_signal(command_name_cell, "Changed Name")
    @warning_ignore("unsafe_call_argument")
    assert_eq(command_grid._db.select_value("command", "command_id=%d" % command_id, "name"), "Changed Name")

    var program_hotkey_cell: ProgramHotkeyTextCell = command_grid.get_cell(row, 1)
    enter_text_and_emit_changed_signal(program_hotkey_cell, "Shift+1")
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [7, command_id, "Shift+1"]))
    enter_text_and_emit_changed_signal(program_hotkey_cell, "")
    assert_false(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [7, command_id, "Shift+1"]))

    var user_hotkey_cell: UserHotkeyTextCell = command_grid.get_cell(row, 5)
    enter_text_and_emit_changed_signal(user_hotkey_cell, "Ctrl+Space")
    assert_true(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [command_id, "Ctrl+Space"]))
    assert_false(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [command_id, "Ctrl+P"]))

    var checkbox: UserHotkeyProgramCheckbox = command_grid.get_cell(row, 6)
    checkbox.button_pressed = true
    assert_true(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [user_hotkey_id, 7]))
    checkbox.button_pressed = false
    assert_false(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [user_hotkey_id, 7]))

    checkbox = command_grid.get_cell(row, 7)
    checkbox.button_pressed = false
    assert_false(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [user_hotkey_id, 8]))
    checkbox.button_pressed = true
    assert_true(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [user_hotkey_id, 8]))

    # create and add a new command
    command_id = 8
    user_hotkey_id = 5
    row = 5
    enter_text_and_emit_changed_signal(add_command_cell, "New Command")

    command_name_cell = command_grid.get_cell(row, 0)
    enter_text_and_emit_changed_signal(command_name_cell, "Very New Command")
    @warning_ignore("unsafe_call_argument")
    assert_eq(command_grid._db.select_value("command", "command_id=%d" % command_id, "name"), "Very New Command")

    program_hotkey_cell = command_grid.get_cell(row, 2)
    enter_text_and_emit_changed_signal(program_hotkey_cell, "Alt+2")
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [8, command_id, "Alt+2"]))

    user_hotkey_cell = command_grid.get_cell(row, 5)
    enter_text_and_emit_changed_signal(user_hotkey_cell, "Ctrl+Alt+3")
    assert_true(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [command_id, "Ctrl+Alt+3"]))

    checkbox = command_grid.get_cell(row, 7)
    checkbox.button_pressed = true
    assert_true(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [user_hotkey_id, 8]))
    checkbox.button_pressed = false
    assert_false(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=%d AND program_id=%d" % [user_hotkey_id, 8]))
