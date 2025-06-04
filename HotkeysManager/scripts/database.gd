class_name Database

var db: SQLite = null

class QueryResult:
    var ok: bool
    var rows: Array = []


func open(db_name: String) -> bool:
    var db_needs_to_be_created := !FileAccess.file_exists(db_name)
    db = SQLite.new()
    db.path = db_name
    db.foreign_keys = true
    db.verbosity_level = SQLite.VerbosityLevel.NORMAL

    if !db.open_db():
        show_error("Unable to open database.", db.error_message)
        close()
        return false

    if db_needs_to_be_created:
        if !create_database_structure():
            close_and_delete_database()
            return false

    return true


func close() -> void:
    assert(is_open())

    db.close_db()
    db = null


func close_and_delete_database() -> void:
    assert(is_open())

    var filename := db.path
    close()

    if FileAccess.file_exists(filename):
        DirAccess.remove_absolute(filename)


func is_open() -> bool:
    return db != null


func create_database_structure() -> bool:
    assert(is_open())

    var sql := FileAccess.get_file_as_string("res://database.sql")

    if sql.is_empty():
        show_error("Unable to create database.", "File open error: %d" % FileAccess.get_open_error())
        return false

    if !db.query(sql):
        show_error("Unable to create database.", db.error_message)
        return false

    return true


func show_error(text: String, message: String) -> void:
    Events.error.emit(text, message)


func query(sql: String, bindings: Array = []) -> QueryResult:
    assert(is_open())

    var res := QueryResult.new()

    if !db.query_with_bindings(sql, bindings):
        show_error("Database query error.", db.error_message)
        res.ok = false
        return res

    res.ok = true
    res.rows = db.query_result
    return res
