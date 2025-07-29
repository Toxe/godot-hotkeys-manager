class_name VerificationDialog extends BaseDialog

signal confirmed(dialog: VerificationDialog)

const dialog_scene: PackedScene = preload("uid://sdp0se8heewl")

@export var label_text: String:
    set(value):
        label_text = value
        get_label().text = label_text


## Create and show a new dialog. Unless parent is [code]null[/code] it will automatically be added to the parent as a child.
static func open_dialog(parent: Node, dialog_title: String, label: String, callable: Callable) -> VerificationDialog:
    var dialog: VerificationDialog = dialog_scene.instantiate()
    dialog.title = dialog_title
    dialog.label_text = label
    dialog.confirmed.connect(callable)
    if parent:
        parent.add_child(dialog)
    return dialog


func get_label() -> RichTextLabel:
    return $VBoxContainer/RichTextLabel


func _on_confirmation_button_pressed() -> void:
    close()
    confirmed.emit(self)
