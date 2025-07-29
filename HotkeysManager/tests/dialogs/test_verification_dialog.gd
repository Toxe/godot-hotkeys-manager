extends GutTest


func create_dialog() -> VerificationDialog:
    return VerificationDialog.open_dialog(null, "Confirmation", "Are you sure?", func(_d: VerificationDialog) -> void: pass )


func test_a_new_dialog_is_visible() -> void:
    var dialog: VerificationDialog = add_child_autofree(create_dialog())
    assert_true(dialog.visible)


func test_dialog_shows_title_and_text() -> void:
    var dialog: VerificationDialog = add_child_autofree(create_dialog())
    var label: RichTextLabel = dialog.find_child("RichTextLabel", true, false)
    assert_eq(dialog.title, "Confirmation")
    assert_eq(label.text, "Are you sure?")


func test_confirming_the_dialog() -> void:
    var dialog: VerificationDialog = add_child_autofree(create_dialog())
    watch_signals(dialog)
    dialog._on_confirmation_button_pressed()
    assert_signal_emitted(dialog.confirmed)
