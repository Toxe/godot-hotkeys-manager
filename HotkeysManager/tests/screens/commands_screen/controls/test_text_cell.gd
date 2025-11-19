extends GutTest

var _input_sender := GutInputSender.new(Input)


func after_each() -> void:
    _input_sender.release_all()
    _input_sender.clear()


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


func test_grab_focus_and_enter_edit_mode() -> void:
    var cell := create_text_cell()
    assert_false(cell.has_focus())
    assert_false(cell.is_editing())
    cell.grab_focus_and_enter_edit_mode()
    assert_true(cell.has_focus())
    assert_true(cell.is_editing())


func test_grab_focus_without_entering_edit_mode() -> void:
    var cell := create_text_cell()
    assert_false(cell.has_focus())
    assert_false(cell.is_editing())
    cell.grab_focus_without_entering_edit_mode()
    assert_true(cell.has_focus())
    assert_false(cell.is_editing())


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


func test_action_BeginEditingCell_starts_editing_cell_not_in_edit_mode() -> void:
    var cell := create_text_cell("some previous text")
    cell.grab_focus_without_entering_edit_mode()
    _input_sender.action_down("begin_editing_cell")
    _input_sender.action_up("begin_editing_cell")
    await wait_idle_frames(1)
    assert_true(cell.is_editing())
    assert_true(cell.has_focus())
    assert_eq(cell.text, "some previous text")


func test_action_BeginEditingCell_is_ignored_for_cells_in_edit_mode() -> void:
    var cell := create_text_cell("some previous text")
    cell.grab_focus_and_enter_edit_mode()
    _input_sender.action_down("begin_editing_cell")
    _input_sender.action_up("begin_editing_cell")
    await wait_idle_frames(1)
    assert_true(cell.is_editing())
    assert_true(cell.has_focus())
    assert_eq(cell.text, "some previous text")


func test_action_BeginEditingCell_puts_the_caret_at_the_end_of_the_text(text: String = use_parameters(["", ".", "???", "longer text"])) -> void:
    var cell := create_text_cell(text)
    cell.grab_focus_without_entering_edit_mode()
    _input_sender.action_down("begin_editing_cell")
    _input_sender.action_up("begin_editing_cell")
    await wait_idle_frames(1)
    assert_eq(cell.caret_column, text.length())


func test_action_FinishEditingCell_stops_editing_cell_in_edit_mode() -> void:
    var cell := create_text_cell("some previous text")
    cell.grab_focus_and_enter_edit_mode()
    _input_sender.action_down("finish_editing_cell")
    _input_sender.action_up("finish_editing_cell")
    await wait_idle_frames(1)
    assert_false(cell.is_editing())
    assert_true(cell.has_focus())
    assert_eq(cell.text, "some previous text")


func test_action_FinishEditingCell_is_ignored_for_cells_not_in_edit_mode() -> void:
    var cell := create_text_cell("some previous text")
    cell.grab_focus_without_entering_edit_mode()
    _input_sender.action_down("finish_editing_cell")
    _input_sender.action_up("finish_editing_cell")
    await wait_idle_frames(1)
    assert_false(cell.is_editing())
    assert_true(cell.has_focus())
    assert_eq(cell.text, "some previous text")


func test_action_FinishEditingCell_sends_changed_signal_if_text_has_been_changed() -> void:
    var cell := create_text_cell("old text")
    watch_signals(cell)
    cell.text = "new text"
    cell.grab_focus_and_enter_edit_mode()
    _input_sender.action_down("finish_editing_cell")
    _input_sender.action_up("finish_editing_cell")
    await wait_idle_frames(1)
    assert_signal_emitted_with_parameters(cell.changed, [cell, "old text", "new text"])


func test_action_FinishEditingCell_doesnt_send_changed_signal_if_text_hasnt_been_changed() -> void:
    var cell := create_text_cell("old text")
    watch_signals(cell)
    cell.grab_focus_and_enter_edit_mode()
    _input_sender.action_down("finish_editing_cell")
    _input_sender.action_up("finish_editing_cell")
    await wait_idle_frames(1)
    assert_signal_not_emitted(cell.changed)


func test_action_ClearCell_for_cells_not_in_edit_mode() -> void:
    var cell := create_text_cell("some previous text")
    cell.grab_focus_without_entering_edit_mode()
    _input_sender.action_down("clear_cell")
    _input_sender.action_up("clear_cell")
    await wait_idle_frames(1)
    assert_false(cell.is_editing())
    assert_true(cell.has_focus())
    assert_true(cell.text.is_empty())


func test_action_ClearCell_is_ignored_for_cells_in_edit_mode() -> void:
    var cell := create_text_cell("some previous text")
    cell.grab_focus_and_enter_edit_mode()
    _input_sender.action_down("clear_cell")
    _input_sender.action_up("clear_cell")
    await wait_idle_frames(1)
    assert_true(cell.is_editing())
    assert_true(cell.has_focus())
    assert_eq(cell.text, "some previous text")


func test_action_ClearCell_sends_changed_signal_if_text_has_been_deleted() -> void:
    var cell := create_text_cell("old text")
    watch_signals(cell)
    cell.grab_focus_without_entering_edit_mode()
    _input_sender.action_down("clear_cell")
    _input_sender.action_up("clear_cell")
    await wait_idle_frames(1)
    assert_signal_emitted_with_parameters(cell.changed, [cell, "old text", ""])


func test_action_ClearCell_doesnt_send_changed_signal_if_no_text_has_been_deleted() -> void:
    var cell := create_text_cell("")
    watch_signals(cell)
    cell.grab_focus_without_entering_edit_mode()
    _input_sender.action_down("clear_cell")
    _input_sender.action_up("clear_cell")
    await wait_idle_frames(1)
    assert_signal_not_emitted(cell.changed)
