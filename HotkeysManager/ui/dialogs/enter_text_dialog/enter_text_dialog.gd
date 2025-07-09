class_name EnterTextDialog extends BaseDialog

signal submitted(dialog: EnterTextDialog, text: String)

const dialog_scene: PackedScene = preload("uid://pmsm6nuojugq")

@export var label_text: String:
    set(value):
        label_text = value
        get_label().text = label_text


## Create and show a new dialog. Unless parent is [code]null[/code] it will automatically be added to the parent as a child.
static func open_dialog(parent: Node, dialog_title: String, label: String, callable: Callable, prefill := "") -> EnterTextDialog:
    var dialog: EnterTextDialog = dialog_scene.instantiate()
    dialog.title = dialog_title
    dialog.label_text = label
    dialog.get_text_field().text = prefill
    dialog.submitted.connect(callable)
    if parent:
        parent.add_child(dialog)
    return dialog


func _ready() -> void:
    super._ready()
    get_label().text = label_text
    get_text_field().grab_focus()
    get_text_field().caret_column = get_text_field().text.length()
    update_submit_button(get_text_field().text)


func get_label() -> RichTextLabel:
    return $VBoxContainer/VBoxContainer/RichTextLabel


func get_text_field() -> LineEdit:
    return $VBoxContainer/VBoxContainer/LineEdit


func update_submit_button(text: String) -> void:
    ($VBoxContainer/HBoxContainer/SubmitButton as Button).disabled = text.is_empty()


func _on_submit_button_pressed() -> void:
    close()
    submitted.emit(self, get_text_field().text)


func _on_line_edit_text_changed(new_text: String) -> void:
    update_submit_button(new_text)
