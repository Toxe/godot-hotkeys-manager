class_name BaseDialog extends Window

signal canceled(dialog: BaseDialog)


func _ready() -> void:
    close_requested.connect(_on_cancel_requested)


func close() -> void:
    queue_free()


func _on_cancel_requested() -> void:
    close()
    canceled.emit(self)
