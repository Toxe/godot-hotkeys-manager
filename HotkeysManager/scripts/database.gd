class_name Database

var db: SQLite = null


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


func query_result() -> Array[Dictionary]:
    return db.query_result


func last_insert_rowid() -> int:
    return db.last_insert_rowid


func query(sql: String, bindings: Array = []) -> bool:
    assert(is_open())

    if !db.query_with_bindings(sql, bindings):
        show_error("Database query error.", db.error_message)
        return false
    return true


## Returns [code]false[/code] on a database error or an Array of rows (which can be empty).
func select_rows(table: String, conditions: String, fields: Array) -> Variant:
    assert(is_open())

    var rows := db.select_rows(table, conditions, fields)
    if db.error_message != "not an error":
        show_error("Database query error.", db.error_message)
        return false
    return rows


## Returns [code]false[/code] on a database error or a Dictionary with row values or [code]null[/code] (if the row doesn't exist).
func select_row(table: String, conditions: String, fields: Array) -> Variant:
    var result: Variant = select_rows(table, conditions, fields)
    if !result:
        return false

    var rows: Array = result
    if rows.is_empty():
        return null
    elif rows.size() > 1:
        show_error("select_row", "returned more than one row")
        return false
    else:
        return rows[0]


## Returns [code]false[/code] on a database error or the value or [code]null[/code] (if the row doesn't exist).
func select_value(table: String, conditions: String, field: String) -> Variant:
    var result: Variant = select_row(table, conditions, [field])
    if !result:
        return result # can be false or null
    var values: Dictionary = result
    return values[field]


func insert_rows(table: String, rows: Array[Dictionary]) -> bool:
    assert(is_open())

    if !db.insert_rows(table, rows):
        show_error("Database query error.", db.error_message)
        return false
    return true


func insert_row(table: String, values: Dictionary) -> bool:
    assert(is_open())

    if !db.insert_row(table, values):
        show_error("Database query error.", db.error_message)
        return false
    return true


func update_rows(table: String, conditions: String, values: Dictionary) -> bool:
    assert(is_open())

    if !db.update_rows(table, conditions, values):
        show_error("Database query error.", db.error_message)
        return false
    return true


func delete_rows(table: String, conditions: String) -> bool:
    assert(is_open())

    if !db.delete_rows(table, conditions):
        show_error("Database query error.", db.error_message)
        return false
    return true
