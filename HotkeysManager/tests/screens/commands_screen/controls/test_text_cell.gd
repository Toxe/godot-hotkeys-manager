extends GutTest


func create_text_cell(text: Variant = null) -> TextCell:
    var cell: TextCell = TextCell.new()
    if text != null:
        assert(text is String)
        cell.text = text
    return add_child_autofree(cell)


func simulate_entering_text(cell: TextCell, text: String) -> void:
    cell.grab_focus()
    cell.text = text
    cell.release_focus()


func test_a_new_cell_is_empty() -> void:
    var cell := create_text_cell()
    assert_eq(cell.text, "")


func test_empty_cell_sends_changed_signal_after_entering_text() -> void:
    var cell := create_text_cell()
    watch_signals(cell)
    simulate_entering_text(cell, "hello world")
    assert_signal_emitted_with_parameters(cell.changed, [cell, "", "hello world"])


func test_prefilled_cell_sends_changed_signal_after_entering_text() -> void:
    var cell := create_text_cell("old text")
    watch_signals(cell)
    simulate_entering_text(cell, "hello world")
    assert_signal_emitted_with_parameters(cell.changed, [cell, "old text", "hello world"])


func test_automatically_trim_spaces_from_beginning_and_end_of_entered_text(text: String = use_parameters([" new text", "   new text", "new text ", "new text   ", " new text ", "   new text   "])) -> void:
    var cell := create_text_cell("old text")
    watch_signals(cell)
    simulate_entering_text(cell, text)
    assert_signal_emitted_with_parameters(cell.changed, [cell, "old text", "new text"])


func test_text_field_contains_the_trimmed_text_after_input_has_finished() -> void:
    var cell := create_text_cell("old text")
    watch_signals(cell)
    simulate_entering_text(cell, "  input  ")
    assert_signal_emitted_with_parameters(cell.changed, [cell, "old text", "input"])
    assert_eq(cell.text, "input")


func test_prefilled_cell_sends_changed_signal_after_deleting_all_text(text: String = use_parameters(["", " ", "   "])) -> void:
    var cell := create_text_cell("old text")
    watch_signals(cell)
    simulate_entering_text(cell, text)
    assert_signal_emitted_with_parameters(cell.changed, [cell, "old text", ""])


func test_prefilled_cell_does_not_send_changed_signal_if_text_hasnt_changed(text: String = use_parameters(["text", " text", "text ", " text "])) -> void:
    var cell := create_text_cell("text")
    watch_signals(cell)
    simulate_entering_text(cell, text)
    assert_signal_not_emitted(cell.changed)


func test_empty_cell_does_not_send_changed_signal_if_no_text_has_been_entered(text: String = use_parameters(["", " "])) -> void:
    var cell := create_text_cell()
    watch_signals(cell)
    simulate_entering_text(cell, text)
    assert_signal_not_emitted(cell.changed)
