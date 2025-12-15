extends GutTest

const commands_screen_scene: PackedScene = preload("uid://de72ge75p8811")


class TestStaticFunctions extends GutTest:
    var db: Database = null
    var programgroup_id := 3

    func before_each() -> void:
        db = Database.new()
        db.open(":memory:")

    func test_query_all_commands() -> void:
        var commands := CommandsScreen.query_all_commands(db)
        assert_eq_deep(commands, {
            1: "Go to File",
            2: "Go to Next Editor Tab",
            3: "New Tab",
            4: "New Window",
            5: "Close Tab",
            6: "Close All Tabs",
            7: "Quit",
        })

    func test_query_programs() -> void:
        var programs := CommandsScreen.query_programs(db, programgroup_id)
        assert_eq_deep(programs, {
            7: "Krita",
            8: "Firefox",
            9: "Vivaldi",
            10: "Chrome",
        })

    func test_query_program_abbreviations() -> void:
        var program_abbreviations := CommandsScreen.query_program_abbreviations(db, programgroup_id)
        assert_eq_deep(program_abbreviations, {
            7: "Kr",
            8: "FF",
            9: "Viv",
            10: "Chr",
        })

    func test_query_query_program_icons() -> void:
        var program_icons := CommandsScreen.query_program_icons(db, programgroup_id)
        assert_eq(program_icons.size(), 4)

    func test_query_commands() -> void:
        var commands := CommandsScreen.query_commands(db, programgroup_id)
        assert_eq_deep(commands, {
            3: "New Tab",
            5: "Close Tab",
        })

    func test_query_program_command_hotkeys() -> void:
        var program_command_hotkeys := CommandsScreen.query_program_command_hotkeys(db, programgroup_id)
        assert_eq_deep(program_command_hotkeys, {
            3: {
                8: ["Ctrl+T"],
            },
            5: {
                8: ["Ctrl+F4"],
                9: ["Ctrl+F4", "Ctrl+W"],
                10: ["Ctrl+W"],
            },
        })

    func test_query_user_hotkeys_by_commands() -> void:
        var user_hotkeys_by_commands := CommandsScreen.query_user_hotkeys_by_commands(db, programgroup_id)
        assert_eq_deep(user_hotkeys_by_commands, {
            5: {"user_hotkey_id": 3, "user_hotkey": "Ctrl+F4", "command_name": "Close Tab"},
        })

    func test_query_user_hotkeys_by_programs() -> void:
        var user_hotkeys_by_programs := CommandsScreen.query_user_hotkeys_by_programs(db, programgroup_id)
        assert_eq_deep(user_hotkeys_by_programs, {
            4: {"user_hotkey_id": 4, "user_hotkey": "Ctrl+N", "command_name": "New Window"},
            5: {"user_hotkey_id": 3, "user_hotkey": "Ctrl+F4", "command_name": "Close Tab"},
        })

    func test_query_user_hotkey_programs() -> void:
        var user_hotkey_programs := CommandsScreen.query_user_hotkey_programs(db, programgroup_id)
        assert_eq_deep(user_hotkey_programs, {
            4: {"user_hotkey_id": 4, "hotkeys": [9]},
            5: {"user_hotkey_id": 3, "hotkeys": [7, 8]},
        })


class TestInstancedClass extends GutTest:
    var commands_screen: CommandsScreen = null

    func before_each() -> void:
        const programgroup_id := 3
        var db: Database = Database.new()
        db.open(":memory:")
        commands_screen = autofree(commands_screen_scene.instantiate())
        commands_screen.setup(db, programgroup_id)

    func test_can_delete_command() -> void:
        var old_count := CommandsScreen.query_all_commands(commands_screen._db).size()
        commands_screen._on_delete_command_dialog_submitted(null, [1, 3])
        var new_count := CommandsScreen.query_all_commands(commands_screen._db).size()
        assert_eq(new_count, old_count - 2)

    func test_can_open_Delete_Command_dialog() -> void:
        commands_screen._on_delete_command_button_pressed()
        var dialog: SelectionDialog = commands_screen.find_child("SelectionDialog", true, false)
        assert_not_null(dialog)
        assert_eq(dialog.title, "Delete Command")
        dialog.close()
