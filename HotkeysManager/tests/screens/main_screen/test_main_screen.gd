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
    if programgroups.size() == expected_names.size():
        for i in programgroups.size():
            var programgroup: Programgroup = programgroups[i]
            assert_eq(programgroup.programgroup_name, expected_names[i])


func check_programgroup_has_all_programs(programgroup: Programgroup, expected_programs: Array[String]) -> void:
    assert_eq(programgroup.get_program_list().item_count, expected_programs.size())
    for index in programgroup.get_program_list().item_count:
        assert_has(expected_programs, programgroup.get_program_list().get_item_text(index))


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
        5: "Group 5",
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
        5: {
            5: "Photoshop",
        },
    })


func test_main_screen_shows_programgroups() -> void:
    check_has_all_programgroups(["Grafikprogramme", "Group 3", "Group 4", "Group 5", "Texteditoren"])


func test_can_open_New_Program_Group_dialog() -> void:
    main_screen._on_new_group_button_pressed()
    var dialog: EnterTextDialog = main_screen.find_child("EnterTextDialog", true, false)
    assert_not_null(dialog)
    assert_eq(dialog.title, "New Program Group")
    dialog.close()


func test_can_create_new_programgroup() -> void:
    main_screen._on_new_group_dialog_submitted(null, {"programgroup_name": "New Group"})
    check_has_all_programgroups(["Grafikprogramme", "Group 3", "Group 4", "Group 5", "New Group", "Texteditoren"])


func test_can_delete_programgroup() -> void:
    main_screen._on_programgroup_deleted(4)
    check_has_all_programgroups(["Grafikprogramme", "Group 3", "Group 5", "Texteditoren"])
    await wait_idle_frames(1) # wait 1 frame to free the node, so that GUT won't report orphans


func test_can_rename_programgroup() -> void:
    var programgroups := main_screen.find_children("*", "Programgroup", true, false)
    var programgroup: Programgroup = programgroups[2]
    programgroup._on_rename_group_dialog_submitted(null, {"programgroup_name": "AAA"})
    check_has_all_programgroups(["AAA", "Grafikprogramme", "Group 3", "Group 5", "Texteditoren"])
    await wait_idle_frames(1) # wait 1 frame to free the node, so that GUT won't report orphans


func test_update_programgroups_after_a_program_has_been_edited() -> void:
    var program_list: ProgramList = main_screen.find_child("ProgramList", true, false)
    program_list._on_edit_program_dialog_submitted(null, {"name": "New Program", "abbreviation": "newp"}, 4)
    var programgroups := main_screen.find_children("*", "Programgroup", true, false)
    var programgroup1: Programgroup = programgroups[0]
    var programgroup2: Programgroup = programgroups[1]
    check_programgroup_has_all_programs(programgroup1, ["Photoshop", "Illustrator", "New Program"])
    check_programgroup_has_all_programs(programgroup2, ["New Program", "Firefox", "Vivaldi", "Chrome"])
    await wait_idle_frames(1) # wait 1 frame, so that GUT won't report orphans


func test_update_programgroups_after_a_program_has_been_deleted() -> void:
    var program_list: ProgramList = main_screen.find_child("ProgramList", true, false)
    program_list._on_delete_program_dialog_confirmed(null, 4)
    var programgroups := main_screen.find_children("*", "Programgroup", true, false)
    var programgroup1: Programgroup = programgroups[0]
    var programgroup2: Programgroup = programgroups[1]
    check_programgroup_has_all_programs(programgroup1, ["Photoshop", "Illustrator"])
    check_programgroup_has_all_programs(programgroup2, ["Firefox", "Vivaldi", "Chrome"])
    await wait_idle_frames(1) # wait 1 frame, so that GUT won't report orphans
