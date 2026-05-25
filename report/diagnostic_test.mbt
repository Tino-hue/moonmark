test "Diagnostic::critical creates correct level" {
  let d = @report.Diagnostic::critical("CYCLE-001", "Cycle found", ["A", "B", "C"])
  inspect!(d.level, content="Critical")
  inspect!(d.code, content="CYCLE-001")
  inspect!(d.message, content="Cycle found")
  inspect!(d.path.length(), content="3")
  inspect!(d.suggestions.length(), content="0")
}

test "Diagnostic::with_suggestion appends suggestion" {
  let d = @report.Diagnostic::warning("WARN-001", "Old version", ["A"])
    .with_suggestion("Upgrade to 2.0.0")
  inspect!(d.level, content="Warning")
  inspect!(d.suggestions.length(), content="1")
  inspect!(d.suggestions[0], content="Upgrade to 2.0.0")
}

test "Diagnostic::to_string exact format" {
  let d = @report.Diagnostic::info("INFO-001", "No issues", [])
    .with_suggestion("Keep it up")
  let s = d.to_string()
  inspect!(s, content="Info [INFO-001] No issues | suggestion: Keep it up")
}

test "Diagnostic::to_json_string exact format" {
  let d = @report.Diagnostic::critical("CYCLE-001", "Cycle", ["A", "B"])
  let s = d.to_json_string()
  inspect!(s, content="{\"level\":\"Critical\",\"code\":\"CYCLE-001\",\"message\":\"Cycle\",\"path\":[\"A\",\"B\"],\"suggestions\":[]}")
}
