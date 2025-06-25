extends Node

enum LogLevel {
    ERROR,
    NORMAL,
}

@export var log_level := LogLevel.ERROR


func _ready() -> void:
    Events.error.connect(_on_error)
    Events.database_query_succeeded.connect(_on_database_query_succeeded)
    Events.database_query_failed.connect(_on_database_query_failed)


func build_prefix() -> String:
    return "%s #%d |" % [Time.get_time_string_from_system(), Engine.get_process_frames()]


func _on_error(error_message: String) -> void:
    printerr("%s %s" % [build_prefix(), error_message])


func _on_database_query_succeeded(query_type: StringName, dur: float, num_rows: int) -> void:
    if log_level == LogLevel.NORMAL:
        var suffix := (" (%d rows)" % num_rows) if query_type == &"SELECT" else ""
        print_rich("[color=darkgray]%s[/color] [color=green]%s:[/color] %.03f ms%s" % [build_prefix(), query_type, dur / 1000.0, suffix])


func _on_database_query_failed(query_type: StringName, dur: float, error_message: String) -> void:
    printerr("%s %s error: %s (%.03f ms)" % [build_prefix(), query_type, error_message, dur / 1000.0])
