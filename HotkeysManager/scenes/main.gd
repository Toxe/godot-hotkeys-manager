extends Control

var db: SQLite = null


func _ready() -> void:
    db = open_database("user://hotkeys.sqlite")


func show_error(text: String, message: String) -> void:
    printerr(text)
    printerr(message)
    ($ErrorView/ErrorText as Label).text = "Error: %s" % text
    ($ErrorView/ErrorMessage as Label).text = message
    ($Content as Control).visible = false
    ($ErrorView as Control).visible = true


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
