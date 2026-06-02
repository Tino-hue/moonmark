///|
test "run analysis on empty graph" {
  let graph = @graph.DependencyGraph::new()
  let metas : Map[String, NodeMeta] = {}
  let report = run_analysis(graph, metas)
  inspect(report.node_count, content="0")
  inspect(report.overall_score, content="100")
  inspect(report.diagnostics.length(), content="0")
}

///|
test "run analysis detects cycle" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_node("C", "1.0.0", 2)
  graph.add_edge("A", "1.0.0", "B", "1.0.0")
  graph.add_edge("B", "1.0.0", "C", "1.0.0")
  graph.add_edge("C", "1.0.0", "A", "1.0.0")

  let metas : Map[String, NodeMeta] = {}
  let report = run_analysis(graph, metas)
  inspect(report.node_count, content="3")
  assert_true(report.diagnostics.length() > 0)
}

///|
test "run analysis with high risk license" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("pkg", "1.0.0", 0)

  let metas : Map[String, NodeMeta] = {
    "pkg@1.0.0": NodeMeta::new(license=Some("GPL-3.0")),
  }
  let report = run_analysis(graph, metas)
  inspect(report.node_count, content="1")

  let mut found = false
  for d in report.diagnostics {
    if d.code == "LICENSE-001" {
      found = true
    }
  }
  assert_true(found)
}

///|
test "run analysis with deprecated apis" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("pkg", "1.0.0", 0)

  let metas : Map[String, NodeMeta] = {
    "pkg@1.0.0": NodeMeta::new(deprecated_apis=[DeprecatedApi::new("old_fn")]),
  }
  let report = run_analysis(graph, metas)

  let mut found = false
  for d in report.diagnostics {
    if d.code == "DEPRECATED-001" {
      found = true
    }
  }
  assert_true(found)
}

///|
test "run analysis overall score" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("a", "1.0.0", 0)
  graph.add_node("b", "2.0.0", 1)

  let metas : Map[String, NodeMeta] = {
    "a@1.0.0": NodeMeta::new(license=Some("MIT")),
    "b@2.0.0": NodeMeta::new(license=Some("MIT")),
  }
  let report = run_analysis(graph, metas)
  inspect(report.health_scores.length(), content="2")
  inspect(report.overall_score, content="98")
}

///|
test "render report contains summary" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("pkg", "1.0.0", 0)

  let metas : Map[String, NodeMeta] = {
    "pkg@1.0.0": NodeMeta::new(license=Some("MIT")),
  }
  let report = run_analysis(graph, metas)
  let text = render_report(report)
  assert_true(text.contains("MoonBit Depsight Analysis Report"))
  assert_true(text.contains("1 nodes analyzed"))
  assert_true(text.contains("Overall Health Score"))
}
