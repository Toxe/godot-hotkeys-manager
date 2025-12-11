extends GutTest


func test_program_id_of_a_new_checkbox_is_zero() -> void:
    var checkbox: UserHotkeyProgramCheckboxCell = add_child_autofree(UserHotkeyProgramCheckboxCell.new())
    assert_eq(checkbox.program_id, 0)


func test_user_hotkey_id_of_a_new_checkbox_is_zero() -> void:
    var checkbox: UserHotkeyProgramCheckboxCell = add_child_autofree(UserHotkeyProgramCheckboxCell.new())
    assert_eq(checkbox.user_hotkey_id, 0)


func test_a_new_checkbox_is_disabled() -> void:
    var checkbox: UserHotkeyProgramCheckboxCell = add_child_autofree(UserHotkeyProgramCheckboxCell.new())
    assert_true(checkbox.disabled)


func test_can_create_a_new_cell_with_arguments() -> void:
    var checkbox: UserHotkeyProgramCheckboxCell = add_child_autofree(UserHotkeyProgramCheckboxCell.new(11, 22))
    assert_eq(checkbox.program_id, 11)
    assert_eq(checkbox.user_hotkey_id, 22)


func test_assigning_a_valid_user_hotkey_id_automatically_enables_the_cell() -> void:
    var checkbox: UserHotkeyProgramCheckboxCell = add_child_autofree(UserHotkeyProgramCheckboxCell.new())
    checkbox.user_hotkey_id = 3
    assert_false(checkbox.disabled)


func test_clearing_the_user_hotkey_id_automatically_disables_the_cell() -> void:
    var checkbox: UserHotkeyProgramCheckboxCell = add_child_autofree(UserHotkeyProgramCheckboxCell.new(1, 2))
    checkbox.user_hotkey_id = 0
    assert_true(checkbox.disabled)
