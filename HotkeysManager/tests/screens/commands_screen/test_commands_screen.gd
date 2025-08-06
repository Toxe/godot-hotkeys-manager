extends GutTest

const commands_screen_scene: PackedScene = preload("uid://de72ge75p8811")

var commands_screen: CommandsScreen = null


func before_each() -> void:
    var db: Database = Database.new()
    db.open(":memory:")

    const programgroup_id := 3
    commands_screen = autofree(commands_screen_scene.instantiate())
    commands_screen.setup(db, programgroup_id)


func test_query_programs() -> void:
    var programs := commands_screen.query_programs(commands_screen._programgroup_id)
    assert_eq_deep(programs, {
        7: "Krita",
        8: "Firefox",
        9: "Vivaldi",
        10: "Chrome",
    })


func test_query_program_abbreviations() -> void:
    var program_abbreviations := commands_screen.query_program_abbreviations(commands_screen._programgroup_id)
    assert_eq_deep(program_abbreviations, {
          7: "Kr",
          8: "FF",
          9: "Viv",
          10: "Chr",
    })


func test_query_commands() -> void:
    var commands := commands_screen.query_commands(commands_screen._programgroup_id)
    assert_eq_deep(commands, {
          3: "New Tab",
          5: "Close Tab",
    })


func test_query_program_commands() -> void:
    var program_commands := commands_screen.query_program_commands(commands_screen._programgroup_id)
    assert_eq_deep(program_commands, {
          3: {8: {"program_command_id": 9, "program_command_name": "New Tab"}},
          5: {10: {"program_command_id": 10, "program_command_name": "Close Tab"}},
    })


func test_query_program_command_hotkeys() -> void:
    var program_command_hotkeys := commands_screen.query_program_command_hotkeys(commands_screen._programgroup_id)
    assert_eq_deep(program_command_hotkeys, {
          3: {8: ["Ctrl+T"]},
          5: {10: ["Ctrl+W"]},
    })


func test_query_user_hotkeys_by_commands() -> void:
    var user_hotkeys_by_commands := commands_screen.query_user_hotkeys_by_commands(commands_screen._programgroup_id)
    assert_eq_deep(user_hotkeys_by_commands, {
          5: {"user_hotkey_id": 3, "user_hotkey": "Ctrl+W", "command_name": "Close Tab"},
    })


func test_query_user_hotkeys_by_programs() -> void:
    var user_hotkeys_by_programs := commands_screen.query_user_hotkeys_by_programs(commands_screen._programgroup_id)
    assert_eq_deep(user_hotkeys_by_programs, {
          4: {"user_hotkey_id": 4, "user_hotkey": "Ctrl+N", "command_name": "New Window"},
          5: {"user_hotkey_id": 3, "user_hotkey": "Ctrl+W", "command_name": "Close Tab"},
    })


func test_query_user_hotkey_programs() -> void:
    var user_hotkey_programs := commands_screen.query_user_hotkey_programs(commands_screen._programgroup_id)
    assert_eq_deep(user_hotkey_programs, {
          4: {"user_hotkey_id": 4, "hotkeys": [9]},
          5: {"user_hotkey_id": 3, "hotkeys": [7, 8]},
    })
