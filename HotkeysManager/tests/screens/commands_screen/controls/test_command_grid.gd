extends GutTest

const commands_screen_scene: PackedScene = preload("uid://de72ge75p8811")

var commands_screen: CommandsScreen = null
var command_grid: CommandGrid = null


func before_all() -> void:
    var db: Database = Database.new()
    db.open(":memory:")

    const programgroup_id := 3
    commands_screen = commands_screen_scene.instantiate()
    commands_screen.setup(db, programgroup_id)
    add_child(commands_screen)
    command_grid = commands_screen.find_child("CommandGrid", true, false)


func after_all() -> void:
    commands_screen.queue_free()


func test_number_of_grid_cells() -> void:
    assert_eq(command_grid.get_child_count(), 4 * 10)


func test_command_button_titles() -> void:
    var expected_titles: Array[String] = ["New Tab", "Close Tab", "New Window"]
    var command_button_titles: Array[String] = []

    for button: Button in command_grid.find_children("*", "Button", true, false):
        if button.theme_type_variation == "CommandButton":
            command_button_titles.append(button.text)

    assert_eq(command_button_titles.size(), expected_titles.size())

    for title in expected_titles:
        assert_has(command_button_titles, title)
