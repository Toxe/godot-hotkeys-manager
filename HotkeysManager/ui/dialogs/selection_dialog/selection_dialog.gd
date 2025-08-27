class_name SelectionDialog extends BaseDialog

signal submitted(dialog: SelectionDialog, selection: Array[Variant])

const dialog_scene: PackedScene = preload("uid://1eqq02vc7slg")

@export var label_text: String:
    set(value):
        label_text = value
        get_label().text = label_text


## Create and show a new dialog. Unless parent is [code]null[/code] it will automatically be added to the parent as a child.
static func open_dialog(parent: Node, dialog_title: String, label: String, callable: Callable, options: Dictionary[int, String]) -> SelectionDialog:
    var dialog: SelectionDialog = dialog_scene.instantiate()
    dialog.title = dialog_title
    dialog.label_text = label
    dialog.submitted.connect(callable)

    var list := dialog.get_list()
    for id: int in options:
        var text := options[id]
        var index := list.add_item(text)
        list.set_item_metadata(index, id)

    if parent:
        parent.add_child(dialog)

    return dialog


func get_label() -> RichTextLabel:
    return $VBoxContainer/VBoxContainer/RichTextLabel


func get_list() -> ItemList:
    return $VBoxContainer/VBoxContainer/ItemList


func _on_submit_button_pressed() -> void:
    var selection := []
    for index in get_list().get_selected_items():
        selection.append(get_list().get_item_metadata(index))
    submitted.emit(self, selection)
    close()


func _on_item_list_multi_selected(_index: int, _selected: bool) -> void:
    ($VBoxContainer/HBoxContainer/SubmitButton as Button).disabled = !get_list().is_anything_selected()
