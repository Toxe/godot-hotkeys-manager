class_name TestUtils


static func assert_and_ignore_expected_error(test: GutTest, expected_error: String) -> void:
    var errors: Array = test.get_errors()
    test.assert_gt(errors.size(), 0)

    for err: GutTrackedError in errors:
        var err_msg: String = err.code
        if err_msg.contains(expected_error):
            err.handled = true
            return

    test.fail_test("expected error \"%s\"" % expected_error)
