extends GutTest


func create_dialog() -> SelectionDialog:
    const options: Dictionary[int, String] = {
        1: "One",
        2: "Two",
        3: "Three",
    }
    return SelectionDialog.open_dialog(null, "Selection", "Please select something.", func(_d: SelectionDialog, _s: String) -> void: pass , options)


func test_a_new_dialog_is_visible() -> void:
    var dialog: SelectionDialog = add_child_autofree(create_dialog())
    assert_true(dialog.visible)


func test_dialog_shows_title_and_text() -> void:
    var dialog: SelectionDialog = add_child_autofree(create_dialog())
    var label: RichTextLabel = dialog.find_child("RichTextLabel", true, false)
    assert_eq(dialog.title, "Selection")
    assert_eq(label.text, "Please select something.")


func test_shows_list_with_options() -> void:
    var dialog: SelectionDialog = add_child_autofree(create_dialog())
    var list := dialog.get_list()

    assert_eq(list.item_count, 3)

    assert_eq(list.get_item_text(0), "One")
    assert_eq(list.get_item_text(1), "Two")
    assert_eq(list.get_item_text(2), "Three")

    assert_eq(list.get_item_metadata(0), 1)
    assert_eq(list.get_item_metadata(1), 2)
    assert_eq(list.get_item_metadata(2), 3)


func test_no_items_are_selected_by_default() -> void:
    var dialog: SelectionDialog = add_child_autofree(create_dialog())
    var list := dialog.get_list()
    assert_eq(list.get_selected_items().size(), 0)


func test_submit_button_is_disabled_by_default() -> void:
    var dialog: SelectionDialog = add_child_autofree(create_dialog())
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    assert_true(submit_button.disabled)


func test_submit_button_is_disabled_if_no_items_are_selected() -> void:
    var dialog: SelectionDialog = add_child_autofree(create_dialog())
    var submit_button: Button = dialog.find_child("SubmitButton", true, false)
    var list := dialog.get_list()

    list.select(1)
    dialog._on_item_list_multi_selected(1, true)
    assert_false(submit_button.disabled)

    list.deselect(1)
    dialog._on_item_list_multi_selected(1, false)
    assert_true(submit_button.disabled)


func test_submitting_the_dialog() -> void:
    var dialog: SelectionDialog = add_child_autofree(create_dialog())
    var list := dialog.get_list()
    list.select(1)

    watch_signals(dialog)
    dialog._on_submit_button_pressed()
    assert_signal_emitted(dialog.submitted)
