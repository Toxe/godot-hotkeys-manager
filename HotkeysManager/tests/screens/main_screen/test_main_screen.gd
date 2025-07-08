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


func test_query_programgroups() -> void:
    var programgroups := main_screen.query_programgroups()
    assert_eq_deep(programgroups, {
        1: "Texteditoren",
        2: "Grafikprogramme",
        3: "Web Browser",
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
    })


func test_main_screen_shows_programgroups() -> void:
    check_has_all_programgroups(["Grafikprogramme", "Texteditoren", "Web Browser"])


func test_can_remove_programgroup() -> void:
    main_screen._on_programgroup_deleted(2)
    check_has_all_programgroups(["Texteditoren", "Web Browser"])
    await wait_process_frames(1) # wait 1 frame to free the node, so that GUT won't report orphans


func test_can_create_new_program() -> void:
    main_screen._on_new_program_dialog_submitted(null, "New Program")
    assert_gt(main_screen._db.select_value("program", "name='New Program'", "id"), 0)


func test_can_create_new_programgroup() -> void:
    main_screen._on_new_group_dialog_submitted(null, "New Group")
    check_has_all_programgroups(["Grafikprogramme", "Texteditoren", "Web Browser", "New Group"])


func test_can_open_New_Program_dialog() -> void:
    main_screen._on_new_program_button_pressed()
    var dialog: EnterTextDialog = main_screen.find_child("EnterTextDialog", true, false)
    assert_not_null(dialog)
    dialog.close()


func test_can_open_New_Program_Group_dialog() -> void:
    main_screen._on_new_group_button_pressed()
    var dialog: EnterTextDialog = main_screen.find_child("EnterTextDialog", true, false)
    assert_not_null(dialog)
    dialog.close()
