extends GutTest


func test_command_id_of_a_new_cell_is_zero() -> void:
    var cell: ProgramHotkeyTextCell = add_child_autofree(ProgramHotkeyTextCell.new())
    assert_eq(cell.command_id, 0)


func test_program_id_of_a_new_cell_is_zero() -> void:
    var cell: ProgramHotkeyTextCell = add_child_autofree(ProgramHotkeyTextCell.new())
    assert_eq(cell.program_id, 0)


func test_is_bound_of_a_new_cell_is_false() -> void:
    var cell: ProgramHotkeyTextCell = add_child_autofree(ProgramHotkeyTextCell.new())
    assert_false(cell.is_bound)


func test_can_create_a_new_cell_with_arguments() -> void:
    var cell: ProgramHotkeyTextCell = add_child_autofree(ProgramHotkeyTextCell.new(11, 22, true))
    assert_eq(cell.command_id, 11)
    assert_eq(cell.program_id, 22)
    assert_true(cell.is_bound)
