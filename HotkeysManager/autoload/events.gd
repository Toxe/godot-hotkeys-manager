extends Node

@warning_ignore_start("unused_signal")

signal switch_to_main_screen
signal switch_to_commands_screen
signal switch_to_hotkeys_screen
signal error(text: String, message: String)
signal database_query_succeeded(query_type: StringName, dur: float, num_rows: int)
signal database_query_failed(query_type: StringName, dur: float, error_message: String)

@warning_ignore_restore("unused_signal")
