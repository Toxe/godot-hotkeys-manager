extends Control

const error_screen_scene = preload("res://ui/screens/error_screen/error_screen.tscn")
const main_screen_scene = preload("res://ui/screens/main_screen/main_screen.tscn")
const commands_screen_scene = preload("res://ui/screens/commands_screen/commands_screen.tscn")
const hotkeys_screen_scene = preload("res://ui/screens/hotkeys_screen/hotkeys_screen.tscn")

var db: SQLite = null


func _ready() -> void:
    Events.switch_to_main_screen.connect(_on_switch_to_main_screen)
    Events.switch_to_commands_screen.connect(_on_switch_to_commands_screen)
    Events.switch_to_hotkeys_screen.connect(_on_switch_to_hotkeys_screen)

    db = open_database("user://hotkeys.sqlite")

    if db:
        switch_screen(load_screen(main_screen_scene))


func load_screen(scene: PackedScene) -> Control:
    return scene.instantiate()


func switch_screen(screen: Control) -> void:
    for child in get_children():
        remove_child(child)
        child.queue_free()
    add_child(screen)


func show_error(text: String, message: String) -> void:
    var error_screen: ErrorScreen = load_screen(error_screen_scene)
    error_screen.error_text = text
    error_screen.error_message = message
    switch_screen(error_screen)


func open_database(db_name: String) -> SQLite:
    var db_needs_to_be_created := !FileAccess.file_exists(db_name)
    var local_db := SQLite.new()
    local_db.path = db_name
    local_db.foreign_keys = true
    local_db.verbosity_level = SQLite.VerbosityLevel.NORMAL

    if !local_db.open_db():
        show_error("Unable to open database.", local_db.error_message)
        close_and_delete_database(local_db, db_name)
        return null

    if db_needs_to_be_created:
        if !create_database_structure(local_db):
            close_and_delete_database(local_db, db_name)
            return null

    return local_db


func create_database_structure(local_db: SQLite) -> bool:
    var sql := FileAccess.get_file_as_string("res://database.sql")

    if sql.is_empty():
        show_error("Unable to create database.", "File open error: %d" % FileAccess.get_open_error())
        return false

    if !local_db.query(sql):
        show_error("Unable to create database.", local_db.error_message)
        return false

    return true


func close_and_delete_database(local_db: SQLite, db_name: String) -> void:
    if local_db:
        local_db.close_db()

    if FileAccess.file_exists(db_name):
        DirAccess.remove_absolute(db_name)


func _on_switch_to_main_screen() -> void:
    switch_screen(load_screen(main_screen_scene))


func _on_switch_to_commands_screen() -> void:
    switch_screen(load_screen(commands_screen_scene))


func _on_switch_to_hotkeys_screen() -> void:
    switch_screen(load_screen(hotkeys_screen_scene))
