extends GutTest

var _input_sender := GutInputSender.new(Input)


func create_command_grid(programgroup_id: int) -> CommandGrid:
    var db: Database = Database.new()
    db.open(":memory:")

    var programs := CommandsScreen.query_programs(db, programgroup_id)
    var program_abbreviations := CommandsScreen.query_program_abbreviations(db, programgroup_id)
    var program_icons := CommandsScreen.query_program_icons(db, programgroup_id)
    var commands := CommandsScreen.query_commands(db, programgroup_id)
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
    command_grid.setup(db, programgroup_id, programs, program_abbreviations, program_icons, combined_commands, program_command_hotkeys, user_hotkeys, user_hotkey_programs)
    return add_child_autofree(command_grid)


func after_each() -> void:
    _input_sender.release_all()
    _input_sender.clear()


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
    assert_eq(command_grid.number_of_programs(), 4)


func test_get_cell_returns_grid_controls() -> void:
    var command_grid := create_command_grid(3)
    assert_is(command_grid.get_cell(0, 0), TextCell)
    assert_is(command_grid.get_cell(1, 0), TextCell)
    assert_is(command_grid.get_cell(2, 0), Control)
    assert_is(command_grid.get_cell(3, 0), TextCell)
    assert_is(command_grid.get_cell(0, 9), UserHotkeyProgramCheckboxCell)
    assert_is(command_grid.get_cell(1, 9), UserHotkeyProgramCheckboxCell)
    assert_is(command_grid.get_cell(2, 9), Control)
    assert_is(command_grid.get_cell(3, 9), UserHotkeyProgramCheckboxCell)


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

    var user_hotkey_program_checkbox: UserHotkeyProgramCheckboxCell = command_grid.get_cell(3, 6)
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
    assert_eq(command_grid._db.select_value("command", "name", "command_id=?", [5]), "New Command Name")


func test_cannot_save_an_empty_command_name() -> void:
    var command_grid := create_command_grid(3)
    var cell: TextCell = command_grid.get_cell(1, 0)
    enter_text_and_emit_changed_signal(cell, "")
    @warning_ignore("unsafe_call_argument")
    assert_eq(command_grid._db.select_value("command", "name", "command_id=?", [5]), "Close Tab")


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
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell.program_id, cell.command_id, "Ctrl+F4"]))
    # old, deleted hotkey
    assert_false(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell.program_id, cell.command_id, "Ctrl+W"]))


func test_cannot_change_a_program_command_hotkey_to_an_already_existing_one() -> void:
    var command_grid := create_command_grid(3)
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(1, 3)
    enter_text_and_emit_changed_signal(cell, "Ctrl+W")
    # database error
    assert_engine_error("UNIQUE constraint failed")
    # cell text changed back to the old hotkey
    assert_eq(cell.text, "Ctrl+F4")
    # old and new hotkeys still exist
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell.program_id, cell.command_id, "Ctrl+W"]))
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell.program_id, cell.command_id, "Ctrl+F4"]))


func test_can_delete_an_existing_program_command_hotkey_by_removing_all_text_from_a_cell_belonging_to_an_existing_program_command() -> void:
    var command_grid := create_command_grid(3)
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(1, 4)
    enter_text_and_emit_changed_signal(cell, "")
    # deleted hotkey
    assert_false(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell.program_id, cell.command_id, "Ctrl+W"]))
    # making sure no empty hotkey was created
    assert_false(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell.program_id, cell.command_id, ""]))


func test_can_create_a_new_program_command_hotkey_by_entering_text_into_an_empty_cell_belonging_to_an_existing_program_command() -> void:
    var command_grid := create_command_grid(3)
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(2, 4)
    enter_text_and_emit_changed_signal(cell, "Ctrl+F4")
    # new hotkey was added
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell.program_id, cell.command_id, "Ctrl+F4"]))


func test_can_create_a_new_program_command_hotkey_by_entering_text_into_an_empty_cell_that_doesnt_belong_to_an_existing_program_command() -> void:
    var command_grid := create_command_grid(3)
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(3, 4)
    enter_text_and_emit_changed_signal(cell, "Ctrl+F4")
    # new proggram command hotkey was added
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell.program_id, cell.command_id, "Ctrl+F4"]))


func test_can_add_a_second_hotkey_after_creating_a_new_program_command_hotkey() -> void:
    var command_grid := create_command_grid(3)
    var cell1: ProgramHotkeyTextCell = command_grid.get_cell(1, 1)
    var cell2: ProgramHotkeyTextCell = command_grid.get_cell(2, 1)
    enter_text_and_emit_changed_signal(cell1, "Shift+1")
    enter_text_and_emit_changed_signal(cell2, "Shift+2")
    # new proggram command hotkeys were added
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell1.program_id, cell1.command_id, "Shift+1"]))
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [cell2.program_id, cell2.command_id, "Shift+2"]))


func test_cannot_create_a_new_program_command_hotkey_if_it_already_exists_for_this_program_command() -> void:
    var command_grid := create_command_grid(3)
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(2, 4)
    enter_text_and_emit_changed_signal(cell, "Ctrl+W")
    # database error
    assert_engine_error("UNIQUE constraint failed")
    # cell text changed back to being empty
    assert_eq(cell.text, "")
    # hotkey was not added
    var rows: Array = command_grid._db.select_rows("program_command_hotkey", ["hotkey"], "program_id=? AND command_id=?", [cell.program_id, cell.command_id])
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
    assert_true(command_grid._db.rows_exist("user_hotkey", "command_id=? AND hotkey=?", [cell.command_id, "Ctrl+W"]))
    # old, deleted hotkey
    assert_false(command_grid._db.rows_exist("user_hotkey", "command_id=? AND hotkey=?", [cell.command_id, "Ctrl+F4"]))


func test_can_delete_a_user_hotkey_by_clearing_the_cell() -> void:
    var command_grid := create_command_grid(3)
    var cell: UserHotkeyTextCell = command_grid.get_cell(1, 5)
    enter_text_and_emit_changed_signal(cell, "")
    # user_hotkey_id of the cell is now zero
    assert_eq(cell.user_hotkey_id, 0)
    # deleted hotkey
    assert_false(command_grid._db.rows_exist("user_hotkey", "command_id=? AND hotkey=?", [cell.command_id, "Ctrl+F4"]))
    # making sure no empty hotkey was created
    assert_false(command_grid._db.rows_exist("user_hotkey", "command_id=? AND hotkey=?", [cell.command_id, ""]))


func test_can_create_a_user_hotkey_by_entering_text_into_an_empty_cell() -> void:
    var command_grid := create_command_grid(3)
    var cell: UserHotkeyTextCell = command_grid.get_cell(0, 5)
    enter_text_and_emit_changed_signal(cell, "Ctrl+T")
    # assign new user_hotkey_id to cell
    assert_gt(cell.user_hotkey_id, 0)
    # new hotkey
    assert_true(command_grid._db.rows_exist("user_hotkey", "command_id=? AND hotkey=?", [cell.command_id, "Ctrl+T"]))


func test_can_assign_user_hotkey_program() -> void:
    var command_grid := create_command_grid(3)
    var checkbox: UserHotkeyProgramCheckboxCell = command_grid.get_cell(1, 8)
    checkbox.button_pressed = true
    assert_true(checkbox.button_pressed)
    assert_true(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=? AND program_id=?", [checkbox.user_hotkey_id, checkbox.program_id]))


func test_can_unassign_user_hotkey_program() -> void:
    var command_grid := create_command_grid(3)
    var checkbox: UserHotkeyProgramCheckboxCell = command_grid.get_cell(1, 7)
    checkbox.button_pressed = false
    assert_false(checkbox.button_pressed)
    assert_false(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=? AND program_id=?", [checkbox.user_hotkey_id, checkbox.program_id]))


func test_after_creating_a_new_user_hotkey_the_program_assignment_checkboxes_are_enabled_and_unchecked() -> void:
    var command_grid := create_command_grid(3)
    var cell: UserHotkeyTextCell = command_grid.get_cell(0, 5)
    enter_text_and_emit_changed_signal(cell, "Ctrl+Space")
    for col in range(6, 10):
        var checkbox: UserHotkeyProgramCheckboxCell = command_grid.get_cell(0, col)
        assert_eq(checkbox.user_hotkey_id, cell.user_hotkey_id)
        assert_false(checkbox.disabled)
        assert_false(checkbox.button_pressed)


func test_after_creating_a_new_user_hotkey_the_program_assignment_checkboxes_work() -> void:
    var command_grid := create_command_grid(3)
    var cell: UserHotkeyTextCell = command_grid.get_cell(0, 5)
    enter_text_and_emit_changed_signal(cell, "Ctrl+Space")
    for col in range(6, 10):
        var checkbox: UserHotkeyProgramCheckboxCell = command_grid.get_cell(0, col)
        checkbox.button_pressed = true
        assert_true(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=? AND program_id=?", [checkbox.user_hotkey_id, checkbox.program_id]))


func test_after_deleting_a_user_hotkey_the_program_assignment_checkboxes_are_disabled_and_unchecked() -> void:
    var command_grid := create_command_grid(3)
    var cell: UserHotkeyTextCell = command_grid.get_cell(1, 5)
    enter_text_and_emit_changed_signal(cell, "")
    for col in range(6, 10):
        var checkbox: UserHotkeyProgramCheckboxCell = command_grid.get_cell(1, col)
        assert_eq(checkbox.user_hotkey_id, 0)
        assert_true(checkbox.disabled)
        assert_false(checkbox.button_pressed)


func test_after_changing_a_user_hotkey_the_program_assignment_checkboxes_dont_change() -> void:
    var command_grid := create_command_grid(3)
    @warning_ignore_start("unsafe_call_argument")
    var cell: UserHotkeyTextCell = command_grid.get_cell(1, 5)
    var old_state: Dictionary[int, Dictionary]
    for col in range(6, 10):
        var checkbox: UserHotkeyProgramCheckboxCell = command_grid.get_cell(1, col)
        old_state[col] = {"user_hotkey_id": checkbox.user_hotkey_id, "disabled": checkbox.disabled, "button_pressed": checkbox.button_pressed}
    enter_text_and_emit_changed_signal(cell, "Ctrl+Space")
    for col in range(6, 10):
        var checkbox: UserHotkeyProgramCheckboxCell = command_grid.get_cell(1, col)
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
    var row: Variant = command_grid._db.select_row("command", ["command_id", "name"], "name=?", [params["command_name_input"]])
    var command_id: int = row["command_id"]
    var command_name: String = row["name"]
    assert_gt(command_id, 0)
    assert_eq(command_name, params["command_name_expected"])

    # check the new, added command cells
    var command_name_cell: TextCell = command_grid.get_cell(command_grid_row, 0)
    var user_hotkey_cell: UserHotkeyTextCell = command_grid.get_cell(command_grid_row, command_grid.number_of_programs() + 1)
    assert_not_null(command_name_cell)
    assert_not_null(user_hotkey_cell)
    assert_eq(command_name_cell.text, command_name)
    assert_eq(user_hotkey_cell.command_id, command_id)
    assert_eq(user_hotkey_cell.user_hotkey_id, params["expected_user_hotkey_id"])
    assert_eq(user_hotkey_cell.text, params["expected_user_hotkey"])

    for col in range(1, command_grid.number_of_programs() + 1):
        var cell: ProgramHotkeyTextCell = command_grid.get_cell(command_grid_row, col)
        assert_not_null(cell)
        assert_eq(cell.command_id, command_id)
        assert_gt(cell.program_id, 0)

    for col in range(command_grid.number_of_programs() + 2, command_grid.number_of_programs() + 2 + command_grid.number_of_programs()):
        var checkbox: UserHotkeyProgramCheckboxCell = command_grid.get_cell(command_grid_row, col)
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
    assert_eq(command_grid._db.select_value("command", "name", "command_id=?", [command_id]), "Changed Name")

    var program_hotkey_cell: ProgramHotkeyTextCell = command_grid.get_cell(row, 1)
    enter_text_and_emit_changed_signal(program_hotkey_cell, "Shift+1")
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [7, command_id, "Shift+1"]))
    enter_text_and_emit_changed_signal(program_hotkey_cell, "")
    assert_false(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [7, command_id, "Shift+1"]))

    var user_hotkey_cell: UserHotkeyTextCell = command_grid.get_cell(row, 5)
    enter_text_and_emit_changed_signal(user_hotkey_cell, "Ctrl+Space")
    assert_true(command_grid._db.rows_exist("user_hotkey", "command_id=? AND hotkey=?", [command_id, "Ctrl+Space"]))
    assert_false(command_grid._db.rows_exist("user_hotkey", "command_id=? AND hotkey=?", [command_id, "Ctrl+P"]))

    var checkbox: UserHotkeyProgramCheckboxCell = command_grid.get_cell(row, 6)
    checkbox.button_pressed = true
    assert_true(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=? AND program_id=?", [user_hotkey_id, 7]))
    checkbox.button_pressed = false
    assert_false(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=? AND program_id=?", [user_hotkey_id, 7]))

    checkbox = command_grid.get_cell(row, 7)
    checkbox.button_pressed = false
    assert_false(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=? AND program_id=?", [user_hotkey_id, 8]))
    checkbox.button_pressed = true
    assert_true(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=? AND program_id=?", [user_hotkey_id, 8]))

    # create and add a new command
    command_id = 8
    user_hotkey_id = 5
    row = 5
    enter_text_and_emit_changed_signal(add_command_cell, "New Command")

    command_name_cell = command_grid.get_cell(row, 0)
    enter_text_and_emit_changed_signal(command_name_cell, "Very New Command")
    @warning_ignore("unsafe_call_argument")
    assert_eq(command_grid._db.select_value("command", "name", "command_id=?", [command_id]), "Very New Command")

    program_hotkey_cell = command_grid.get_cell(row, 2)
    enter_text_and_emit_changed_signal(program_hotkey_cell, "Alt+2")
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [8, command_id, "Alt+2"]))

    user_hotkey_cell = command_grid.get_cell(row, 5)
    enter_text_and_emit_changed_signal(user_hotkey_cell, "Ctrl+Alt+3")
    assert_true(command_grid._db.rows_exist("user_hotkey", "command_id=? AND hotkey=?", [command_id, "Ctrl+Alt+3"]))

    checkbox = command_grid.get_cell(row, 7)
    checkbox.button_pressed = true
    assert_true(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=? AND program_id=?", [user_hotkey_id, 8]))
    checkbox.button_pressed = false
    assert_false(command_grid._db.rows_exist("user_hotkey_program", "user_hotkey_id=? AND program_id=?", [user_hotkey_id, 8]))


var test_add_row_actions_params := [
    {
        "_": "action 'add_row_above' for command with multiple rows when on middle row of command",
        "action": "add_row_above",
        "programgroup_id": 1,
        "input_cell_row": 1,
        "input_cell_column": 1,
        "expect_to_add_a_new_grid_row": true,
    },
    {
        "_": "action 'add_row_above' for command with multiple rows when on last row of command",
        "action": "add_row_above",
        "programgroup_id": 1,
        "input_cell_row": 2,
        "input_cell_column": 1,
        "expect_to_add_a_new_grid_row": true,
    },
    {
        "_": "action 'add_row_above' when on first row of command adds row to the previous command",
        "action": "add_row_above",
        "programgroup_id": 1,
        "input_cell_row": 3,
        "input_cell_column": 1,
        "expect_to_add_a_new_grid_row": true,
    },
    {
        "_": "action 'add_row_above' cannot add row if on first table row",
        "action": "add_row_above",
        "programgroup_id": 1,
        "input_cell_row": 0,
        "input_cell_column": 1,
        "expect_to_add_a_new_grid_row": false,
    },
    {
        "_": "action 'add_row_below' for command with only one row",
        "action": "add_row_below",
        "programgroup_id": 3,
        "input_cell_row": 0,
        "input_cell_column": 1,
        "expect_to_add_a_new_grid_row": true,
    },
    {
        "_": "action 'add_row_below' for command with multiple rows when on first row of command",
        "action": "add_row_below",
        "programgroup_id": 1,
        "input_cell_row": 0,
        "input_cell_column": 1,
        "expect_to_add_a_new_grid_row": true,
    },
    {
        "_": "action 'add_row_below' for command with multiple rows when on middle row of command",
        "action": "add_row_below",
        "programgroup_id": 1,
        "input_cell_row": 1,
        "input_cell_column": 1,
        "expect_to_add_a_new_grid_row": true,
    },
    {
        "_": "action 'add_row_below' for command with multiple rows when on last row of command",
        "action": "add_row_below",
        "programgroup_id": 1,
        "input_cell_row": 2,
        "input_cell_column": 1,
        "expect_to_add_a_new_grid_row": true,
    },
    {
        "_": "action 'add_row_below' when on last table row",
        "action": "add_row_below",
        "programgroup_id": 1,
        "input_cell_row": 3,
        "input_cell_column": 1,
        "expect_to_add_a_new_grid_row": true,
    },
    {
        "_": "can add row above when on the AddCommand input field",
        "action": "add_row_above",
        "programgroup_id": 3,
        "focus_AddCommand_input_field": true,
        "expect_to_add_a_new_grid_row": true,
    },
    {
        "_": "cannot add row below when on the AddCommand input field",
        "action": "add_row_below",
        "programgroup_id": 3,
        "focus_AddCommand_input_field": true,
        "expect_to_add_a_new_grid_row": false,
    },
    {
        "_": "cannot add row above if the table is empty",
        "action": "add_row_above",
        "programgroup_id": 5,
        "focus_AddCommand_input_field": true,
        "expect_to_add_a_new_grid_row": false,
    },
    {
        "_": "cannot add row below if the table is empty",
        "action": "add_row_below",
        "programgroup_id": 5,
        "focus_AddCommand_input_field": true,
        "expect_to_add_a_new_grid_row": false,
    },
    {
        "_": "can add row above when on a UserHotkeyProgramCheckboxCell",
        "action": "add_row_above",
        "programgroup_id": 3,
        "input_cell_row": 1,
        "input_cell_column": 8,
        "expect_to_add_a_new_grid_row": true,
    },
    {
        "_": "can add row below when on a UserHotkeyProgramCheckboxCell",
        "action": "add_row_below",
        "programgroup_id": 3,
        "input_cell_row": 1,
        "input_cell_column": 8,
        "expect_to_add_a_new_grid_row": true,
    },
]


func test_add_row_actions(params: Dictionary = use_parameters(test_add_row_actions_params)) -> void:
    @warning_ignore_start("unsafe_call_argument")
    var command_grid := create_command_grid(params["programgroup_id"])
    var old_num_rows := command_grid._rows
    var old_num_children := command_grid.get_child_count()
    var old_command_table_row_count := command_grid._db.count_rows("command")

    # get input cell and row
    var old_input_cell: Control
    if params.get("focus_AddCommand_input_field", false):
        old_input_cell = command_grid.get_add_command_cell()
    else:
        old_input_cell = command_grid.get_cell(params["input_cell_row"], params["input_cell_column"])
    var input_row := command_grid.get_cell_coords(old_input_cell).y

    # input cell grabs focus
    var old_input_cell_text_cell: TextCell = old_input_cell as TextCell
    var old_input_cell_checkbox: UserHotkeyProgramCheckboxCell = old_input_cell as UserHotkeyProgramCheckboxCell
    if old_input_cell_text_cell:
        old_input_cell_text_cell.grab_focus_without_entering_edit_mode()
    if old_input_cell_checkbox:
        old_input_cell_checkbox.grab_focus()

    _input_sender.action_down(params["action"])
    _input_sender.action_up(params["action"])
    await wait_idle_frames(1)

    var old_row := input_row # row index of the previous input row
    var new_row := input_row # row index of the newly added row

    if params["expect_to_add_a_new_grid_row"]:
        if params["action"] == "add_row_above":
            old_row += 1
        else:
            new_row += 1

    # make sure the previous input cell has moved to "old_row" (if it has moved at all)
    assert_eq(command_grid.get_cell_coords(old_input_cell).y, old_row)

    # check if cells have been added
    if params["expect_to_add_a_new_grid_row"]:
        assert_eq(command_grid._rows, old_num_rows + 1)
        assert_eq(command_grid.get_child_count(), old_num_children + command_grid._cols)
    else:
        assert_eq(command_grid._rows, old_num_rows)
        assert_eq(command_grid.get_child_count(), old_num_children)

    # no new row has been added to the "command" database table yet
    assert_eq(command_grid._db.count_rows("command"), old_command_table_row_count)

    # check the new, added command row cells
    if params["expect_to_add_a_new_grid_row"]:
        # the command name and user hotkey cells are just empty Controls
        var command_name_control: Control = command_grid.get_cell(new_row, 0)
        var user_hotkey_control: Control = command_grid.get_cell(new_row, command_grid.number_of_programs() + 1)
        assert_not_null(command_name_control)
        assert_not_null(user_hotkey_control)
        assert_true(command_name_control is Control)
        assert_true(command_name_control is not TextCell)
        assert_true(user_hotkey_control is Control)
        assert_true(user_hotkey_control is not UserHotkeyTextCell)

        var above_row := new_row - 1 # index of the row above the newly added row

        for col in range(1, command_grid.number_of_programs() + 1):
            # get the program hotkey cell from the row above
            var program_hotkey_cell_above: ProgramHotkeyTextCell = command_grid.get_cell(above_row, col)
            assert_not_null(program_hotkey_cell_above)

            var cell: ProgramHotkeyTextCell = command_grid.get_cell(new_row, col)
            assert_not_null(cell)
            assert_eq(cell.command_id, program_hotkey_cell_above.command_id)
            assert_eq(cell.program_id, program_hotkey_cell_above.program_id)

        for col in range(command_grid.number_of_programs() + 2, command_grid.number_of_programs() + 2 + command_grid.number_of_programs()):
            var control: Control = command_grid.get_cell(new_row, col)
            assert_not_null(control)
            assert_true(control is Control)
            assert_true(control is not UserHotkeyProgramCheckboxCell)
    @warning_ignore_restore("unsafe_call_argument")


var test_adding_a_row_moves_the_focus_cell_to_the_new_row_if_possible_params := [
    {
        "_": "focus moves to the ProgramHotkeyTextCell in the added row above",
        "action": "add_row_above",
        "programgroup_id": 3,
        "input_cell_row": 2,
        "input_cell_column": 3,
        "should_move_focus_to_new_row": true,
    },
    {
        "_": "focus moves to the ProgramHotkeyTextCell in the added row below",
        "action": "add_row_below",
        "programgroup_id": 3,
        "input_cell_row": 2,
        "input_cell_column": 3,
        "should_move_focus_to_new_row": true,
    },
    {
        "_": "focus cannot move because the new cell above is empty (Control instead of ProgramHotkeyTextCell)",
        "action": "add_row_above",
        "programgroup_id": 3,
        "input_cell_row": 3,
        "input_cell_column": 5,
        "should_move_focus_to_new_row": false,
    },
    {
        "_": "focus cannot move because the new cell below is empty (Control instead of ProgramHotkeyTextCell)",
        "action": "add_row_below",
        "programgroup_id": 3,
        "input_cell_row": 1,
        "input_cell_column": 5,
        "should_move_focus_to_new_row": false,
    },
]


func test_adding_a_row_moves_the_focus_cell_to_the_new_row_if_possible(params: Dictionary = use_parameters(test_adding_a_row_moves_the_focus_cell_to_the_new_row_if_possible_params)) -> void:
    @warning_ignore_start("unsafe_call_argument")
    var command_grid := create_command_grid(params["programgroup_id"])
    var input_cell: TextCell = command_grid.get_cell(params["input_cell_row"], params["input_cell_column"])
    input_cell.grab_focus_without_entering_edit_mode()
    _input_sender.action_down(params["action"])
    _input_sender.action_up(params["action"])
    await wait_idle_frames(1)

    if params["should_move_focus_to_new_row"]:
        # the current focus cell moved to the new row
        if params["action"] == "add_row_above":
            assert_eq(command_grid.get_focus_cell(), command_grid.get_cell(params["input_cell_row"], params["input_cell_column"]))
        else:
            assert_eq(command_grid.get_focus_cell(), command_grid.get_cell(params["input_cell_row"] + 1, params["input_cell_column"]))
    else:
        # focus cell stayed on its old row
        if params["action"] == "add_row_above":
            assert_eq(command_grid.get_focus_cell(), command_grid.get_cell(params["input_cell_row"] + 1, params["input_cell_column"]))
        else:
            assert_eq(command_grid.get_focus_cell(), command_grid.get_cell(params["input_cell_row"], params["input_cell_column"]))
    @warning_ignore_restore("unsafe_call_argument")


var test_after_adding_a_new_row_focus_text_cells_are_not_in_edit_mode_params := [
    "add_row_above",
    "add_row_below"
]


func test_after_adding_a_new_row_focus_text_cells_are_not_in_edit_mode(action: String = use_parameters(test_after_adding_a_new_row_focus_text_cells_are_not_in_edit_mode_params)) -> void:
    var command_grid := create_command_grid(3)
    var input_cell: TextCell = command_grid.get_cell(2, 3)
    input_cell.grab_focus_without_entering_edit_mode()
    _input_sender.action_down(action)
    _input_sender.action_up(action)
    await wait_idle_frames(1)
    var focus_cell: TextCell = command_grid.get_focus_cell()
    assert_false(focus_cell.is_editing())
