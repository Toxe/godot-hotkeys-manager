extends GutTest


func test_command_id_of_a_new_cell_is_zero() -> void:
    var cell: UserHotkeyTextCell = add_child_autofree(UserHotkeyTextCell.new())
    assert_eq(cell.command_id, 0)


func test_can_create_a_new_cell_with_arguments() -> void:
    var cell: UserHotkeyTextCell = add_child_autofree(UserHotkeyTextCell.new(11))
    assert_eq(cell.command_id, 11)
