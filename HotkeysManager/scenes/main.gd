extends Control

const main_screen_scene = preload("uid://b2csr7tbxjl3k")
const commands_screen_scene = preload("uid://de72ge75p8811")
const hotkeys_screen_scene = preload("uid://b3a0qoyhinuec")

var _db: Database = Database.new()


func _ready() -> void:
    (get_node("/root/ConsoleLogger") as ConsoleLogger).log_level = ConsoleLogger.LogLevel.NORMAL

    Events.switch_to_main_screen.connect(switch_to_main_screen)
    Events.switch_to_commands_screen.connect(switch_to_commands_screen)
    Events.switch_to_hotkeys_screen.connect(switch_to_hotkeys_screen)

    if _db.open("user://hotkeys.sqlite"):
        switch_to_main_screen()


func load_screen(scene: PackedScene) -> Control:
    return scene.instantiate()


func switch_screen(screen: Control) -> void:
    for child in $VBoxContainer/Screens.get_children():
        $VBoxContainer/Screens.remove_child(child)
        child.queue_free()
    $VBoxContainer/Screens.add_child(screen)


func switch_to_main_screen() -> void:
    var screen: MainScreen = load_screen(main_screen_scene)
    screen.setup(_db)
    switch_screen(screen)


func switch_to_commands_screen(programgroup_id: int) -> void:
    var screen: CommandsScreen = load_screen(commands_screen_scene)
    screen.setup(_db, programgroup_id)
    switch_screen(screen)


func switch_to_hotkeys_screen() -> void:
    var screen: HotkeysScreen = load_screen(hotkeys_screen_scene)
    screen.setup(_db)
    switch_screen(screen)
