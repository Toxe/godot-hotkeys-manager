extends GutTest

const main_screen_scene: PackedScene = preload("uid://b2csr7tbxjl3k")

var main_screen: MainScreen = null


func before_each() -> void:
    var db: Database = Database.new()
    db.verbosity_level = SQLite.VerbosityLevel.QUIET
    db.open(":memory:")

    main_screen = autofree(main_screen_scene.instantiate())
    main_screen.setup(db)


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
    const expected_names: Array[String] = ["Grafikprogramme", "Texteditoren", "Web Browser"]
    var programgroups := main_screen.find_children("*", "Programgroup", true, false)
    assert_eq(programgroups.size(), expected_names.size())

    for pg: Programgroup in programgroups:
        assert_has(expected_names, pg.programgroup_name)


func test_programgroup_control_has_been_removed_after_programgroup_got_deleted() -> void:
    const expected_names: Array[String] = ["Texteditoren", "Web Browser"]

    main_screen._on_programgroup_deleted(2)
    var programgroups := main_screen.find_children("*", "Programgroup", true, false)
    assert_eq(programgroups.size(), expected_names.size())

    for pg: Programgroup in programgroups:
        assert_has(expected_names, pg.programgroup_name)
