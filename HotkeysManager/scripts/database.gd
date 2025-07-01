class_name Database

var _db: SQLite = null


func open(db_name: String) -> bool:
    var db_needs_to_be_created := !FileAccess.file_exists(db_name)
    _db = SQLite.new()
    _db.path = db_name
    _db.foreign_keys = true
    _db.verbosity_level = SQLite.VerbosityLevel.NORMAL

    if !_db.open_db():
        Events.error.emit("Unable to open database \"%s\"." % db_name)
        close()
        return false

    if db_needs_to_be_created:
        if !create_database_structure():
            close_and_delete_database()
            return false

    return true


func close() -> void:
    assert(is_open())

    _db.close_db()
    _db = null


func close_and_delete_database() -> void:
    assert(is_open())

    var filename := _db.path
    close()

    if FileAccess.file_exists(filename):
        DirAccess.remove_absolute(filename)


func is_open() -> bool:
    return _db != null


func create_database_structure() -> bool:
    assert(is_open())

    for file: String in ["res://db/schema.sql", "res://db/example.sql"]:
        var sql := FileAccess.get_file_as_string(file)
        if sql.is_empty():
            Events.error.emit("Unable to create database. File system error: %d" % FileAccess.get_open_error())
            return false
        if !query(sql):
            Events.error.emit("Unable to create database.")
            return false

    return true


func query_result() -> Array[Dictionary]:
    return _db.query_result


func last_insert_rowid() -> int:
    return _db.last_insert_rowid


func exec_call(query_type: StringName, fn_query: Callable) -> bool:
    assert(is_open())

    var t0 := Time.get_ticks_usec()
    fn_query.call()
    var dur := Time.get_ticks_usec() - t0
    var success := _db.error_message == "not an error"
    var num_rows := query_result().size() if query_type == &"SELECT" else 0

    if success:
        Events.database_query_succeeded.emit(query_type, dur, num_rows)
    else:
        Events.database_query_failed.emit(query_type, dur, _db.error_message)

    return success


func insert_rows(table: String, rows: Array[Dictionary]) -> bool:
    return exec_call(&"INSERT", func() -> void: _db.insert_rows(table, rows))


func insert_row(table: String, values: Dictionary) -> bool:
    return exec_call(&"INSERT", func() -> void: _db.insert_row(table, values))


func update_rows(table: String, conditions: String, values: Dictionary) -> bool:
    return exec_call(&"UPDATE", func() -> void: _db.update_rows(table, conditions, values))


func delete_rows(table: String, conditions: String) -> bool:
    return exec_call(&"DELETE", func() -> void: _db.delete_rows(table, conditions))


## Returns [code]false[/code] on a database error or an Array of rows (which can be empty).
func select_rows(table: String, conditions: String, fields: Array) -> Variant:
    if exec_call(&"SELECT", func() -> void: _db.select_rows(table, conditions, fields)):
        return query_result()
    else:
        return false


## Returns [code]false[/code] on a database error or a Dictionary with row values or [code]null[/code] (if the row doesn't exist).
func select_row(table: String, conditions: String, fields: Array) -> Variant:
    var result: Variant = select_rows(table, conditions, fields)
    if !result:
        return false
    var rows: Array = result
    if rows.is_empty():
        return null
    elif rows.size() > 1:
        Events.error.emit("Database error: select_row() returned more than one row.")
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


## For complex SELECT queries that fit no other function. Returns [code]false[/code] on a database error or an Array of rows (which can be empty).
func select(sql: String, bindings: Array = []) -> Variant:
    if exec_call(&"SELECT", func() -> void: _db.query_with_bindings(sql, bindings)):
        return query_result()
    else:
        return false


## A general query function, when there is no better fit.
func query(sql: String, bindings: Array = []) -> bool:
    return exec_call(&"QUERY", func() -> void: _db.query_with_bindings(sql, bindings))
