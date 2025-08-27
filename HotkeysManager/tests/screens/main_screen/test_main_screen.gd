extends GutTest

const main_screen_scene: PackedScene = preload("uid://b2csr7tbxjl3k")

var main_screen: MainScreen = null


func before_each() -> void:
    var db: Database = Database.new()
    db.open(":memory:")

    main_screen = autofree(main_screen_scene.instantiate())
    main_screen.setup(db)


func check_has_all_programgroups(expected_names: Array[String]) -> void:
    var programgroups := main_screen.find_children("*", "Programgroup", true, false)
    assert_eq(programgroups.size(), expected_names.size())
    for pg: Programgroup in programgroups:
        assert_has(expected_names, pg.programgroup_name)


func test_query_programs() -> void:
    var programs := main_screen.query_programs()
    assert_eq_deep(programs, {
        1: "CLion",
        2: "Visual Studio",
        3: "Visual Studio Code",
        4: "Obsidian",
        5: "Photoshop",
        6: "Illustrator",
        7: "Krita",
        8: "Firefox",
        9: "Vivaldi",
        10: "Chrome",
    })


func test_query_programgroups() -> void:
    var programgroups := main_screen.query_programgroups()
    assert_eq_deep(programgroups, {
        1: "Texteditoren",
        2: "Grafikprogramme",
        3: "Group 3",
        4: "Group 4",
    })


func test_query_programgroup_programs() -> void:
    var programgroup_programs := main_screen.query_programgroup_programs()
    assert_eq_deep(programgroup_programs, {
        1: {
            1: "CLion",
            2: "Visual Studio",
            3: "Visual Studio Code",
            4: "Obsidian",
        },
        2: {
            5: "Photoshop",
            6: "Illustrator",
            7: "Krita",
        },
        3: {
            7: "Krita",
            8: "Firefox",
            9: "Vivaldi",
            10: "Chrome",
        },
    })


func test_main_screen_shows_programgroups() -> void:
    check_has_all_programgroups(["Grafikprogramme", "Texteditoren", "Group 3", "Group 4"])


func test_can_remove_programgroup() -> void:
    main_screen._on_programgroup_deleted(2)
    check_has_all_programgroups(["Texteditoren", "Group 3", "Group 4"])
    await wait_process_frames(1) # wait 1 frame to free the node, so that GUT won't report orphans


func test_can_create_new_program() -> void:
    main_screen._on_new_program_dialog_submitted(null, {"name": "New Program", "abbreviation": "newp"})
    assert_gt(main_screen._db.select_value("program", "name='New Program' AND abbreviation='newp'", "program_id"), 0)


func test_can_delete_program() -> void:
    var old_count := main_screen.query_programs().size()
    main_screen._on_delete_program_dialog_submitted(null, [1, 3, 5])
    var new_count := main_screen.query_programs().size()
    assert_eq(new_count, old_count - 3)


func test_can_create_new_programgroup() -> void:
    main_screen._on_new_group_dialog_submitted(null, {"programgroup_name": "New Group"})
    check_has_all_programgroups(["Grafikprogramme", "Texteditoren", "Group 3", "Group 4", "New Group"])


func test_can_open_New_Program_dialog() -> void:
    main_screen._on_new_program_button_pressed()
    var dialog: EnterTextDialog = main_screen.find_child("EnterTextDialog", true, false)
    assert_not_null(dialog)
    assert_eq(dialog.title, "New Program")
    dialog.close()


func test_can_open_Delete_Program_dialog() -> void:
    main_screen._on_delete_program_button_pressed()
    var dialog: SelectionDialog = main_screen.find_child("SelectionDialog", true, false)
    assert_not_null(dialog)
    assert_eq(dialog.title, "Delete Program")
    dialog.close()


func test_can_open_New_Program_Group_dialog() -> void:
    main_screen._on_new_group_button_pressed()
    var dialog: EnterTextDialog = main_screen.find_child("EnterTextDialog", true, false)
    assert_not_null(dialog)
    assert_eq(dialog.title, "New Program Group")
    dialog.close()
