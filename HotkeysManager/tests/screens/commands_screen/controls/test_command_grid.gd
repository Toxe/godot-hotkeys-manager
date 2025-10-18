extends GutTest

const commands_screen_scene: PackedScene = preload("uid://de72ge75p8811")

var commands_screen: CommandsScreen = null
var command_grid: CommandGrid = null


func before_each() -> void:
    var db: Database = Database.new()
    db.open(":memory:")

    const programgroup_id := 3
    commands_screen = commands_screen_scene.instantiate()
    commands_screen.setup(db, programgroup_id)
    add_child(commands_screen)
    command_grid = commands_screen.find_child("CommandGrid", true, false)


func after_each() -> void:
    commands_screen.queue_free()


func enter_text_and_emit_changed_signal(cell: TextCell, new_text: String) -> void:
    var old_text := cell.text
    cell.text = new_text
    cell.changed.emit(cell, old_text, new_text)


func test_grid_child_count() -> void:
    assert_eq(command_grid.get_child_count(), 5 * 10)


func test_number_of_rows() -> void:
    assert_eq(command_grid.rows, 4)


func test_number_of_columns() -> void:
    assert_eq(command_grid.cols, 10)


func test_get_cell_returns_grid_controls() -> void:
    assert_is(command_grid.get_cell(0, 0), TextCell)
    assert_is(command_grid.get_cell(1, 0), TextCell)
    assert_is(command_grid.get_cell(2, 0), Control)
    assert_is(command_grid.get_cell(3, 0), TextCell)
    assert_is(command_grid.get_cell(0, 9), Label)
    assert_is(command_grid.get_cell(1, 9), Label)
    assert_is(command_grid.get_cell(2, 9), Control)
    assert_is(command_grid.get_cell(3, 9), Label)


func test_get_cell_returns_null_for_non_existing_cells() -> void:
    assert_null(command_grid.get_cell(-1, 0))
    assert_null(command_grid.get_cell(0, -1))
    assert_null(command_grid.get_cell(command_grid.rows, 0))
    assert_null(command_grid.get_cell(command_grid.rows + 1, 0))
    assert_null(command_grid.get_cell(0, command_grid.cols))
    assert_null(command_grid.get_cell(0, command_grid.cols + 1))


func test_command_name_cell_titles() -> void:
    var expected_titles: Array[String] = ["New Tab", "Close Tab", "New Window"]
    var command_name_cell_titles: Array[String] = []

    for row in command_grid.rows:
        var cell := command_grid.get_cell(row, 0)
        if cell is TextCell:
            command_name_cell_titles.append((cell as TextCell).text)

    assert_eq_deep(command_name_cell_titles, expected_titles)


func test_can_enter_and_save_a_new_command_name() -> void:
    var cell: TextCell = command_grid.get_cell(1, 0)
    enter_text_and_emit_changed_signal(cell, "New Command Name")
    @warning_ignore("unsafe_call_argument")
    assert_eq(command_grid._db.select_value("command", "command_id=5", "name"), "New Command Name")


func test_cannot_save_an_empty_command_name() -> void:
    var cell: TextCell = command_grid.get_cell(1, 0)
    enter_text_and_emit_changed_signal(cell, "")
    @warning_ignore("unsafe_call_argument")
    assert_eq(command_grid._db.select_value("command", "command_id=5", "name"), "Close Tab")


func test_entering_an_empty_command_name_will_change_the_cell_text_back_to_the_old_name() -> void:
    var cell: TextCell = command_grid.get_cell(1, 0)
    enter_text_and_emit_changed_signal(cell, "")
    assert_eq(cell.text, "Close Tab")


func test_can_change_and_save_a_program_command_hotkey() -> void:
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(1, 4)
    var was_bound := cell.is_bound
    enter_text_and_emit_changed_signal(cell, "Ctrl+F4")
    # cell is_bound has not changed
    assert_eq(cell.is_bound, was_bound)
    # new, saved hotkey
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+F4"]))
    # old, deleted hotkey
    assert_false(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+W"]))


func test_cannot_change_a_program_command_hotkey_to_an_already_existing_one() -> void:
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(1, 3)
    var was_bound := cell.is_bound
    enter_text_and_emit_changed_signal(cell, "Ctrl+W")
    # database error
    assert_engine_error("UNIQUE constraint failed")
    # cell text changed back to the old hotkey
    assert_eq(cell.text, "Ctrl+F4")
    # cell is_bound has not changed
    assert_eq(cell.is_bound, was_bound)
    # old and new hotkeys still exist
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+W"]))
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+F4"]))


func test_can_delete_an_existing_program_command_hotkey_by_removing_all_text_from_a_cell_belonging_to_an_existing_program_command() -> void:
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(1, 4)
    var was_bound := cell.is_bound
    enter_text_and_emit_changed_signal(cell, "")
    # cell is_bound has not changed and the cell is still bound to a program command
    assert_eq(cell.is_bound, was_bound)
    assert_true(cell.is_bound)
    # deleted hotkey
    assert_false(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+W"]))
    # making sure no empty hotkey was created
    assert_false(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, ""]))


func test_can_create_a_new_program_command_hotkey_by_entering_text_into_an_empty_cell_belonging_to_an_existing_program_command() -> void:
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(2, 4)
    var was_bound := cell.is_bound
    enter_text_and_emit_changed_signal(cell, "Ctrl+F4")
    # cell is_bound has not changed
    assert_eq(cell.is_bound, was_bound)
    # new hotkey was added
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+F4"]))


func test_can_create_a_new_program_command_hotkey_by_entering_text_into_an_empty_cell_that_doesnt_belong_to_an_existing_program_command() -> void:
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(3, 4)
    enter_text_and_emit_changed_signal(cell, "Ctrl+F4")
    # cell is now bound to a program command
    assert_true(cell.is_bound)
    # new proggram command was added
    assert_true(command_grid._db.rows_exist("program_command", "program_id=%d AND command_id=%d" % [cell.program_id, cell.command_id]))
    # new hotkey was added
    assert_true(command_grid._db.rows_exist("program_command_hotkey", "program_id=%d AND command_id=%d AND hotkey='%s'" % [cell.program_id, cell.command_id, "Ctrl+F4"]))


func test_can_add_a_second_hotkey_after_creating_a_new_program_command_hotkey() -> void:
    var cell1: ProgramHotkeyTextCell = command_grid.get_cell(1, 1)
    var cell2: ProgramHotkeyTextCell = command_grid.get_cell(2, 1)
    assert_false(cell1.is_bound)
    assert_false(cell2.is_bound)
    enter_text_and_emit_changed_signal(cell1, "Shift+1")
    assert_true(cell1.is_bound)
    assert_true(cell2.is_bound)
    enter_text_and_emit_changed_signal(cell2, "Shift+2")
    assert_true(cell1.is_bound)
    assert_true(cell2.is_bound)


func test_cannot_create_a_new_program_command_hotkey_if_it_already_exists_for_this_program_command() -> void:
    var cell: ProgramHotkeyTextCell = command_grid.get_cell(2, 4)
    var was_bound := cell.is_bound
    enter_text_and_emit_changed_signal(cell, "Ctrl+W")
    # database error
    assert_engine_error("UNIQUE constraint failed")
    # cell text changed back to being empty
    assert_eq(cell.text, "")
    # cell is_bound has not changed
    assert_eq(cell.is_bound, was_bound)
    # hotkey was not added
    var rows: Array = command_grid._db.select_rows("program_command_hotkey", "program_id=%d AND command_id=%d" % [cell.program_id, cell.command_id], ["hotkey"])
    assert_eq(rows.size(), 1)


func test_can_change_a_user_hotkey() -> void:
    var cell: UserHotkeyTextCell = command_grid.get_cell(1, 5)
    enter_text_and_emit_changed_signal(cell, "Ctrl+W")
    # new, saved hotkey
    assert_true(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, "Ctrl+W"]))
    # old, deleted hotkey
    assert_false(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, "Ctrl+F4"]))


func test_can_delete_a_user_hotkey_by_clearing_the_cell() -> void:
    var cell: UserHotkeyTextCell = command_grid.get_cell(1, 5)
    enter_text_and_emit_changed_signal(cell, "")
    # deleted hotkey
    assert_false(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, "Ctrl+F4"]))
    # making sure no empty hotkey was created
    assert_false(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, ""]))


func test_can_create_a_user_hotkey_by_entering_text_into_an_empty_cell() -> void:
    var cell: UserHotkeyTextCell = command_grid.get_cell(0, 5)
    enter_text_and_emit_changed_signal(cell, "Ctrl+T")
    # new hotkey
    assert_true(command_grid._db.rows_exist("user_hotkey", "command_id=%d AND hotkey='%s'" % [cell.command_id, "Ctrl+T"]))
