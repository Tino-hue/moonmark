test "Diagnostic::critical creates correct level" {
  let d = @report.Diagnostic::critical("CYCLE-001", "Cycle found", ["A", "B", "C"])
  assert_eq(d.level, @report.LEVEL_CRITICAL)
  assert_eq(d.code, "CYCLE-001")
  assert_eq(d.message, "Cycle found")
  assert_eq(d.path.length(), 3)
  assert_eq(d.suggestions.length(), 0)
}

test "Diagnostic::with_suggestion appends suggestion" {
  let d = @report.Diagnostic::warning("WARN-001", "Old version", ["A"])
    .with_suggestion("Upgrade to 2.0.0")
  assert_eq(d.level, @report.LEVEL_WARNING)
  assert_eq(d.suggestions.length(), 1)
  assert_eq(d.suggestions[0], "Upgrade to 2.0.0")
}

test "Diagnostic::to_string exact format" {
  let d = @report.Diagnostic::info("INFO-001", "No issues", [])
    .with_suggestion("Keep it up")
  let s = d.to_string()
  assert_eq(s, "Info [INFO-001] No issues | suggestion: Keep it up")
}

test "Diagnostic::to_json_string exact format" {
  let d = @report.Diagnostic::critical("CYCLE-001", "Cycle", ["A", "B"])
  let s = d.to_json_string()
  assert_eq(s, "{\"level\":\"Critical\",\"code\":\"CYCLE-001\",\"message\":\"Cycle\",\"path\":[\"A\",\"B\"],\"suggestions\":[]}")
}
