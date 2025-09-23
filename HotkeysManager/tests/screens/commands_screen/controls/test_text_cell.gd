extends GutTest


func test_a_new_cell_if_empty() -> void:
    var cell: TextCell = add_child_autofree(TextCell.new())
    assert_eq(cell.text, "")


func test_does_not_send_editing_stopped_signal_when_entering_edit_mode() -> void:
    var cell: TextCell = add_child_autofree(TextCell.new())
    watch_signals(cell)
    cell.grab_focus()
    assert_signal_not_emitted(cell.editing_stopped)


func test_sends_editing_stopped_signal_after_leaving_edit_mode() -> void:
    var cell: TextCell = add_child_autofree(TextCell.new())
    watch_signals(cell)
    cell.grab_focus()
    cell.release_focus()
    assert_signal_emitted(cell.editing_stopped)


func test_empty_cell_sends_changed_signal_after_entering_text() -> void:
    var cell: TextCell = TextCell.new()
    cell.changed.connect(func(old_text: String, new_text: String) -> void:
        assert_eq(old_text, "")
        assert_eq(new_text, "hello world")
    )
    add_child_autofree(cell)

    cell.grab_focus()
    cell.text = "hello world"
    cell.release_focus()


func test_prefilled_cell_sends_changed_signal_after_entering_text() -> void:
    var cell: TextCell = TextCell.new()
    cell.text = "old text"
    cell.changed.connect(func(old_text: String, new_text: String) -> void:
        assert_eq(old_text, "old text")
        assert_eq(new_text, "hello world")
    )
    add_child_autofree(cell)

    cell.grab_focus()
    cell.text = "hello world"
    cell.release_focus()


func test_prefilled_cell_sends_changed_signal_after_deleting_all_text() -> void:
    var cell: TextCell = TextCell.new()
    cell.text = "old text"
    cell.changed.connect(func(old_text: String, new_text: String) -> void:
        assert_eq(old_text, "old text")
        assert_eq(new_text, "")
    )
    add_child_autofree(cell)

    cell.grab_focus()
    cell.text = ""
    cell.release_focus()


func test_prefilled_cell_does_not_send_changed_signal_if_text_hasnt_changed() -> void:
    var cell: TextCell = TextCell.new()
    cell.text = "old text"
    watch_signals(cell)
    add_child_autofree(cell)

    cell.grab_focus()
    cell.release_focus()

    assert_signal_not_emitted(cell.changed)


func test_empty_cell_does_not_send_changed_signal_if_no_text_has_been_entered() -> void:
    var cell: TextCell = TextCell.new()
    watch_signals(cell)
    add_child_autofree(cell)

    cell.grab_focus()
    cell.release_focus()

    assert_signal_not_emitted(cell.changed)
