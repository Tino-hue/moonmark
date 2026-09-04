///|
test "run analysis on empty graph" {
  let graph = @graph.DependencyGraph::new()
  let metas : Map[String, NodeMeta] = Map([])
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

  let metas : Map[String, NodeMeta] = Map([])
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

  // 给两节点真实 self_size；若无 size，size_reasonableness 会走 None→80
  // 而不是占位时代码误给的 Some(0)→100。用真实值时 F02 传递 size = self_size
  //（无依赖图边），于是 size_reasonableness=100（<10KB）。
  let metas : Map[String, NodeMeta] = {
    "a@1.0.0": NodeMeta::new(license=Some("MIT"), self_size=2048),
    "b@2.0.0": NodeMeta::new(license=Some("MIT"), self_size=1024),
  }
  let report = run_analysis(graph, metas)
  inspect(report.health_scores.length(), content="2")
  inspect(report.overall_score, content="98")
  // 两节点无依赖边，传递体积 = 自身体积；Top 5 罪犯应为 2 条
  inspect(report.size_offenders_top5.length(), content="2")
  // 降序：a(2048) > b(1024)
  if report.size_offenders_top5.length() == 2 {
    inspect(report.size_offenders_top5[0].node_id, content="a@1.0.0")
    inspect(report.size_offenders_top5[0].transitive_size, content="2048")
    inspect(report.size_offenders_top5[1].node_id, content="b@2.0.0")
  }
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
