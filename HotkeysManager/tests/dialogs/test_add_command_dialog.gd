extends GutTest


func create_dialog() -> AddCommandDialog:
    var programs: Dictionary[int, String] = {11: "Program 1", 12: "Program 2", 13: "Program 3"}
    var commands: Dictionary[int, String] = {21: "Command 1", 22: "Command 2", 23: "Command 3"}
    return AddCommandDialog.open_dialog(null, "Select a Command and assign it to at least one Program.", func(_d: AddCommandDialog, _o: Dictionary[String, Variant]) -> void: pass , programs, commands)


func test_a_new_dialog_is_visible() -> void:
    var dialog: AddCommandDialog = add_child_autofree(create_dialog())
    assert_true(dialog.visible)


func test_dialog_shows_title_and_text() -> void:
    var dialog: AddCommandDialog = add_child_autofree(create_dialog())
    var label: RichTextLabel = dialog.find_child("RichTextLabel", true, false)
    assert_eq(dialog.title, "Add Command")
    assert_eq(label.text, "Select a Command and assign it to at least one Program.")


func test_no_items_are_selected_by_default() -> void:
    var dialog: AddCommandDialog = add_child_autofree(create_dialog())
    var list := dialog.get_list()
    assert_eq(list.get_selected_items().size(), 0)


func test_submit_button_is_disabled_by_default() -> void:
    var dialog: AddCommandDialog = add_child_autofree(create_dialog())
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    assert_true(submit_button.disabled)


func test_submitting_the_dialog() -> void:
    var dialog: AddCommandDialog = add_child_autofree(create_dialog())
    var list := dialog.get_list()
    list.select(1)

    watch_signals(dialog)
    dialog._on_submit_button_pressed()
    assert_signal_emitted(dialog.submitted)
