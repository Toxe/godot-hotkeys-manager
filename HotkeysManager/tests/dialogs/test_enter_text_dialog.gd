extends GutTest


func create_dialog() -> EnterTextDialog:
    return EnterTextDialog.open_dialog(null, "Enter Text", "Please enter some text.", func(_d: EnterTextDialog, _s: String) -> void: pass )


func simulate_text_input(dialog: EnterTextDialog, text_field: LineEdit, text: String) -> void:
    text_field.text = text
    dialog._on_line_edit_text_changed(text)


func test_a_new_dialog_is_visible() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog())
    assert_true(dialog.visible)


func test_text_field_is_empty_by_default() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog())
    var text_field := dialog.get_text_field()
    assert_eq(text_field.text, "")


func test_can_enter_text_before_showing_the_dialog() -> void:
    var dialog: EnterTextDialog = create_dialog()
    var text_field := dialog.get_text_field()
    text_field.text = "hello"
    add_child_autofree(dialog)
    assert_eq(text_field.text, "hello")


func test_text_field_has_focus_and_is_in_edit_mode() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog())
    var text_field := dialog.get_text_field()
    assert_true(text_field.has_focus())
    assert_true(text_field.is_editing())


func test_submit_button_is_disabled_if_text_field_is_empty() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog())
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    var text_field := dialog.get_text_field()

    assert_eq(text_field.text, "")
    assert_true(submit_button.disabled)

    simulate_text_input(dialog, text_field, "hello")

    assert_eq(text_field.text, "hello")
    assert_false(submit_button.disabled)


func test_submit_button_is_enabled_if_text_field_was_prefilled() -> void:
    var dialog: EnterTextDialog = create_dialog()
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    dialog.get_text_field().text = "hello"
    add_child_autofree(dialog)

    assert_false(submit_button.disabled)


func test_dialog_shows_title_and_text() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog())
    var label: RichTextLabel = dialog.find_child("RichTextLabel", true, false)
    assert_eq(dialog.title, "Enter Text")
    assert_eq(label.text, "Please enter some text.")


func test_submitting_the_dialog() -> void:
    var dialog: EnterTextDialog = add_child_autofree(create_dialog())
    watch_signals(dialog)
    dialog._on_submit_button_pressed()
    assert_signal_emitted(dialog.submitted)
