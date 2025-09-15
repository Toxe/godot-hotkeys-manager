extends GutTest


func create_dialog(input_fields: Dictionary[String, String], prefill: Dictionary[String, String] = {}) -> EnterTextDialog:
    return EnterTextDialog.open_dialog(null, "Enter Text", "Please enter some text.", input_fields, func(_d: EnterTextDialog, _s: String) -> void: pass , prefill)


func simulate_text_input(dialog: EnterTextDialog, field: String, text: String) -> void:
    var text_field := dialog.get_text_field(field)
    text_field.text = text
    dialog._on_line_edit_text_changed(text)


func test_generating_node_names_for_input_labels() -> void:
    assert_eq(EnterTextDialog.node_name_for_input_label("field"), "Label_field")
    assert_eq(EnterTextDialog.node_name_for_input_label("field123"), "Label_field123")
    assert_eq(EnterTextDialog.node_name_for_input_label("field_a"), "Label_field_a")


func test_generating_node_names_for_input_text_fields() -> void:
    assert_eq(EnterTextDialog.node_name_for_input_text_field("field"), "LineEdit_field")
    assert_eq(EnterTextDialog.node_name_for_input_text_field("field123"), "LineEdit_field123")
    assert_eq(EnterTextDialog.node_name_for_input_text_field("field_a"), "LineEdit_field_a")


func test_a_new_dialog_is_visible() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"text": "Enter Text"}))
    assert_true(dialog.visible)


func test_dialog_shows_title_and_text() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field": "Some Field"}))
    var label: RichTextLabel = dialog.find_child("RichTextLabel", true, false)
    assert_eq(dialog.title, "Enter Text")
    assert_eq(label.text, "Please enter some text.")


func check_has_input_controls(dialog: EnterTextDialog, input_field_name: String, input_label_text: String) -> void:
    var input_label: Node = dialog.find_child(EnterTextDialog.node_name_for_input_label(input_field_name), true, false)
    var input_field: Node = dialog.find_child(EnterTextDialog.node_name_for_input_text_field(input_field_name), true, false)
    assert_not_null(input_label)
    assert_not_null(input_field)
    assert_is(input_label, Label)
    assert_is(input_field, LineEdit)
    assert_eq((input_label as Label).text, input_label_text)


func test_can_show_dialog_with_one_input_field() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"text": "Label Text"}))
    check_has_input_controls(dialog, "text", "Label Text")


func test_can_show_dialog_with_multiple_input_fields() -> void:
    var input_fields: Dictionary[String, String]

    for i in 5:
        input_fields["field_%d" % i] = "Label Text %d" % i

    var dialog: EnterTextDialog = add_child_autofree(create_dialog(input_fields))

    for i in 5:
        check_has_input_controls(dialog, "field_%d" % i, "Label Text %d" % i)


func test_text_fields_are_empty_by_default() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field_a": "Field A", "field_b": "Field B", "field_c": "Field C"}))
    assert_eq(dialog.get_text_field("field_a").text, "")
    assert_eq(dialog.get_text_field("field_b").text, "")
    assert_eq(dialog.get_text_field("field_c").text, "")


func test_can_prefill_all_text_fields() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field_a": "Field A", "field_b": "Field B", "field_c": "Field C"}, {"field_a": "Some Text A", "field_b": "Some Text B", "field_c": "Some Text C"}))
    assert_eq(dialog.get_text_field("field_a").text, "Some Text A")
    assert_eq(dialog.get_text_field("field_b").text, "Some Text B")
    assert_eq(dialog.get_text_field("field_c").text, "Some Text C")


func test_can_prefill_some_text_fields() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field_a": "Field A", "field_b": "Field B", "field_c": "Field C", "field_d": "Field D"}, {"field_b": "Some Text B", "field_c": "Some Text C"}))
    assert_eq(dialog.get_text_field("field_a").text, "")
    assert_eq(dialog.get_text_field("field_b").text, "Some Text B")
    assert_eq(dialog.get_text_field("field_c").text, "Some Text C")
    assert_eq(dialog.get_text_field("field_d").text, "")


func test_first_and_only_input_field_has_focus_and_is_in_edit_mode() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field": "Label Text"}))
    var text_field := dialog.get_text_field("field")
    assert_true(text_field.has_focus())
    assert_true(text_field.is_editing())


func test_first_of_multiple_input_fields_has_focus_and_is_in_edit_mode() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field_a": "Field A", "field_b": "Field B", "field_c": "Field C"}))
    var text_field := dialog.get_text_field("field_a")
    assert_true(text_field.has_focus())
    assert_true(text_field.is_editing())


func test_submit_button_is_disabled_if_first_and_only_input_field_is_empty() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field": "Label Text"}))
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    assert_true(submit_button.disabled)


func test_submit_button_is_disabled_if_first_of_multiple_input_fields_is_empty() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field_a": "Field A", "field_b": "Field B", "field_c": "Field C"}, {"field_b": "Some Text B", "field_c": "Some Text C"}))
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    assert_true(submit_button.disabled)


func test_submit_button_is_enabled_if_first_and_only_input_field_was_prefilled() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field": "Label Text"}, {"field": "Prefilled Text"}))
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    assert_false(submit_button.disabled)


func test_submit_button_is_enabled_if_first_of_multiple_input_fields_was_prefilled() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field_a": "Field A", "field_b": "Field B", "field_c": "Field C"}, {"field_a": "Prefilled Text"}))
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    assert_false(submit_button.disabled)


func test_submit_button_gets_enabled_when_entering_text_into_first_and_only_input_field() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field": "Label Text"}))
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    simulate_text_input(dialog, "field", "hello world")
    assert_eq(dialog.get_text_field("field").text, "hello world")
    assert_false(submit_button.disabled)


func test_submit_button_gets_enabled_when_entering_text_into_first_of_multiple_input_fields() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field_a": "Field A", "field_b": "Field B", "field_c": "Field C"}))
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    simulate_text_input(dialog, "field_a", "hello world")
    assert_eq(dialog.get_text_field("field_a").text, "hello world")
    assert_false(submit_button.disabled)


func test_submit_button_gets_disabled_when_deleting_all_text_from_first_and_only_input_field() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field": "Label Text"}, {"field": "Prefilled Text"}))
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    simulate_text_input(dialog, "field", "")
    assert_eq(dialog.get_text_field("field").text, "")
    assert_true(submit_button.disabled)


func test_submit_button_gets_disabled_when_deleting_all_text_from_first_of_multiple_input_fields() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field_a": "Field A", "field_b": "Field B", "field_c": "Field C"}, {"field_a": "Prefilled Text"}))
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    simulate_text_input(dialog, "field_a", "")
    assert_eq(dialog.get_text_field("field_a").text, "")
    assert_true(submit_button.disabled)


func test_submitting_the_dialog_with_one_input_field() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field": "Label Text"}, {"field": "Prefilled Text"}))
    dialog.submitted.connect(func(_submitted_dialog: EnterTextDialog, values: Dictionary[String, String]) -> void:
        assert_eq_deep(values, {"field": "Prefilled Text"})
    )

    dialog.get_submit_button().pressed.emit()
    await wait_idle_frames(1)
    TestUtils.assert_and_ignore_expected_error(self, "Error calling from signal 'submitted' to callable: 'GDScript::<anonymous lambda>': Cannot convert argument 2 from Dictionary to String.")


func test_submitting_the_dialog_with_multiple_input_fields() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog({"field_a": "Field A", "field_b": "Field B", "field_c": "Field C"}, {"field_a": "Some Text A", "field_c": "Some Text C"}))
    dialog.submitted.connect(func(_submitted_dialog: EnterTextDialog, values: Dictionary[String, String]) -> void:
        assert_eq_deep(values, {"field_a": "Some Text A", "field_b": "", "field_c": "Some Text C"})
    )

    dialog.get_submit_button().pressed.emit()
    await wait_idle_frames(1)
    TestUtils.assert_and_ignore_expected_error(self, "Error calling from signal 'submitted' to callable: 'GDScript::<anonymous lambda>': Cannot convert argument 2 from Dictionary to String.")
