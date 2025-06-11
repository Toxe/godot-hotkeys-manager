class_name StatusBar extends PanelContainer

var select_counter := 0
var insert_counter := 0
var delete_counter := 0
var update_counter := 0
var error_counter := 0
var num_rows_counter := 0

@onready var select_counter_label: Label = $HBoxContainer/SelectCounterLabel
@onready var insert_counter_label: Label = $HBoxContainer/InsertCounterLabel
@onready var delete_counter_label: Label = $HBoxContainer/DeleteCounterLabel
@onready var update_counter_label: Label = $HBoxContainer/UpdateCounterLabel
@onready var error_counter_label: Label = $HBoxContainer/ErrorCounterLabel


func _ready() -> void:
    Events.error.connect(_on_error)
    Events.database_query_succeeded.connect(_on_database_query_succeeded)
    Events.database_query_failed.connect(_on_database_query_failed)


func _on_error(_error_message: String) -> void:
    error_counter = increase_counter_and_update_label(error_counter, error_counter_label)


func _on_database_query_succeeded(query_type: StringName, _dur: float, num_rows: int) -> void:
    match query_type:
        &"SELECT": increase_select_counters_and_update_label(num_rows)
        &"INSERT": insert_counter = increase_counter_and_update_label(insert_counter, insert_counter_label)
        &"DELETE": delete_counter = increase_counter_and_update_label(delete_counter, delete_counter_label)
        &"UPDATE": update_counter = increase_counter_and_update_label(update_counter, update_counter_label)


func _on_database_query_failed(_query_type: StringName, _dur: float, _error_message: String) -> void:
    error_counter = increase_counter_and_update_label(error_counter, error_counter_label)


func increase_counter_and_update_label(counter: int, label: Label) -> int:
    counter += 1
    label.text = "%s %d" % [label.text.substr(0, 1), counter]
    return counter


func increase_select_counters_and_update_label(num_rows: int) -> void:
    select_counter += 1
    num_rows_counter += num_rows
    select_counter_label.text = "%s %d (%d rows)" % [select_counter_label.text.substr(0, 1), select_counter, num_rows_counter]
