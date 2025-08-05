extends GutTest

const programgroup_scene: PackedScene = preload("uid://ctfylvylgevof")

var programgroup: Programgroup = null


func before_each() -> void:
    var db: Database = Database.new()
    db.open(":memory:")

    const programgroup_id := 1
    const programgroup_name := "Texteditoren"
    const programs: Dictionary = {1: "CLion", 2: "Visual Studio", 3: "Visual Studio Code", 4: "Obsidian"}
    programgroup = autofree(programgroup_scene.instantiate())
    programgroup.setup(db, programgroup_id, programgroup_name, programs)


func check_has_all_programs(expected_programs: Array[String]) -> void:
    assert_eq(programgroup.get_program_list().item_count, expected_programs.size())
    for index in programgroup.get_program_list().item_count:
        assert_has(expected_programs, programgroup.get_program_list().get_item_text(index))


func test_query_programs() -> void:
    var programgroup1: Programgroup = autofree(programgroup_scene.instantiate())
    var programgroup2: Programgroup = autofree(programgroup_scene.instantiate())
    var programgroup3: Programgroup = autofree(programgroup_scene.instantiate())
    var programgroup4: Programgroup = autofree(programgroup_scene.instantiate())
    programgroup1.setup(programgroup._db, 1, "Programgroup 1", {})
    programgroup2.setup(programgroup._db, 2, "Programgroup 2", {})
    programgroup3.setup(programgroup._db, 3, "Programgroup 3", {})
    programgroup4.setup(programgroup._db, 4, "Programgroup 4", {})

    assert_eq_deep(programgroup1.query_programs(), {
        1: "CLion",
        2: "Visual Studio",
        3: "Visual Studio Code",
        4: "Obsidian",
    })
    assert_eq_deep(programgroup2.query_programs(), {
        5: "Photoshop",
        6: "Illustrator",
        7: "Krita",
    })
    assert_eq_deep(programgroup3.query_programs(), {
        7: "Krita",
        8: "Firefox",
        9: "Vivaldi",
        10: "Chrome",
    })
    assert_eq_deep(programgroup4.query_programs(), {})


func test_query_available_programs() -> void:
    var programgroup1: Programgroup = autofree(programgroup_scene.instantiate())
    var programgroup2: Programgroup = autofree(programgroup_scene.instantiate())
    var programgroup3: Programgroup = autofree(programgroup_scene.instantiate())
    var programgroup4: Programgroup = autofree(programgroup_scene.instantiate())
    programgroup1.setup(programgroup._db, 1, "Programgroup 1", {})
    programgroup2.setup(programgroup._db, 2, "Programgroup 2", {})
    programgroup3.setup(programgroup._db, 3, "Programgroup 3", {})
    programgroup4.setup(programgroup._db, 4, "Programgroup 4", {})

    assert_eq_deep(programgroup1.query_available_programs(), {
        5: "Photoshop",
        6: "Illustrator",
        7: "Krita",
        8: "Firefox",
        9: "Vivaldi",
        10: "Chrome",
    })
    assert_eq_deep(programgroup2.query_available_programs(), {
        1: "CLion",
        2: "Visual Studio",
        3: "Visual Studio Code",
        4: "Obsidian",
        8: "Firefox",
        9: "Vivaldi",
        10: "Chrome",
    })
    assert_eq_deep(programgroup3.query_available_programs(), {
        1: "CLion",
        2: "Visual Studio",
        3: "Visual Studio Code",
        4: "Obsidian",
        5: "Photoshop",
        6: "Illustrator",
    })
    assert_eq_deep(programgroup4.query_available_programs(), {
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


func test_programgroup_has_name() -> void:
    assert_eq(programgroup.programgroup_name, "Texteditoren")


func test_can_rename_programgroup() -> void:
    programgroup._on_rename_group_dialog_submitted(null, "New Name")
    assert_eq(programgroup.programgroup_name, "New Name")
    assert_eq(programgroup._db.select_value("programgroup", "programgroup_id=%d" % programgroup._programgroup_id, "name"), "New Name")


func test_can_delete_programgroup() -> void:
    watch_signals(programgroup)
    programgroup._on_delete_group_dialog_confirmed(null)
    assert_signal_emitted(programgroup.programgroup_deleted)
    assert_null(programgroup._db.select_value("programgroup", "programgroup_id=%d" % programgroup._programgroup_id, "programgroup_id"))


func test_program_list_shows_programs() -> void:
    check_has_all_programs(["CLion", "Visual Studio", "Visual Studio Code", "Obsidian"])


func test_can_add_a_program() -> void:
    programgroup._on_add_program_dialog_submitted(null, [7])
    check_has_all_programs(["CLion", "Visual Studio", "Visual Studio Code", "Obsidian", "Krita"])


func test_can_add_multiple_programs() -> void:
    programgroup._on_add_program_dialog_submitted(null, [5, 6])
    check_has_all_programs(["CLion", "Visual Studio", "Visual Studio Code", "Obsidian", "Illustrator", "Photoshop"])


func test_cannot_add_a_program_twice() -> void:
    programgroup._on_add_program_dialog_submitted(null, [7])
    check_has_all_programs(["CLion", "Visual Studio", "Visual Studio Code", "Obsidian", "Krita"])

    programgroup._on_add_program_dialog_submitted(null, [7])
    check_has_all_programs(["CLion", "Visual Studio", "Visual Studio Code", "Obsidian", "Krita"])


func test_cannot_add_unavailable_programs() -> void:
    programgroup._on_add_program_dialog_submitted(null, [1001, 1002])
    check_has_all_programs(["CLion", "Visual Studio", "Visual Studio Code", "Obsidian"])


func test_can_remove_a_program() -> void:
    programgroup.select_program_list_item(1)
    programgroup._on_remove_program_button_pressed()
    check_has_all_programs(["CLion", "Visual Studio Code", "Obsidian"])


func test_no_list_item_is_selected_in_the_beginning() -> void:
    assert_lt(programgroup.get_selected_program_list_item(), 0)


func test_program_list_contains_existing_programs() -> void:
    for program_id: int in [1, 2, 3, 4]:
        assert_true(programgroup.program_list_contains_program(program_id), "program_id=%d" % program_id)


func test_program_list_contains_non_existing_programs() -> void:
    for program_id: int in [-1, 0, 5, 6]:
        assert_false(programgroup.program_list_contains_program(program_id), "program_id=%d" % program_id)


func test_select_non_existing_program_list_items() -> void:
    # no item is selected by default
    programgroup.select_program_list_item(-1)
    assert_lt(programgroup.get_selected_program_list_item(), 0)
    programgroup.select_program_list_item(99)
    assert_lt(programgroup.get_selected_program_list_item(), 0)

    # after selecting an existing item, keep current selection
    programgroup.select_program_list_item(1)

    programgroup.select_program_list_item(-1)
    assert_eq(programgroup.get_selected_program_list_item(), 1)
    programgroup.select_program_list_item(99)
    assert_eq(programgroup.get_selected_program_list_item(), 1)


func test_select_existing_program_list_items() -> void:
    for i in programgroup.get_program_list().item_count:
        programgroup.select_program_list_item(i)
        assert_eq(programgroup.get_selected_program_list_item(), i)


func test_the_remove_button_is_disabled_by_default() -> void:
    var button: Button = programgroup.find_child("RemoveProgramButton", true, false)
    assert_true(button.disabled)


func test_selecting_a_program_by_clicking_a_list_item_enables_the_remove_button() -> void:
    var button: Button = programgroup.find_child("RemoveProgramButton", true, false)
    programgroup._on_program_list_item_selected(1)
    assert_false(button.disabled)


func test_selecting_a_program_by_calling_select_program_list_item_enables_the_remove_button() -> void:
    var button: Button = programgroup.find_child("RemoveProgramButton", true, false)
    programgroup.select_program_list_item(1)
    assert_false(button.disabled)


func test_removing_a_program_selects_the_next_item_in_the_list() -> void:
    programgroup.select_program_list_item(2)

    programgroup._on_remove_program_button_pressed()
    assert_eq(programgroup.get_selected_program_list_item(), 2)
    programgroup._on_remove_program_button_pressed()
    assert_eq(programgroup.get_selected_program_list_item(), 1)
    programgroup._on_remove_program_button_pressed()
    assert_eq(programgroup.get_selected_program_list_item(), 0)
    programgroup._on_remove_program_button_pressed()
    assert_lt(programgroup.get_selected_program_list_item(), 0)


func test_removing_the_last_program_disables_the_remove_button() -> void:
    var button: Button = programgroup.find_child("RemoveProgramButton", true, false)
    programgroup.select_program_list_item(0)

    for i in programgroup.get_program_list().item_count:
        assert_false(button.disabled)
        programgroup._on_remove_program_button_pressed()

    assert_true(button.disabled)


func test_can_open_Rename_Group_dialog() -> void:
    programgroup._on_rename_group_button_pressed()
    var dialog: EnterTextDialog = programgroup.find_child("EnterTextDialog", true, false)
    assert_not_null(dialog)
    dialog.close()
