class_name EnterTextDialog extends BaseDialog

signal submitted(dialog: EnterTextDialog, values: Dictionary[String, String])

const dialog_scene: PackedScene = preload("uid://pmsm6nuojugq")

@export var label_text: String:
    set(value):
        label_text = value
        get_label().text = label_text


## Create and show a new dialog. Unless parent is [code]null[/code] it will automatically be added to the parent as a child.
static func open_dialog(parent: Node, dialog_title: String, label: String, input_fields: Dictionary[String, String], callable: Callable, prefill: Dictionary[String, String] = {}) -> EnterTextDialog:
    assert(!input_fields.is_empty())
    assert(prefill.size() <= input_fields.size())

    var dialog: EnterTextDialog = dialog_scene.instantiate()
    dialog.title = dialog_title
    dialog.label_text = label
    dialog.submitted.connect(callable)

    for field_name in input_fields:
        var field_label_text: String = input_fields[field_name]
        var field_prefill_text: String = prefill.get(field_name, "")
        dialog.add_input_field(field_name, field_label_text, field_prefill_text)

    if parent:
        parent.add_child(dialog)

    return dialog


static func node_name_for_input_label(field_name: String) -> String:
    assert(field_name.is_valid_ascii_identifier())
    return "Label_%s" % field_name


static func node_name_for_input_text_field(field_name: String) -> String:
    assert(field_name.is_valid_ascii_identifier())
    return "LineEdit_%s" % field_name


func _ready() -> void:
    super._ready()
    get_label().text = label_text

    # first text field should grab input
    var first_text_field := get_first_text_field()
    first_text_field.grab_focus()
    first_text_field.caret_column = first_text_field.text.length()

    update_submit_button(first_text_field.text)


func get_label() -> RichTextLabel:
    return $VBoxContainer/RichTextLabel


func get_submit_button() -> Button:
    return $VBoxContainer/HBoxContainer/SubmitButton


func add_input_field(field_name: String, field_label_text: String, field_prefill_text := "") -> void:
    assert(field_name.is_valid_ascii_identifier())
    assert(field_label_text != "")

    var label := Label.new()
    label.name = node_name_for_input_label(field_name)
    label.text = field_label_text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    var text_field := LineEdit.new()
    text_field.name = node_name_for_input_text_field(field_name)
    text_field.text = field_prefill_text
    text_field.custom_minimum_size = Vector2(200, 0)
    text_field.text_changed.connect(_on_line_edit_text_changed)

    ($VBoxContainer/InputFieldsGridContainer as GridContainer).add_child(label)
    ($VBoxContainer/InputFieldsGridContainer as GridContainer).add_child(text_field)


func get_text_field(field_name: String) -> LineEdit:
    return $VBoxContainer/InputFieldsGridContainer.find_child(node_name_for_input_text_field(field_name), true, false)


func get_first_text_field() -> LineEdit:
    return $VBoxContainer/InputFieldsGridContainer.find_child("LineEdit_*", true, false)


func update_submit_button(text: String) -> void:
    ($VBoxContainer/HBoxContainer/SubmitButton as Button).disabled = text.is_empty()


func _on_submit_button_pressed() -> void:
    var values: Dictionary[String, String]
    for text_field: LineEdit in $VBoxContainer/InputFieldsGridContainer.find_children("LineEdit_*", "LineEdit", true, false):
        var field_name := text_field.name.trim_prefix("LineEdit_")
        values[field_name] = text_field.text
    submitted.emit.call_deferred(self, values)
    close()


func _on_line_edit_text_changed(_new_text: String) -> void:
    update_submit_button(get_first_text_field().text)
