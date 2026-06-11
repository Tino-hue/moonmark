///|
test "Diagnostic::critical creates correct level" {
  let d = @report.Diagnostic::critical("CYCLE-001", "Cycle found", [
    "A", "B", "C",
  ])
  assert_true(d.level == "Critical")
  assert_true(d.code == "CYCLE-001")
  assert_true(d.message == "Cycle found")
  assert_true(d.path.length() == 3)
  assert_true(d.suggestions.length() == 0)
}

///|
test "Diagnostic::with_suggestion appends suggestion" {
  let d = @report.Diagnostic::warning("WARN-001", "Old version", ["A"]).with_suggestion(
    "Upgrade to 2.0.0",
  )
  assert_true(d.level == "Warning")
  assert_true(d.suggestions.length() == 1)
  assert_true(d.suggestions[0] == "Upgrade to 2.0.0")
}

///|
test "Diagnostic::to_string exact format" {
  let d = @report.Diagnostic::info("INFO-001", "No issues", []).with_suggestion(
    "Keep it up",
  )
  let s = d.to_string()
  assert_true(s == "Info [INFO-001] No issues | suggestion: Keep it up")
}

///|
test "Diagnostic::to_json_string exact format" {
  let d = @report.Diagnostic::critical("CYCLE-001", "Cycle", ["A", "B"])
  let s = d.to_json_string()
  assert_true(
    s ==
    "{\"level\":\"Critical\",\"code\":\"CYCLE-001\",\"message\":\"Cycle\",\"path\":[\"A\",\"B\"],\"suggestions\":[]}",
  )
}

///|
test "Diagnostic::warning creates correct level" {
  let d = @report.Diagnostic::warning("WARN-001", "Old version", ["A"])
  assert_true(d.level == "Warning")
  assert_true(d.is_warning())
  assert_true(d.is_critical() == false)
  assert_true(d.is_info() == false)
}

///|
test "Diagnostic::info creates correct level" {
  let d = @report.Diagnostic::info("INFO-001", "No issues", [])
  assert_true(d.level == "Info")
  assert_true(d.is_info())
  assert_true(d.is_critical() == false)
  assert_true(d.is_warning() == false)
}

///|
test "Diagnostic empty path and suggestions" {
  let d = @report.Diagnostic::critical("CYCLE-001", "Cycle", [])
    .with_suggestion("Break the edge")
    .with_suggestion("Remove the package")
  assert_true(d.path.length() == 0)
  assert_true(d.suggestions.length() == 2)
}
