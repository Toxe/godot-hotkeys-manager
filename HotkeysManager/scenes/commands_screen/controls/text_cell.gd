class_name TextCell extends LineEdit

signal editing_stopped(text: String)
signal changed(old_text: String, new_text: String)

var _old_text: String


func _ready() -> void:
    _old_text = text
    expand_to_text_length = true

    editing_toggled.connect(_on_editing_toggled)


func _on_editing_toggled(toggled_on: bool) -> void:
    if !toggled_on:
        editing_stopped.emit(text)

        if _old_text != text:
            changed.emit(_old_text, text)
            _old_text = text
