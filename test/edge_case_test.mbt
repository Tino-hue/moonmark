///|
/// Day 25 — Edge case tests
/// 覆盖空依赖、自依赖、异常版本号等边界场景

// ---------- 空依赖 ----------

test "empty deps graph has only root node" {
  let root = @parse.Module::new("root", "1.0.0", Map([]))
  let registry = { "root@1.0.0": root }
  let fetch = make_mock_fetch(registry)
  let builder = @graph.GraphBuilder::new()
  let graph = match builder.build("root", "1.0.0", fetch) {
    Ok(g) => g
    Err(msg) => fail("Build failed: " + msg)
  }
  inspect(graph.size(), content="1")
  inspect(graph.get_children("root", "1.0.0").length(), content="0")
}

///|
test "empty deps analysis has perfect score" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)
  let metas : Map[String, @analyze.NodeMeta] = {
    "root@1.0.0": @analyze.NodeMeta::new(license=Some("MIT")),
  }
  let report = @analyze.run_analysis(graph, metas)
  inspect(report.node_count, content="1")
  inspect(report.overall_score, content="98")
  inspect(report.diagnostics.length(), content="0")
}

// ---------- 自依赖 ----------

///|
test "self dependency creates cycle" {
  let self_dep = @parse.Module::new("self-dep", "1.0.0", { "self-dep": "1.0.0" })
  let registry = { "self-dep@1.0.0": self_dep }
  let fetch = make_mock_fetch(registry)
  let builder = @graph.GraphBuilder::new()
  let graph = match builder.build("self-dep", "1.0.0", fetch) {
    Ok(g) => g
    Err(msg) => fail("Build failed: " + msg)
  }
  inspect(graph.size(), content="1")
  // add_edge should have added the self-loop
  let children = graph.get_children("self-dep", "1.0.0")
  inspect(children.length(), content="1")
  inspect(children[0], content="self-dep@1.0.0")

  let diags = graph.check_cycles()
  inspect(diags.length(), content="1")
  inspect(diags[0].code, content="CYCLE-001")
}

///|
test "self dependency in analysis" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_edge("A", "1.0.0", "A", "1.0.0")

  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let report = @analyze.run_analysis(graph, metas)
  inspect(report.node_count, content="1")
  assert_true(report.diagnostics.length() > 0)
  let cycle_found = report.diagnostics
    .iter()
    .any(fn(d) { d.code == "CYCLE-001" })
  assert_true(cycle_found)
}

// ---------- 异常版本号 ----------

///|
test "parse empty version string" {
  let r = @analyze.parse_version("")
  assert_true(r is Err(_))
}

///|
test "parse non-numeric version" {
  let r = @analyze.parse_version("not.a.version")
  assert_true(r is Err(_))
}

///|
test "parse single number version" {
  let r = @analyze.parse_version("1")
  assert_true(r is Err(_))
}

///|
test "parse two number version" {
  let r = @analyze.parse_version("1.2")
  assert_true(r is Err(_))
}

///|
test "parse four number version" {
  let r = @analyze.parse_version("1.2.3.4")
  assert_true(r is Err(_))
}

///|
test "parse negative major version" {
  let r = @analyze.parse_version("-1.0.0")
  assert_true(r is Err(_))
}

///|
test "parse negative minor version" {
  let r = @analyze.parse_version("1.-1.0")
  assert_true(r is Err(_))
}

///|
test "parse negative patch version" {
  let r = @analyze.parse_version("1.0.-1")
  assert_true(r is Err(_))
}

///|
test "parse version with leading zeros" {
  let v = match @analyze.parse_version("01.02.03") {
    Ok(v) => v
    Err(_) => fail("Should parse leading-zero version")
  }
  inspect(v.major, content="1")
  inspect(v.minor, content="2")
  inspect(v.patch, content="3")
}

///|
test "parse version with only zeros" {
  let v = match @analyze.parse_version("0.0.0") {
    Ok(v) => v
    Err(_) => fail("Should parse 0.0.0")
  }
  inspect(v.major, content="0")
  inspect(v.minor, content="0")
  inspect(v.patch, content="0")
}

///|
test "parse version with large numbers" {
  let v = match @analyze.parse_version("999.888.777") {
    Ok(v) => v
    Err(_) => fail("Should parse large version")
  }
  inspect(v.major, content="999")
  inspect(v.minor, content="888")
  inspect(v.patch, content="777")
}

///|
test "score freshness on invalid version returns fallback" {
  let input = @analyze.NodeScoreInput::new(
    "pkg@1.0.0",
    "bad.version",
    latest_version=Some("2.0.0"),
  )
  let score = @analyze.calculate_health_score(input)
  inspect(score.freshness, content="50")
}

///|
test "score freshness on invalid latest version returns fallback" {
  let input = @analyze.NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    latest_version=Some("invalid"),
  )
  let score = @analyze.calculate_health_score(input)
  inspect(score.freshness, content="50")
}
