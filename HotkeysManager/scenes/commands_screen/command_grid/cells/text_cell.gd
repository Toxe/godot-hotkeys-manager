class_name TextCell extends LineEdit

signal changed(cell: TextCell, old_text: String, new_text: String)
signal add_row(cell: TextCell, add_above: bool)

var _old_text: String


func _ready() -> void:
    _old_text = text
    expand_to_text_length = true

    editing_toggled.connect(_on_editing_toggled)


func _gui_input(event: InputEvent) -> void:
    if event.is_pressed() && !event.is_echo():
        var begin_editing := false
        var finish_editing := false
        var add_row_above := false
        var add_row_below := false
        var clear_cell := false

        if is_editing():
            if event.is_action_pressed("finish_editing_cell", false, true):
                finish_editing = true
            if event.is_action_pressed("add_row_above", false, true):
                finish_editing = true
                add_row_above = true
            if event.is_action_pressed("add_row_below", false, true):
                finish_editing = true
                add_row_below = true
        else:
            if event.is_action_pressed("begin_editing_cell", false, true):
                begin_editing = true
            if event.is_action_pressed("add_row_above", false, true):
                add_row_above = true
            if event.is_action_pressed("add_row_below", false, true):
                add_row_below = true
            if event.is_action_pressed("clear_cell", false, true):
                clear_cell = true

        assert((begin_editing && finish_editing) == false)
        assert((add_row_above && add_row_below) == false)

        if begin_editing:
            accept_event()
            edit();
            caret_column = text.length()
            editing_toggled.emit(true)

        if finish_editing:
            accept_event()
            unedit();
            editing_toggled.emit(false)

        if add_row_above:
            accept_event()
            add_row.emit(self, true)

        if add_row_below:
            accept_event()
            add_row.emit(self, false)

        if clear_cell:
            accept_event()
            change_text("")


func grab_focus_and_enter_edit_mode() -> void:
    edit()


func grab_focus_without_entering_edit_mode() -> void:
    edit()
    unedit()


func change_text(new_text: String) -> void:
    text = new_text.strip_edges()
    if _old_text != text:
        changed.emit(self, _old_text, text)
        _old_text = text


func _on_editing_toggled(toggled_on: bool) -> void:
    if !toggled_on:
        change_text(text)
