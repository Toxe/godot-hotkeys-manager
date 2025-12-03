extends GutTest

const program_list_scene: PackedScene = preload("uid://bb0sf1lk22oy1")

var _program_list: ProgramList = null


func before_each() -> void:
    var db: Database = Database.new()
    db.open(":memory:")

    _program_list = autofree(program_list_scene.instantiate())
    _program_list.setup(db)


func test_lists_programs() -> void:
    assert_gt(_program_list.get_list().item_count, 0)


func test_no_item_is_selected_by_default() -> void:
    assert_true(_program_list.get_list().get_selected_items().is_empty())


func test_the_edit_and_delete_buttons_are_disabled_by_default() -> void:
    var edit_button: Button = _program_list.find_child("EditButton", true, false)
    var delete_button: Button = _program_list.find_child("DeleteButton", true, false)
    assert_true(edit_button.disabled)
    assert_true(delete_button.disabled)


func test_selecting_a_program_enables_the_edit_and_delete_buttons() -> void:
    _program_list._on_item_list_item_selected(0)
    var edit_button: Button = _program_list.find_child("EditButton", true, false)
    var delete_button: Button = _program_list.find_child("DeleteButton", true, false)
    assert_false(edit_button.disabled)
    assert_false(delete_button.disabled)


func test_clicking_the_Add_button_opens_the_Add_Program_dialog() -> void:
    _program_list._on_add_button_pressed()
    var dialog: EnterTextDialog = _program_list.find_child("EnterTextDialog", false, false)
    assert_not_null(dialog)
    if dialog:
        assert_eq(dialog.title, "Add Program")


func test_clicking_the_Edit_button_opens_the_Edit_Program_dialog() -> void:
    _program_list.select_program_list_item(2)
    _program_list._on_edit_button_pressed()
    var dialog: EnterTextDialog = _program_list.find_child("EnterTextDialog", false, false)
    assert_not_null(dialog)
    if dialog:
        assert_eq(dialog.title, "Edit Program")
        assert_eq(dialog.get_text_field("name").text, "Visual Studio Code")
        assert_eq(dialog.get_text_field("abbreviation").text, "VSCode")


func test_clicking_the_Delete_button_opens_the_Delete_Program_dialog() -> void:
    _program_list.select_program_list_item(0)
    _program_list._on_delete_button_pressed()
    var dialog: VerificationDialog = _program_list.find_child("VerificationDialog", false, false)
    assert_not_null(dialog)
    if dialog:
        assert_eq(dialog.title, "Delete Program")


func test_can_add_a_program() -> void:
    var list := _program_list.get_list()
    var old_item_count := list.item_count
    _program_list._on_add_program_dialog_submitted(null, {"name": "New Program", "abbreviation": "newp"})
    assert_true(_program_list._db.rows_exist("program", "name=? AND abbreviation=?", ["New Program", "newp"]))
    assert_eq(list.item_count, old_item_count + 1)
    assert_eq(list.get_item_text(list.item_count - 1), "New Program (newp)")


func test_can_edit_a_program() -> void:
    var list := _program_list.get_list()
    var old_item_count := list.item_count
    var program_data: Dictionary = list.get_item_metadata(2)
    var program_id: int = program_data["program_id"]
    watch_signals(_program_list)
    _program_list._on_edit_program_dialog_submitted(null, {"name": "New Program", "abbreviation": "newp"}, 2, program_id)
    assert_true(_program_list._db.rows_exist("program", "program_id=? AND name=? AND abbreviation=?", [program_id, "New Program", "newp"]))
    assert_signal_emitted_with_parameters(_program_list.program_edited, [program_id])
    assert_eq(list.item_count, old_item_count)
    assert_eq(list.get_item_text(2), "New Program (newp)")


func test_can_delete_a_program() -> void:
    var list := _program_list.get_list()
    var old_item_count := list.item_count
    var old_item_name := list.get_item_text(2)
    var program_data: Dictionary = list.get_item_metadata(2)
    var program_id: int = program_data["program_id"]
    watch_signals(_program_list)
    _program_list._on_delete_program_dialog_confirmed(null, 2, program_id)
    assert_false(_program_list._db.rows_exist("program", "program_id=?", [program_id]))
    assert_signal_emitted_with_parameters(_program_list.program_deleted, [program_id])
    assert_eq(list.item_count, old_item_count - 1)
    assert_true(list.get_item_text(2) != old_item_name)
