extends GutTest

const programgroup_scene: PackedScene = preload("uid://ctfylvylgevof")

var db: Database = null
var programgroup: Programgroup = null


func before_all() -> void:
    Events.switch_to_main_screen.connect(_load_programgroup)


func before_each() -> void:
    db = Database.new()
    db.verbosity_level = SQLite.VerbosityLevel.QUIET
    db.open(":memory:")

    _load_programgroup()


func after_each() -> void:
    db.close()
    db = null


func _load_programgroup() -> void:
    programgroup = programgroup_scene.instantiate()
    programgroup.setup(db, 1)
    add_child_autofree(programgroup)


func test_has_name() -> void:
    assert_eq(programgroup.programgroup_name, "Texteditoren")


func test_program_list_shows_programs() -> void:
    const expected_programs: Array[String] = ["CLion", "Obsidian", "Visual Studio", "Visual Studio Code"]
    var program_list: ItemList = programgroup.find_child("ProgramList", true, false)
    assert_eq(program_list.item_count, expected_programs.size())

    var names: Array[String]
    for index in program_list.item_count:
        names.append(program_list.get_item_text(index))

    for s in expected_programs:
        assert_has(names, s)


func test_can_add_a_program() -> void:
    const expected_programs: Array[String] = ["CLion", "Obsidian", "Visual Studio", "Visual Studio Code", "Krita"]
    programgroup._on_add_program_dialog_submitted([7])

    await wait_for_signal(Events.switch_to_main_screen, 1.0)

    var program_list: ItemList = programgroup.find_child("ProgramList", true, false)
    assert_eq(program_list.item_count, expected_programs.size())

    var names: Array[String]
    for index in program_list.item_count:
        names.append(program_list.get_item_text(index))

    for s in expected_programs:
        assert_has(names, s)


func test_can_add_multiple_programs() -> void:
    const expected_programs: Array[String] = ["CLion", "Obsidian", "Visual Studio", "Visual Studio Code", "Illustrator", "Photoshop"]
    programgroup._on_add_program_dialog_submitted([5, 6])

    await wait_for_signal(Events.switch_to_main_screen, 1.0)

    var program_list: ItemList = programgroup.find_child("ProgramList", true, false)
    assert_eq(program_list.item_count, expected_programs.size())

    var names: Array[String]
    for index in program_list.item_count:
        names.append(program_list.get_item_text(index))

    for s in expected_programs:
        assert_has(names, s)


func test_cannot_add_a_program_twice() -> void:
    const expected_programs: Array[String] = ["CLion", "Obsidian", "Visual Studio", "Visual Studio Code"]
    programgroup._on_add_program_dialog_submitted([4])

    Events.switch_to_main_screen.emit.call_deferred()
    await wait_for_signal(Events.switch_to_main_screen, 1.0)

    var program_list: ItemList = programgroup.find_child("ProgramList", true, false)
    assert_eq(program_list.item_count, expected_programs.size())

    var names: Array[String]
    for index in program_list.item_count:
        names.append(program_list.get_item_text(index))

    for s in expected_programs:
        assert_has(names, s)


func test_selecting_a_program_enables_the_remove_button() -> void:
    var program_list: ItemList = programgroup.find_child("ProgramList", true, false)
    var button: Button = programgroup.find_child("RemoveProgramButton", true, false)

    assert_true(button.disabled)
    program_list.select(1)
    programgroup._on_program_list_item_selected(1)
    assert_false(button.disabled)


func test_can_remove_a_program() -> void:
    var program_list: ItemList = programgroup.find_child("ProgramList", true, false)
    program_list.select(1)
    programgroup._on_remove_program_button_pressed()

    await wait_for_signal(Events.switch_to_main_screen, 1.0)

    program_list = programgroup.find_child("ProgramList", true, false)
    program_list.select(1)

    const expected_programs: Array[String] = ["CLion", "Visual Studio", "Visual Studio Code"]
    assert_eq(program_list.item_count, expected_programs.size())

    var names: Array[String]
    for index in program_list.item_count:
        names.append(program_list.get_item_text(index))

    for s in expected_programs:
        assert_has(names, s)
