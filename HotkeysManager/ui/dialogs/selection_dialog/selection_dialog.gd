class_name SelectionDialog extends Window

signal submitted(selection: Array[Variant])
signal canceled

@export var label_text: String:
    set(value):
        label_text = value
        get_label().text = label_text


func get_label() -> RichTextLabel:
    return $VBoxContainer/VBoxContainer/RichTextLabel


func get_list() -> ItemList:
    return $VBoxContainer/VBoxContainer/ItemList


func _on_visibility_changed() -> void:
    if visible:
        get_label().text = label_text


func _on_submit_button_pressed() -> void:
    var selection := []
    for index in get_list().get_selected_items():
        selection.append(get_list().get_item_metadata(index))
    hide()
    submitted.emit(selection)


func _on_cancel_button_pressed() -> void:
    hide()
    canceled.emit()


func _on_item_list_multi_selected(_index: int, _selected: bool) -> void:
    ($VBoxContainer/HBoxContainer/SubmitButton as Button).disabled = !get_list().is_anything_selected()
