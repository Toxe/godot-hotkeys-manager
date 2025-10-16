extends GutTest


func test_command_id_of_a_new_cell_is_zero() -> void:
    var cell: ProgramHotkeyTextCell = add_child_autofree(ProgramHotkeyTextCell.new())
    assert_eq(cell.command_id, 0)


func test_program_id_of_a_new_cell_is_zero() -> void:
    var cell: ProgramHotkeyTextCell = add_child_autofree(ProgramHotkeyTextCell.new())
    assert_eq(cell.program_id, 0)


func test_hotkey_of_a_new_cell_is_null() -> void:
    var cell: ProgramHotkeyTextCell = add_child_autofree(ProgramHotkeyTextCell.new())
    @warning_ignore("unsafe_call_argument")
    assert_null(cell.hotkey)


func test_can_create_a_new_cell_with_arguments() -> void:
    var cell: ProgramHotkeyTextCell = add_child_autofree(ProgramHotkeyTextCell.new(11, 22, "Shift+3"))
    assert_eq(cell.command_id, 11)
    assert_eq(cell.program_id, 22)
    @warning_ignore("unsafe_call_argument")
    assert_eq(cell.hotkey, "Shift+3")
