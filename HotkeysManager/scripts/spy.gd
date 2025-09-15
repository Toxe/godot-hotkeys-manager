extends Control


func _notification(what: int) -> void:
    print_rich("%s [color=cornflower_blue]%s[/color] --> %s" % [build_prefix(), Utils.notification_name(what), name])


# show ALL events
func _input(event: InputEvent) -> void:
    print_rich("%s [color=yellow]%s[/color] --> %s [color=darkgray](_input)[/color]" % [build_prefix(), event, name])


func _gui_input(event: InputEvent) -> void:
    print_rich("%s [color=orange]%s[/color] --> %s [color=darkgray](_gui_input)[/color]" % [build_prefix(), event, name])


func _unhandled_input(event: InputEvent) -> void:
    print_rich("%s [color=rosy_brown]%s[/color] --> %s [color=darkgray](_unhandled_input)[/color]" % [build_prefix(), event, name])


func build_prefix() -> String:
    return "[color=dark_gray]%0.3f ms, #%d:[/color]" % [Time.get_ticks_usec() / 1000.0, Engine.get_process_frames()]
