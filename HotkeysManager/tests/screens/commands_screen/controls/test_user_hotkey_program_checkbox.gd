extends GutTest


func test_program_id_of_a_new_checkbox_is_zero() -> void:
    var checkbox: UserHotkeyProgramCheckbox = add_child_autofree(UserHotkeyProgramCheckbox.new())
    assert_eq(checkbox.program_id, 0)


func test_user_hotkey_id_of_a_new_checkbox_is_zero() -> void:
    var checkbox: UserHotkeyProgramCheckbox = add_child_autofree(UserHotkeyProgramCheckbox.new())
    assert_eq(checkbox.user_hotkey_id, 0)


func test_can_create_a_new_cell_with_arguments() -> void:
    var checkbox: UserHotkeyProgramCheckbox = add_child_autofree(UserHotkeyProgramCheckbox.new(11, 22))
    assert_eq(checkbox.program_id, 11)
    assert_eq(checkbox.user_hotkey_id, 22)
