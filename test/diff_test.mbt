///|
test "diff_reports detects added diagnostic" {
  let baseline = @analyze.AnalysisReport::new(
    diagnostics=[],
    overall_score=100,
    node_count=1,
  )
  let current = @analyze.AnalysisReport::new(
    diagnostics=[
      @report.Diagnostic::info("LICENSE-002", "No license", ["pkg@1.0.0"]),
    ],
    overall_score=96,
    node_count=1,
  )
  let diff = @analyze.diff_reports(current, baseline)
  assert_true(diff.added.length() == 1)
  assert_true(diff.removed.length() == 0)
  assert_true(diff.unchanged.length() == 0)
  assert_true(diff.score_delta == -4)
}

///|
test "diff_reports detects removed diagnostic" {
  let baseline = @analyze.AnalysisReport::new(
    diagnostics=[
      @report.Diagnostic::info("LICENSE-002", "No license", ["pkg@1.0.0"]),
    ],
    overall_score=96,
    node_count=1,
  )
  let current = @analyze.AnalysisReport::new(
    diagnostics=[],
    overall_score=100,
    node_count=1,
  )
  let diff = @analyze.diff_reports(current, baseline)
  assert_true(diff.added.length() == 0)
  assert_true(diff.removed.length() == 1)
  assert_true(diff.unchanged.length() == 0)
  assert_true(diff.score_delta == 4)
}

///|
test "diff_reports detects unchanged diagnostic" {
  let diag = @report.Diagnostic::info("LICENSE-002", "No license", ["pkg@1.0.0"])
  let baseline = @analyze.AnalysisReport::new(
    diagnostics=[diag],
    overall_score=96,
    node_count=1,
  )
  let current = @analyze.AnalysisReport::new(
    diagnostics=[diag],
    overall_score=96,
    node_count=1,
  )
  let diff = @analyze.diff_reports(current, baseline)
  assert_true(diff.added.length() == 0)
  assert_true(diff.removed.length() == 0)
  assert_true(diff.unchanged.length() == 1)
  assert_true(diff.score_delta == 0)
}

///|
test "parse_audit_json roundtrip" {
  let report = @analyze.AnalysisReport::new(
    diagnostics=[
      @report.Diagnostic::warning("DEP-001", "Outdated", ["a@1.0.0"]).with_suggestion(
        "Upgrade to 2.0.0",
      ),
    ],
    overall_score=85,
    node_count=2,
  )
  let json = @analyze.render_audit_json(report)
  let parsed = @analyze.parse_audit_json(json)
  assert_true(parsed is Ok(_))
  let r = match parsed {
    Ok(v) => v
    Err(_) => @analyze.AnalysisReport::new()
  }
  assert_true(r.get_overall_score() == 85)
  assert_true(r.get_node_count() == 2)
  assert_true(r.get_diagnostics().length() == 1)
  assert_true(r.get_diagnostics()[0].code == "DEP-001")
  assert_true(r.get_diagnostics()[0].suggestions.length() == 1)
  assert_true(r.get_diagnostics()[0].suggestions[0] == "Upgrade to 2.0.0")
}

///|
test "render_diff_terminal contains sections" {
  let diff = @analyze.ReportDiff::new(
    added=[@report.Diagnostic::critical("CYCLE-001", "Cycle", ["A"])],
    removed=[@report.Diagnostic::info("LICENSE-002", "No license", ["B"])],
    score_delta=-10,
  )
  let text = @analyze.render_diff_terminal(diff)
  assert_true(text.contains("Added"))
  assert_true(text.contains("Fixed"))
  assert_true(text.contains("CYCLE-001"))
  assert_true(text.contains("LICENSE-002"))
  assert_true(text.contains("-10"))
}
