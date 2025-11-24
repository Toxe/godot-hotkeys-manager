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
    assert_true(db.update_rows("command", "name='Go to File'", {"name": "test"}))


func test_delete_rows() -> void:
    assert_true(db.delete_rows("command", "name='Go to File'"))
    assert_true(db.delete_rows("command", "*"))


func test_select_rows() -> void:
    var rows: Variant = db.select_rows("program_command_hotkey", "hotkey='Ctrl+W'", ["program_id", "command_id", "hotkey"])
    @warning_ignore("unsafe_call_argument")
    assert_eq_deep(rows, [
        {"program_id": 9, "command_id": 5, "hotkey": "Ctrl+W"},
        {"program_id": 10, "command_id": 5, "hotkey": "Ctrl+W"},
    ])


func test_select_rows_returns_false_on_database_error() -> void:
    @warning_ignore("unsafe_call_argument")
    assert_false(db.select_rows("missing_table", "id=99", ["col1", "col2"]))
    assert_engine_error("no such table: missing_table")


func test_select_row() -> void:
    var row: Variant = db.select_row("user_hotkey", "hotkey='Ctrl+P'", ["command_id", "hotkey"])
    @warning_ignore("unsafe_call_argument")
    assert_eq_deep(row, {"command_id": 1, "hotkey": "Ctrl+P"})


func test_select_row_returns_false_on_database_error() -> void:
    @warning_ignore("unsafe_call_argument")
    assert_false(db.select_row("missing_table", "id=99", ["col1", "col2"]))
    assert_engine_error("no such table: missing_table")


func test_select_row_returns_false_if_there_is_more_than_one_result_row() -> void:
    @warning_ignore("unsafe_call_argument")
    assert_false(db.select_row("program_command_hotkey", "program_id=1", ["hotkey"]))


func test_select_row_returns_null_if_the_row_doesnt_exist() -> void:
    @warning_ignore("unsafe_call_argument")
    assert_null(db.select_row("program_command_hotkey", "program_id=99", ["program_id", "hotkey"]))


func test_select_value() -> void:
    var value: Variant = db.select_value("user_hotkey", "command_id=2", "hotkey")
    @warning_ignore("unsafe_call_argument")
    assert_eq(value, "Ctrl+PageDown")


func test_select_value_returns_false_on_database_error() -> void:
    @warning_ignore("unsafe_call_argument")
    assert_false(db.select_value("missing_table", "id=99", "col"))
    assert_engine_error("no such table: missing_table")


func test_select_value_returns_false_if_there_is_more_than_one_result_row() -> void:
    @warning_ignore("unsafe_call_argument")
    assert_false(db.select_value("program_command_hotkey", "program_id=1", "hotkey"))


func test_select_value_returns_null_if_the_row_doesnt_exist() -> void:
    @warning_ignore("unsafe_call_argument")
    assert_null(db.select_value("program_command_hotkey", "program_id=99", "hotkey"))


func test_select_without_bindings() -> void:
    var rows: Variant = db.select("SELECT program_id, command_id, hotkey FROM program_command_hotkey WHERE hotkey='Ctrl+W';")
    @warning_ignore("unsafe_call_argument")
    assert_eq_deep(rows, [
        {"program_id": 9, "command_id": 5, "hotkey": "Ctrl+W"},
        {"program_id": 10, "command_id": 5, "hotkey": "Ctrl+W"},
    ])


func test_select_with_bindings() -> void:
    var rows: Variant = db.select("SELECT program_id, command_id, hotkey FROM program_command_hotkey WHERE hotkey=?;", ["Ctrl+W"])
    @warning_ignore("unsafe_call_argument")
    assert_eq_deep(rows, [
        {"program_id": 9, "command_id": 5, "hotkey": "Ctrl+W"},
        {"program_id": 10, "command_id": 5, "hotkey": "Ctrl+W"},
    ])


func test_rows_exist_returns_true_if_a_condition_returns_one_row() -> void:
    assert_true(db.rows_exist("program", "program_id=6"))


func test_rows_exist_returns_true_if_a_condition_returns_multiple_rows() -> void:
    assert_true(db.rows_exist("program_command_hotkey", "command_id=2"))


func test_rows_exist_returns_false_if_a_condition_returns_no_rows() -> void:
    assert_false(db.rows_exist("program", "program_id=99"))


func test_count_rows_returns_the_number_of_rows() -> void:
    assert_eq(db.count_rows("command"), 7)
    assert_eq(db.count_rows("program"), 10)
    assert_eq(db.count_rows("program_command_hotkey", "program_id=3"), 4)
    assert_eq(db.count_rows("program_command_hotkey", "program_id=3 AND command_id=1"), 3)
    assert_eq(db.count_rows("program_command_hotkey", "program_id=101 AND command_id=102"), 0)


func test_count_rows_returns_zero_if_a_table_is_empty() -> void:
    db.delete_rows("properties", "*")
    db.delete_rows("command_comment", "*")
    assert_eq(db.count_rows("properties"), 0)
    assert_eq(db.count_rows("command_comment"), 0)
    assert_eq(db.count_rows("command_comment", "command_id=1"), 0)


func test_query() -> void:
    var sql := "CREATE TABLE `foo` (`id` integer PRIMARY KEY NOT NULL, `name` varchar(255)); INSERT INTO `foo` (`name`) VALUES ('first'), ('second');"
    assert_true(db.query(sql))
