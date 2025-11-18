class_name TextCell extends LineEdit

signal changed(cell: TextCell, old_text: String, new_text: String)

var _old_text: String


func _ready() -> void:
    _old_text = text
    expand_to_text_length = true

    editing_toggled.connect(_on_editing_toggled)


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
