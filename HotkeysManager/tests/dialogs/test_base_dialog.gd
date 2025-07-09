extends GutTest


func create_dialog() -> BaseDialog:
    var dialog := BaseDialog.new()
    dialog.title = "BaseDialog"
    dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
    return dialog


func test_canceling_the_dialog() -> void:
    var dialog: BaseDialog = add_child_autofree(create_dialog())
    watch_signals(dialog)
    dialog._on_cancel_requested()
    assert_signal_emitted(dialog.canceled)


func test_dialog_is_getting_destroyed_after_closing() -> void:
    var dialog: BaseDialog = create_dialog()
    add_child(dialog)
    await wait_process_frames(1)
    dialog.close()
    await wait_process_frames(1)
    assert_false(is_instance_valid(dialog))
