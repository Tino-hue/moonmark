test "render_audit_report with no diagnostics" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)

  let metas : Map[String, NodeMeta] = {
    "root@1.0.0": NodeMeta::new(license=Some("MIT")),
  }
  let report = run_analysis(graph, metas)
  let text = render_audit_report(report)

  assert_true(text.contains("Audit"))
  assert_true(text.contains("No issues found"))
  assert_true(text.contains("0 critical"))
  assert_true(text.contains("Health Score"))
}

test "render_audit_report groups by level" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_node("C", "1.0.0", 2)
  graph.add_edge("A", "1.0.0", "B", "1.0.0")
  graph.add_edge("B", "1.0.0", "C", "1.0.0")
  graph.add_edge("C", "1.0.0", "A", "1.0.0")

  let metas : Map[String, NodeMeta] = {
    "A@1.0.0": NodeMeta::new(license=Some("GPL-3.0")),
    "B@1.0.0": NodeMeta::new(license=None),
  }
  let report = run_analysis(graph, metas)
  let text = render_audit_report(report)

  assert_true(text.contains("Critical"))
  assert_true(text.contains("Warning"))
  assert_true(text.contains("CYCLE-001"))
  assert_true(text.contains("LICENSE-001"))
  assert_true(text.contains("Summary"))
}

test "render_audit_report shows suggestions" {
  let diag = @report.Diagnostic::warning("DEP-001", "Outdated dependency", ["pkg@1.0.0"]).with_suggestion("Upgrade to pkg@2.0.0")
  let report = AnalysisReport::new(diagnostics=[diag], health_scores=[HealthScore::new("pkg@1.0.0", 70, freshness=60)], overall_score=70, node_count=1)

  let text = render_audit_report(report)
  assert_true(text.contains("DEP-001"))
  assert_true(text.contains("Outdated dependency"))
  assert_true(text.contains("Upgrade to pkg@2.0.0"))
  assert_true(text.contains("1 warnings"))
}

test "render_audit_report shows path info" {
  let diag = @report.Diagnostic::critical("CYCLE-001", "Circular dependency detected", ["A@1.0.0", "B@1.0.0", "A@1.0.0"])
  let report = AnalysisReport::new(diagnostics=[diag], overall_score=0, node_count=2)

  let text = render_audit_report(report)
  assert_true(text.contains("A@1.0.0 -> B@1.0.0 -> A@1.0.0"))
}

test "render_audit_json is valid structure" {
  let diag = @report.Diagnostic::warning("DEP-001", "Outdated", ["pkg@1.0.0"])
  let report = AnalysisReport::new(diagnostics=[diag], health_scores=[HealthScore::new("pkg@1.0.0", 80)], overall_score=80, node_count=1)

  let json = render_audit_json(report)
  assert_true(json.contains("\"overall_score\":80"))
  assert_true(json.contains("\"node_count\":1"))
  assert_true(json.contains("\"diagnostics\":["))
  assert_true(json.contains("\"health_scores\":["))
  assert_true(json.contains("\"summary\":{"))
  assert_true(json.contains("\"warning\":1"))
  assert_true(json.contains("\"DEP-001\""))
}

test "render_audit_json with empty report" {
  let report = AnalysisReport::new()

  let json = render_audit_json(report)
  assert_true(json.contains("\"overall_score\":100"))
  assert_true(json.contains("\"diagnostics\":[]"))
  assert_true(json.contains("\"health_scores\":[]"))
  assert_true(json.contains("\"critical\":0"))
  assert_true(json.contains("\"warning\":0"))
  assert_true(json.contains("\"info\":0"))
}
