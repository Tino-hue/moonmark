test "render_sarif_report basic structure" {
  let report = @analyze.AnalysisReport::new(
    diagnostics=[@report.Diagnostic::warning("LICENSE-001", "High-risk license", ["pkg@1.0.0"]).with_suggestion("Replace with MIT")],
    overall_score=85,
    node_count=2,
  )
  let graph = @graph.DependencyGraph::new()
  graph.add_node("pkg", "1.0.0", 0)
  let sarif = @analyze.render_sarif_report(report, graph, "pkg@1.0.0")
  assert_true(sarif.contains("\"version\":\"2.1.0\""))
  assert_true(sarif.contains("MoonBit Depsight"))
  assert_true(sarif.contains("LICENSE-001"))
  assert_true(sarif.contains("\"level\":\"warning\""))
  assert_true(sarif.contains("\"overall_score\":85"))
}

test "render_sarif_report critical is error" {
  let report = @analyze.AnalysisReport::new(
    diagnostics=[@report.Diagnostic::critical("CYCLE-001", "Cycle detected", ["A@1.0.0", "B@1.0.0"])],
    overall_score=50,
    node_count=2,
  )
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  let sarif = @analyze.render_sarif_report(report, graph, "A@1.0.0")
  assert_true(sarif.contains("\"level\":\"error\""))
  assert_true(sarif.contains("CYCLE-001"))
}

test "render_sarif_report empty diagnostics" {
  let report = @analyze.AnalysisReport::new(
    diagnostics=[],
    overall_score=100,
    node_count=0,
  )
  let graph = @graph.DependencyGraph::new()
  let sarif = @analyze.render_sarif_report(report, graph, "root@1.0.0")
  assert_true(sarif.contains("\"version\":\"2.1.0\""))
  assert_true(sarif.contains("\"results\":[]"))
}
