class_name AddCommandDialog extends BaseDialog

signal submitted(dialog: AddCommandDialog, options: Dictionary[String, Variant])

const dialog_scene: PackedScene = preload("uid://b338c6ai1jquw")
const command_input_row_scene: PackedScene = preload("uid://d336yo3y6ycap")

var command_input_rows: Array[CommandInputRow] = []

@export var label_text: String:
    set(value):
        label_text = value
        get_label().text = label_text


## Create and show a new dialog. Unless parent is [code]null[/code] it will automatically be added to the parent as a child.
static func open_dialog(parent: Node, label: String, callable: Callable, programs: Dictionary[int, String], commands: Dictionary[int, String]) -> AddCommandDialog:
    var dialog: AddCommandDialog = dialog_scene.instantiate()
    dialog.label_text = label
    dialog.submitted.connect(callable)

    var list := dialog.get_list()
    for command_id: int in commands:
        var command_name := commands[command_id]
        var index := list.add_item(command_name)
        list.set_item_metadata(index, command_id)

    for program_id: int in programs:
        var program_name := programs[program_id]
        var row: CommandInputRow = command_input_row_scene.instantiate()
        row.setup(program_id, program_name)
        dialog.add_command_input_row(row)

    if parent:
        parent.add_child(dialog)

    return dialog


func _ready() -> void:
    super._ready()
    update_submit_button_status()


func get_label() -> RichTextLabel:
    return $VBoxContainer/VBoxContainer/RichTextLabel


func get_list() -> ItemList:
    return $VBoxContainer/VBoxContainer/ItemList


func add_command_input_row(row: CommandInputRow) -> void:
    row.command_input_changed.connect(_on_command_input_changed)
    command_input_rows.append(row)
    $VBoxContainer/VBoxContainer.add_child(row)


func update_submit_button_status() -> void:
    ($VBoxContainer/HBoxContainer/SubmitButton as Button).disabled = true
    if get_list().is_anything_selected():
        for row in command_input_rows:
            if row.has_complete_input():
                ($VBoxContainer/HBoxContainer/SubmitButton as Button).disabled = false
                break


func _on_submit_button_pressed() -> void:
    var index := get_list().get_selected_items().get(0)
    var command_id: int = get_list().get_item_metadata(index)
    var program_commands: Array[Dictionary] = []
    var options: Dictionary[String, Variant] = {"command": command_id, "program_commands": program_commands}

    for row in command_input_rows:
        if row.has_complete_input():
            var program_command: Dictionary[String, Variant] = {
                "program_id": row.get_program_id(),
                "title": row.get_command_title(),
                "hotkey": row.get_hotkey()}
            program_commands.append(program_command)

    close()
    submitted.emit(self, options)


func _on_item_list_item_selected(_index: int) -> void:
    update_submit_button_status()


func _on_command_input_changed() -> void:
    update_submit_button_status()
