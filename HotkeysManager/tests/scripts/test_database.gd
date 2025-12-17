extends GutTest

@warning_ignore_start("unsafe_call_argument")

var db: Database = null


func before_all() -> void:
    Events.database_query_failed.connect(func _on_database_query_failed(_query_type: StringName, _dur: float, error_message: String) -> void: printerr(error_message))


func before_each() -> void:
    db = autofree(Database.new())
    db.open(":memory:")


func test_insert_rows() -> void:
    assert_true(db.insert_rows("program", [ {"name": "test1"}, {"name": "test2"}]))
    assert_eq(db.last_insert_rowid(), 12)


func test_insert_row() -> void:
    assert_true(db.insert_row("program", {"name": "test"}))
    assert_eq(db.last_insert_rowid(), 11)


func test_update_rows() -> void:
    assert_true(db.update_rows("command", "name=?", ["Go to File"], {"name": "new name"}))
    assert_eq(db.count_rows("command", "name='new name'"), 1)

    assert_true(db.update_rows("program", "program_id=?", [7], {"name": "new name", "abbreviation": "new abbr"}))
    assert_eq(db.count_rows("program", "name='new name'"), 1)
    assert_eq(db.count_rows("program", "abbreviation='new abbr'"), 1)

    assert_true(db.update_rows("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [3, 2, "Ctrl+PageDown"], {"hotkey": "Ctrl+Shift+Alt+PageDown"}))
    assert_eq(db.count_rows("program_command_hotkey", "hotkey='Ctrl+Shift+Alt+PageDown'"), 1)


func test_update_rows_sql_injection() -> void:
    assert_true(db.update_rows("command", "name=?", ["' OR 1=1 --"], {"name": "injected"}))
    assert_false(db.rows_exist("command", "name=?", ["injected"]))

    assert_true(db.update_rows("program", "program_id=?", ["7 OR 1=1 --"], {"name": "injected name", "abbreviation": "injected abbr"}))
    assert_false(db.rows_exist("program", "name=?", ["injected name"]))
    assert_false(db.rows_exist("program", "abbreviation=?", ["injected abbr"]))

    assert_true(db.update_rows("program_command_hotkey", "program_id=? AND command_id=? AND hotkey=?", [3, 2, "' OR 1=1 --"], {"hotkey": "injected"}))
    assert_false(db.rows_exist("program_command_hotkey", "hotkey=?", ["injected"]))


func test_delete_rows() -> void:
    assert_true(db.delete_rows("program_command_hotkey", "hotkey=?", ["Ctrl+W"]))
    assert_false(db.rows_exist("program_command_hotkey", "hotkey=?", ["Ctrl+W"]))

    assert_true(db.delete_rows("program_command_hotkey", "program_id=? AND command_id=?", [3, 1]))
    assert_false(db.rows_exist("program_command_hotkey", "program_id=? AND command_id=?", [3, 1]))


func test_delete_rows_sql_injection() -> void:
    var expected_row_count := db.count_rows("program_command_hotkey")

    assert_true(db.delete_rows("program_command_hotkey", "hotkey=?", ["' OR 1=1 --"]))
    assert_eq(db.count_rows("program_command_hotkey"), expected_row_count)

    assert_true(db.delete_rows("program_command_hotkey", "program_id=? AND command_id=?", ["3 OR 1=1 --", 1]))
    assert_eq(db.count_rows("program_command_hotkey"), expected_row_count)


func test_delete_all_rows() -> void:
    assert_true(db.delete_all_rows("user_hotkey"))
    assert_eq(db.count_rows("user_hotkey"), 0)


func test_select_rows() -> void:
    assert_eq_deep(db.select_rows("program_command_hotkey", ["program_id", "command_id", "hotkey"], "hotkey=?", ["Ctrl+W"]), [
        {"program_id": 9, "command_id": 5, "hotkey": "Ctrl+W"},
        {"program_id": 10, "command_id": 5, "hotkey": "Ctrl+W"},
    ])
    assert_eq_deep(db.select_rows("program_command_hotkey", ["program_id", "command_id", "hotkey"], "hotkey=? AND program_id=?", ["Ctrl+W", 9]), [
        {"program_id": 9, "command_id": 5, "hotkey": "Ctrl+W"},
    ])


func test_select_rows_and_return_all_fields() -> void:
    var rows1: Array = db.select_rows("program_command_hotkey", ["*"])
    assert_eq(rows1.size(), 17)
    var rows2: Array = db.select_rows("program_command_hotkey", ["*"], "command_id=?", [1])
    assert_eq(rows2.size(), 8)
    var rows3: Array = db.select_rows("program_command_hotkey", ["*"], "command_id=?", [99])
    assert_eq(rows3.size(), 0)


func test_select_rows_and_sort_rows() -> void:
    assert_eq_deep(db.select_rows("program", ["name"], "", [], "name"), [
        {"name": "Chrome"},
        {"name": "CLion"},
        {"name": "Firefox"},
        {"name": "Illustrator"},
        {"name": "Krita"},
        {"name": "Obsidian"},
        {"name": "Photoshop"},
        {"name": "Visual Studio"},
        {"name": "Visual Studio Code"},
        {"name": "Vivaldi"},
    ])
    assert_eq_deep(db.select_rows("program", ["program_id", "name"], "name LIKE '%r%'", [], "name ASC"), [
        {"program_id": 10, "name": "Chrome"},
        {"program_id": 8, "name": "Firefox"},
        {"program_id": 6, "name": "Illustrator"},
        {"program_id": 7, "name": "Krita"},
    ])
    assert_eq_deep(db.select_rows("program", ["program_id", "name"], "name LIKE '%r%'", [], "name DESC"), [
        {"program_id": 7, "name": "Krita"},
        {"program_id": 6, "name": "Illustrator"},
        {"program_id": 8, "name": "Firefox"},
        {"program_id": 10, "name": "Chrome"},
    ])
    assert_eq_deep(db.select_rows("program", ["program_id", "name"], "name LIKE '%r%'", [], "program_id ASC"), [
        {"program_id": 6, "name": "Illustrator"},
        {"program_id": 7, "name": "Krita"},
        {"program_id": 8, "name": "Firefox"},
        {"program_id": 10, "name": "Chrome"},
    ])
    assert_eq_deep(db.select_rows("program", ["program_id", "name"], "name LIKE '%r%'", [], "program_id DESC"), [
        {"program_id": 10, "name": "Chrome"},
        {"program_id": 8, "name": "Firefox"},
        {"program_id": 7, "name": "Krita"},
        {"program_id": 6, "name": "Illustrator"},
    ])
    assert_eq_deep(db.select_rows("program_command_hotkey", ["program_id", "command_id", "hotkey"], "program_id=?", [2], "command_id DESC, hotkey ASC"), [
        {"program_id": 2, "command_id": 2, "hotkey": "Ctrl+Alt+PageDown"},
        {"program_id": 2, "command_id": 1, "hotkey": "Ctrl+1 Ctrl+F"},
        {"program_id": 2, "command_id": 1, "hotkey": "Ctrl+1 F"},
        {"program_id": 2, "command_id": 1, "hotkey": "Ctrl+Shift+T"},
    ])


func test_select_rows_returns_false_on_database_error() -> void:
    assert_false(db.select_rows("missing_table", ["col1", "col2"], "id=?", [99]))
    assert_engine_error("no such table: missing_table")


func test_select_rows_sql_injection() -> void:
    var rows1: Array = db.select_rows("program_command_hotkey", ["program_id", "command_id", "hotkey"], "hotkey=?", ["' OR 1=1 --"])
    assert_eq(rows1.size(), 0)
    var rows2: Array = db.select_rows("program_command_hotkey", ["program_id", "command_id", "hotkey"], "hotkey=? AND program_id=?", ["' OR 1=1 --", 9])
    assert_eq(rows2.size(), 0)


func test_select_row() -> void:
    assert_eq_deep(db.select_row("user_hotkey", ["command_id", "hotkey"], "hotkey=?", ["Ctrl+P"]), {"command_id": 1, "hotkey": "Ctrl+P"})
    assert_eq_deep(db.select_row("user_hotkey", ["*"], "hotkey=?", ["Ctrl+P"]), {"user_hotkey_id": 1, "command_id": 1, "hotkey": "Ctrl+P"})


func test_select_row_returns_false_on_database_error() -> void:
    assert_false(db.select_row("missing_table", ["col1", "col2"], "id=?", [99]))
    assert_engine_error("no such table: missing_table")


func test_select_row_returns_false_if_there_is_more_than_one_result_row() -> void:
    assert_false(db.select_row("program_command_hotkey", ["hotkey"], "program_id=?", [1]))


func test_select_row_returns_null_if_the_row_doesnt_exist() -> void:
    assert_null(db.select_row("program_command_hotkey", ["program_id", "hotkey"], "program_id=?", [99]))


func test_select_row_sql_injection() -> void:
    db.select_row("user_hotkey", ["*"], "hotkey=?", ["' OR 1=1 --"])
    assert_eq(db.query_result().size(), 0)
    db.select_row("program_command_hotkey", ["*"], "hotkey=? AND program_id=?", ["' OR 1=1 --", 9])
    assert_eq(db.query_result().size(), 0)


func test_select_value() -> void:
    assert_eq(db.select_value("user_hotkey", "hotkey", "command_id=?", [2]), "Ctrl+PageDown")


func test_select_value_returns_false_on_database_error() -> void:
    assert_false(db.select_value("missing_table", "col", "id=?", [99]))
    assert_engine_error("no such table: missing_table")


func test_select_value_returns_false_if_there_is_more_than_one_result_row() -> void:
    assert_false(db.select_value("program_command_hotkey", "hotkey", "program_id=?", [1]))


func test_select_value_returns_null_if_the_row_doesnt_exist() -> void:
    assert_null(db.select_value("program_command_hotkey", "hotkey", "program_id=?", [99]))


func test_select_value_sql_injection() -> void:
    db.select_value("user_hotkey", "command_id", "hotkey=?", ["' OR 1=1 --"])
    assert_eq(db.query_result().size(), 0)
    db.select_value("program_command_hotkey", "program_id", "hotkey=? AND program_id=?", ["' OR 1=1 --", 9])
    assert_eq(db.query_result().size(), 0)


func test_select() -> void:
    assert_eq_deep(db.select("SELECT program_id, command_id, hotkey FROM program_command_hotkey WHERE hotkey=?;", ["Ctrl+W"]), [
        {"program_id": 9, "command_id": 5, "hotkey": "Ctrl+W"},
        {"program_id": 10, "command_id": 5, "hotkey": "Ctrl+W"},
    ])
    var rows: Array = db.select("SELECT * FROM program;")
    assert_eq(rows.size(), 10)


func test_select_sql_injection() -> void:
    var rows1: Array = db.select("SELECT * FROM program_command_hotkey WHERE hotkey=?;", ["' OR 1=1 --"])
    assert_eq(rows1.size(), 0)
    var rows2: Array = db.select("SELECT * FROM program_command_hotkey WHERE hotkey=? AND program_id=?;", ["' OR 1=1 --", 1])
    assert_eq(rows2.size(), 0)


func test_rows_exist_returns_true_if_a_condition_returns_one_row() -> void:
    assert_true(db.rows_exist("program", "program_id=?", [6]))


func test_rows_exist_returns_true_if_a_condition_returns_multiple_rows() -> void:
    assert_true(db.rows_exist("program_command_hotkey", "command_id=?", [2]))


func test_rows_exist_returns_false_if_a_condition_returns_no_rows() -> void:
    assert_false(db.rows_exist("program", "program_id=?", [99]))


func test_rows_exist_sql_injection() -> void:
    assert_false(db.rows_exist("program_command_hotkey", "hotkey=?", ["' OR 1=1) --"]))
    assert_false(db.rows_exist("program_command_hotkey", "hotkey=? AND command_id=?", ["' OR 1=1) --", 3]))


func test_count_rows_returns_the_number_of_rows() -> void:
    assert_eq(db.count_rows("command"), 7)
    assert_eq(db.count_rows("program"), 10)
    assert_eq(db.count_rows("program_command_hotkey", "program_id=?", [3]), 4)
    assert_eq(db.count_rows("program_command_hotkey", "program_id=? AND command_id=?", [3, 1]), 3)
    assert_eq(db.count_rows("program_command_hotkey", "program_id=? AND command_id=?", [101, 102]), 0)


func test_count_rows_returns_zero_if_a_table_is_empty() -> void:
    db.delete_all_rows("properties")
    db.delete_all_rows("command_comment")
    assert_eq(db.count_rows("properties"), 0)
    assert_eq(db.count_rows("command_comment"), 0)
    assert_eq(db.count_rows("command_comment", "command_id=?", [1]), 0)


func test_count_rows_sql_injection() -> void:
    assert_eq(db.count_rows("program_command_hotkey", "program_id=?", ["3 OR 1=1 --"]), 0)
    assert_eq(db.count_rows("program_command_hotkey", "program_id=? AND command_id=?", ["3 OR 1=1 --", "1"]), 0)


func test_query() -> void:
    assert_true(db.query(
        "CREATE TABLE foo (id integer PRIMARY KEY NOT NULL, name varchar(255));
        INSERT INTO foo (name) VALUES (?), (?);", ["first", "second"]))
    assert_true(db.query("SELECT * FROM foo;"))
    assert_eq(db.query_result().size(), 2)


func test_query_sql_injection() -> void:
    assert_true(db.query("DELETE FROM program_command_hotkey WHERE hotkey=?", ["' OR 1=1 --"]))
    assert_gt(db.count_rows("program_command_hotkey"), 0)

    assert_true(db.query("UPDATE program SET name=? WHERE name=?", ["new name", "' OR 1=1 --"]))
    assert_eq(db.count_rows("program", "name=?", ["new name"]), 0)


@warning_ignore_restore("unsafe_call_argument")
