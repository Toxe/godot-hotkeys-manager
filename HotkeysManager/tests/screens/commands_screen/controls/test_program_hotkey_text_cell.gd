extends GutTest


func test_command_id_of_a_new_cell_is_zero() -> void:
    var cell: ProgramHotkeyTextCell = add_child_autofree(ProgramHotkeyTextCell.new())
    assert_eq(cell.command_id, 0)


func test_program_id_of_a_new_cell_is_zero() -> void:
    var cell: ProgramHotkeyTextCell = add_child_autofree(ProgramHotkeyTextCell.new())
    assert_eq(cell.program_id, 0)


func test_program_command_id_of_a_new_cell_is_zero() -> void:
    var cell: ProgramHotkeyTextCell = add_child_autofree(ProgramHotkeyTextCell.new())
    assert_eq(cell.program_command_id, 0)
