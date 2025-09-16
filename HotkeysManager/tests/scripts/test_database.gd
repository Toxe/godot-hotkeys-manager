extends GutTest

var db: Database = null


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
    assert_true(db.update_rows("program_command", "name='Go to File'", {"name": "test"}))


func test_delete_rows() -> void:
    assert_true(db.delete_rows("program_command", "name='Go to File'"))


func test_select_rows() -> void:
    var rows: Variant = db.select_rows("program_command", "name='Go to File'", ["program_id", "command_id", "name"])
    assert_eq_deep(rows, [
        {"program_id": 1, "command_id": 1, "name": "Go to File"},
        {"program_id": 3, "command_id": 1, "name": "Go to File"},
    ])


func test_select_rows_returns_false_on_database_error() -> void:
    assert_false(db.select_rows("missing_table", "id=99", ["col1", "col2"]))
    TestUtils.assert_and_ignore_expected_error(self, "no such table: missing_table")


func test_select_row() -> void:
    var row: Variant = db.select_row("user_hotkey", "hotkey='Ctrl+P'", ["command_id", "hotkey"])
    assert_eq_deep(row, {"command_id": 1, "hotkey": "Ctrl+P"})


func test_select_row_returns_false_on_database_error() -> void:
    assert_false(db.select_row("missing_table", "id=99", ["col1", "col2"]))
    TestUtils.assert_and_ignore_expected_error(self, "no such table: missing_table")


func test_select_row_returns_false_if_there_is_more_than_one_result_row() -> void:
    assert_false(db.select_row("program_command", "program_id=1", ["name"]))


func test_select_row_returns_null_if_the_row_doesnt_exist() -> void:
    assert_null(db.select_row("program_command", "program_id=99", ["program_id", "name"]))


func test_select_value() -> void:
    var value: Variant = db.select_value("user_hotkey", "command_id=2", "hotkey")
    assert_eq(value, "Ctrl+PageDown")


func test_select_value_returns_false_on_database_error() -> void:
    assert_false(db.select_value("missing_table", "id=99", "col"))
    TestUtils.assert_and_ignore_expected_error(self, "no such table: missing_table")


func test_select_value_returns_false_if_there_is_more_than_one_result_row() -> void:
    assert_false(db.select_value("program_command", "program_id=1", "name"))


func test_select_value_returns_null_if_the_row_doesnt_exist() -> void:
    assert_null(db.select_value("program_command", "program_id=99", "name"))


func test_select_without_bindings() -> void:
    var rows: Variant = db.select("SELECT program_id, command_id, name FROM program_command WHERE name='Go to File';")
    assert_eq_deep(rows, [
        {"program_id": 1, "command_id": 1, "name": "Go to File"},
        {"program_id": 3, "command_id": 1, "name": "Go to File"},
    ])


func test_select_with_bindings() -> void:
    var rows: Variant = db.select("SELECT program_id, command_id, name FROM program_command WHERE name=?;", ["Go to File"])
    assert_eq_deep(rows, [
        {"program_id": 1, "command_id": 1, "name": "Go to File"},
        {"program_id": 3, "command_id": 1, "name": "Go to File"},
    ])


func test_query() -> void:
    var sql := "CREATE TABLE `foo` (`id` integer PRIMARY KEY NOT NULL, `name` varchar(255)); INSERT INTO `foo` (`name`) VALUES ('first'), ('second');"
    assert_true(db.query(sql))
