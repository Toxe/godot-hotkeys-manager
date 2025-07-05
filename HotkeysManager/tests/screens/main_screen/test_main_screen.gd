extends GutTest

const main_screen_scene: PackedScene = preload("uid://b2csr7tbxjl3k")

var db: Database = null
var screen: MainScreen = null


func before_each() -> void:
    db = Database.new()
    db.verbosity_level = SQLite.VerbosityLevel.QUIET
    db.open(":memory:")

    screen = main_screen_scene.instantiate()
    screen.setup(db)
    add_child_autofree(screen)


func after_each() -> void:
    db.close()
    db = null


func test_main_screen_shows_programgroups() -> void:
    const expected_names: Array[String] = ["Grafikprogramme", "Texteditoren"]
    var programgroups := screen.find_children("*", "Programgroup", true, false)
    assert_eq(programgroups.size(), expected_names.size())

    for pg: Programgroup in programgroups:
        assert_has(expected_names, pg.programgroup_name)
