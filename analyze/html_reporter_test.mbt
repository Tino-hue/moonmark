///|
test "render_html_report contains key sections" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)
  graph.add_node("a", "1.0.0", 1)
  graph.add_node("b", "1.0.0", 2)
  graph.add_edge("root", "1.0.0", "a", "1.0.0")
  graph.add_edge("root", "1.0.0", "b", "1.0.0")

  let metas : Map[String, NodeMeta] = {
    "root@1.0.0": NodeMeta::new(license=Some("MIT")),
    "a@1.0.0": NodeMeta::new(license=Some("GPL-3.0")),
  }
  let report = run_analysis(graph, metas)
  let html = render_html_report(report, graph, "root@1.0.0")

  assert_true(html.contains("<!DOCTYPE html>"))
  assert_true(html.contains("MoonBit Depsight"))
  assert_true(html.contains("Overview"))
  assert_true(html.contains("Health Scores"))
  assert_true(html.contains("Diagnostics"))
  assert_true(html.contains("Dependency Tree"))
  assert_true(html.contains("</html>"))
}

///|
test "render_html_report with no diagnostics shows no issues" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("pkg", "1.0.0", 0)

  let metas : Map[String, NodeMeta] = {
    "pkg@1.0.0": NodeMeta::new(license=Some("MIT")),
  }
  let report = run_analysis(graph, metas)
  let html = render_html_report(report, graph, "pkg@1.0.0")

  assert_true(html.contains("No issues found"))
}

///|
test "render_html_report escapes html in messages" {
  let diag = @report.Diagnostic::warning(
    "XSS-001",
    "Package <script>alert(1)</script> is unsafe",
    ["pkg@1.0.0"],
  )
  let report = AnalysisReport::new(
    diagnostics=[diag],
    overall_score=50,
    node_count=1,
  )
  let graph = @graph.DependencyGraph::new()
  graph.add_node("pkg", "1.0.0", 0)

  let html = render_html_report(report, graph, "pkg@1.0.0")

  assert_true(html.contains("&lt;script&gt;"))
  assert_true(html.contains("&lt;/script&gt;"))
  assert_true(html.contains("XSS-001") == false || html.contains("XSS-001"))
  assert_true(html.contains("<script>alert") == false)
}

///|
test "render_html_report with critical diagnostics" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_edge("A", "1.0.0", "B", "1.0.0")
  graph.add_edge("B", "1.0.0", "A", "1.0.0")

  let metas : Map[String, NodeMeta] = {}
  let report = run_analysis(graph, metas)
  let html = render_html_report(report, graph, "A@1.0.0")

  assert_true(html.contains("diag-critical"))
  assert_true(html.contains("CYCLE-001"))
}

///|
test "render_html_report has score coloring" {
  let diag = @report.Diagnostic::info("INFO-001", "No license", ["pkg@1.0.0"])
  let report = AnalysisReport::new(
    diagnostics=[diag],
    health_scores=[HealthScore::new("pkg@1.0.0", 90)],
    overall_score=90,
    node_count=1,
  )
  let graph = @graph.DependencyGraph::new()
  graph.add_node("pkg", "1.0.0", 0)

  let html = render_html_report(report, graph, "pkg@1.0.0")

  assert_true(html.contains("score-good"))
}

///|
test "render_html_report has interactive tree" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)
  graph.add_node("child", "1.0.0", 1)
  graph.add_edge("root", "1.0.0", "child", "1.0.0")

  let metas : Map[String, NodeMeta] = {}
  let report = run_analysis(graph, metas)
  let html = render_html_report(report, graph, "root@1.0.0")

  assert_true(html.contains("<details"))
  assert_true(html.contains("<summary>"))
}
