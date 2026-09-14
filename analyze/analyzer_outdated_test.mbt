///|
/// OUTDATED-001 / DUPLICATE-001 诊断码测试

///|
test "run analysis detects outdated dependency (major -> warning)" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("pkg", "1.0.0", 0)

  let metas : Map[String, NodeMeta] = {
    "pkg@1.0.0": NodeMeta::new(
      license=Some("MIT"),
      latest_version=Some("2.0.0"),
    ),
  }
  let report = run_analysis(graph, metas)

  let mut found = false
  for d in report.diagnostics {
    if d.code == "OUTDATED-001" {
      found = true
      assert_true(d.is_warning())
      assert_true(d.path.length() == 1)
      assert_true(d.path[0] == "pkg@1.0.0")
    }
  }
  assert_true(found)
}

///|
test "run analysis outdated minor bump is info" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("pkg", "1.0.0", 0)

  let metas : Map[String, NodeMeta] = {
    "pkg@1.0.0": NodeMeta::new(latest_version=Some("1.1.0")),
  }
  let report = run_analysis(graph, metas)

  let mut found = false
  for d in report.diagnostics {
    if d.code == "OUTDATED-001" {
      found = true
      assert_true(d.is_info())
    }
  }
  assert_true(found)
}

///|
test "run analysis no outdated when latest equals current" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("pkg", "1.0.0", 0)

  let metas : Map[String, NodeMeta] = {
    "pkg@1.0.0": NodeMeta::new(latest_version=Some("1.0.0")),
  }
  let report = run_analysis(graph, metas)

  for d in report.diagnostics {
    assert_true(d.code != "OUTDATED-001")
  }
}

///|
test "run analysis detects duplicate versions" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("lib", "1.0.0", 0)
  graph.add_node("lib", "2.0.0", 1)

  let metas : Map[String, NodeMeta] = Map([])
  let report = run_analysis(graph, metas)

  let mut found = false
  for d in report.diagnostics {
    if d.code == "DUPLICATE-001" {
      found = true
      assert_true(d.is_warning())
      assert_true(d.path.length() == 2)
    }
  }
  assert_true(found)
}

///|
test "run analysis no duplicate for distinct names" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("a", "1.0.0", 0)
  graph.add_node("b", "1.0.0", 1)

  let metas : Map[String, NodeMeta] = Map([])
  let report = run_analysis(graph, metas)

  for d in report.diagnostics {
    assert_true(d.code != "DUPLICATE-001")
  }
}
