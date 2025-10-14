extends GutTest


func test_a_new_cell_if_empty() -> void:
    var cell: TextCell = add_child_autofree(TextCell.new())
    assert_eq(cell.text, "")


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


func test_automatically_trim_spaces_from_beginning_and_end_of_entered_text(text: String = use_parameters([" new text", "   new text", "new text ", "new text   ", " new text ", "   new text   "])) -> void:
    var cell: TextCell = TextCell.new()
    cell.text = "old text"
    cell.changed.connect(func(old_text: String, new_text: String) -> void:
        assert_eq(old_text, "old text")
        assert_eq(new_text, "new text")
    )
    add_child_autofree(cell)

    cell.grab_focus()
    cell.text = text
    cell.release_focus()


func test_text_field_contains_the_trimmed_text_after_input_has_finished() -> void:
    var cell: TextCell = TextCell.new()
    cell.text = "old text"
    cell.changed.connect(func(old_text: String, new_text: String) -> void:
        assert_eq(old_text, "old text")
        assert_eq(new_text, "input")
    )
    add_child_autofree(cell)

    cell.grab_focus()
    cell.text = "  input  "
    cell.release_focus()

    assert_eq(cell.text, "input")


func test_prefilled_cell_sends_changed_signal_after_deleting_all_text(text: String = use_parameters(["", " ", "   "])) -> void:
    var cell: TextCell = TextCell.new()
    cell.text = "old text"
    cell.changed.connect(func(old_text: String, new_text: String) -> void:
        assert_eq(old_text, "old text")
        assert_eq(new_text, "")
    )
    add_child_autofree(cell)

    cell.grab_focus()
    cell.text = text
    cell.release_focus()


func test_prefilled_cell_does_not_send_changed_signal_if_text_hasnt_changed(text: String = use_parameters(["text", " text", "text ", " text "])) -> void:
    var cell: TextCell = TextCell.new()
    cell.text = "text"
    watch_signals(cell)
    add_child_autofree(cell)

    cell.grab_focus()
    cell.text = text
    cell.release_focus()

    assert_signal_not_emitted(cell.changed)


func test_empty_cell_does_not_send_changed_signal_if_no_text_has_been_entered(text: String = use_parameters(["", " "])) -> void:
    var cell: TextCell = TextCell.new()
    watch_signals(cell)
    add_child_autofree(cell)

    cell.grab_focus()
    cell.text = text
    cell.release_focus()

    assert_signal_not_emitted(cell.changed)
