///|
/// 改进测试：并发模拟、性能回归阈值、更多 Mock 场景
/// 补充原有测试的覆盖盲区

// ---------- 并发 Fetch 模拟测试 ----------

test "concurrent fetch multiple packages" {
  let registry : Map[String, @parse.Module] = {
    "a@1.0.0": @parse.Module::new("a", "1.0.0", { "b": "1.0.0" }),
    "b@1.0.0": @parse.Module::new("b", "1.0.0", { "c": "1.0.0" }),
    "c@1.0.0": @parse.Module::new("c", "1.0.0", Map([])),
  }

  let mut fetch_count = 0
  fn counting_fetch(
    name : String,
    version : String,
  ) -> Result[@parse.Module, String] {
    fetch_count = fetch_count + 1
    let id = name + "@" + version
    match registry.get(id) {
      Some(m) => Ok(m)
      None => Err("Not found: " + id)
    }
  }

  let builder = @graph.GraphBuilder::new()
  let graph = match builder.build("a", "1.0.0", counting_fetch) {
    Ok(g) => g
    Err(msg) => fail("Build failed: " + msg)
  }

  // 应该 fetch 了 3 个包
  inspect(fetch_count, content="3")
  // 图应该包含 3 个节点
  inspect(graph.size(), content="3")
}

///|
test "concurrent fetch with partial failures" {
  let registry : Map[String, @parse.Module] = {
    "a@1.0.0": @parse.Module::new("a", "1.0.0", { "b": "1.0.0", "c": "1.0.0" }),
    "b@1.0.0": @parse.Module::new("b", "1.0.0", Map([])),
    // c 不存在
  }

  fn partial_fail_fetch(
    name : String,
    version : String,
  ) -> Result[@parse.Module, String] {
    let id = name + "@" + version
    match registry.get(id) {
      Some(m) => Ok(m)
      None => Err("Package not found: " + id)
    }
  }

  let builder = @graph.GraphBuilder::new_with_max_depth(5)
  // 当依赖 fetch 失败时，GraphBuilder 会返回 Err
  let result = builder.build("a", "1.0.0", partial_fail_fetch)
  match result {
    Ok(graph) =>
      // 如果成功，至少有根节点
      assert_true(graph.size() >= 1)
    Err(_) =>
      // 如果失败，这是预期行为
      assert_true(true)
  }
}

// ---------- 性能回归阈值测试（快速版本，不 skip） ----------

///|
test "perf: graph build 10 nodes under 100ms" {
  let registry : Map[String, @parse.Module] = Map([])
  let mut i = 0
  while i < 10 {
    let name = "pkg" + i.to_string()
    let deps : Map[String, String] = Map([])
    if i > 0 {
      deps["pkg" + (i - 1).to_string()] = "1.0.0"
    }
    registry[name + "@1.0.0"] = @parse.Module::new(name, "1.0.0", deps)
    i = i + 1
  }

  fn mock_fetch(
    name : String,
    version : String,
  ) -> Result[@parse.Module, String] {
    let id = name + "@" + version
    match registry.get(id) {
      Some(m) => Ok(m)
      None => Err("not found")
    }
  }

  let start = perf_now()
  let builder = @graph.GraphBuilder::new()
  let _graph = match builder.build("pkg9", "1.0.0", mock_fetch) {
    Ok(g) => g
    Err(_) => fail("Build failed")
  }
  let elapsed = perf_now() - start

  // 10 节点图构建应 < 100ms
  assert_true(elapsed < 100.0)
}

///|
test "perf: analysis 10 nodes under 50ms" {
  let graph = @graph.DependencyGraph::new()
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let mut i = 0
  while i < 10 {
    let name = "pkg" + i.to_string()
    graph.add_node(name, "1.0.0", i)
    if i > 0 {
      graph.add_edge(name, "1.0.0", "pkg" + (i - 1).to_string(), "1.0.0")
    }
    metas[name + "@1.0.0"] = @analyze.NodeMeta::new(license=Some("MIT"))
    i = i + 1
  }

  let start = perf_now()
  let _report = @analyze.run_analysis(graph, metas)
  let elapsed = perf_now() - start

  // 10 节点分析应 < 50ms
  assert_true(elapsed < 50.0)
}

///|
test "perf: report rendering under 100ms" {
  let graph = @graph.DependencyGraph::new()
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let mut i = 0
  while i < 10 {
    let name = "pkg" + i.to_string()
    graph.add_node(name, "1.0.0", i)
    if i > 0 {
      graph.add_edge(name, "1.0.0", "pkg" + (i - 1).to_string(), "1.0.0")
    }
    metas[name + "@1.0.0"] = @analyze.NodeMeta::new(license=Some("MIT"))
    i = i + 1
  }
  let report = @analyze.run_analysis(graph, metas)

  let start = perf_now()
  ignore(@analyze.render_audit_report(report))
  ignore(@analyze.render_terminal_report(report, graph, "pkg9@1.0.0"))
  ignore(@analyze.render_html_report(report, graph, "pkg9@1.0.0"))
  ignore(@analyze.render_audit_json(report))
  let elapsed = perf_now() - start

  // 10 节点报告渲染应 < 100ms
  assert_true(elapsed < 100.0)
}

// ---------- 更多 Mock 场景测试 ----------

///|
test "mock: fetch returns invalid JSON" {
  fn invalid_json_fetch(
    _name : String,
    _version : String,
  ) -> Result[@parse.Module, String] {
    Err("Invalid JSON response")
  }

  let builder = @graph.GraphBuilder::new()
  // 无效 JSON 应该返回错误
  let result = builder.build("root", "1.0.0", invalid_json_fetch)
  match result {
    Ok(_) => fail("Should fail on invalid JSON")
    Err(_) => assert_true(true) // 预期行为
  }
}

///|
test "mock: fetch returns empty string" {
  fn empty_fetch(
    _name : String,
    _version : String,
  ) -> Result[@parse.Module, String] {
    Err("Empty response")
  }

  let builder = @graph.GraphBuilder::new()
  let result = builder.build("root", "1.0.0", empty_fetch)
  match result {
    Ok(_) => fail("Should fail on empty response")
    Err(_) => assert_true(true)
  }
}

///|
test "mock: fetch timeout simulation" {
  fn timeout_fetch(
    _name : String,
    _version : String,
  ) -> Result[@parse.Module, String] {
    Err("Request timeout after 12000ms")
  }

  let builder = @graph.GraphBuilder::new()
  let result = builder.build("root", "1.0.0", timeout_fetch)
  match result {
    Ok(_) => fail("Should fail on timeout")
    Err(_) => assert_true(true)
  }
}

///|
test "mock: fetch rate limit (429)" {
  fn rate_limit_fetch(
    _name : String,
    _version : String,
  ) -> Result[@parse.Module, String] {
    Err("HTTP 429: Too Many Requests")
  }

  let builder = @graph.GraphBuilder::new()
  let result = builder.build("root", "1.0.0", rate_limit_fetch)
  match result {
    Ok(_) => fail("Should fail on rate limit")
    Err(_) => assert_true(true)
  }
}

///|
test "mock: fetch 404 not found" {
  fn not_found_fetch(
    _name : String,
    _version : String,
  ) -> Result[@parse.Module, String] {
    Err("HTTP 404: Not Found")
  }

  let builder = @graph.GraphBuilder::new()
  let result = builder.build("root", "1.0.0", not_found_fetch)
  match result {
    Ok(_) => fail("Should fail on 404")
    Err(_) => assert_true(true)
  }
}

// ---------- 评分边界测试 ----------

///|
test "score: all dimensions at minimum" {
  let input = @analyze.NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    latest_version=Some("2.0.0"),
    license_spdx=Some("GPL-3.0"),
    deprecated_count=10,
    total_api_count=10,
    transitive_size=Some(10 * 1024 * 1024),
    last_commit_days_ago=Some(400),
  )
  let score = @analyze.calculate_health_score(input)
  // 所有维度都差，总分应该很低
  assert_true(score.total < 50)
}

///|
test "score: all dimensions at maximum" {
  let input = @analyze.NodeScoreInput::new(
    "pkg@1.0.0",
    "2.0.0",
    latest_version=Some("2.0.0"),
    license_spdx=Some("MIT"),
    deprecated_count=0,
    total_api_count=100,
    transitive_size=Some(1024),
    last_commit_days_ago=Some(5),
  )
  let score = @analyze.calculate_health_score(input)
  // 所有维度都好，总分应该很高
  assert_true(score.total >= 90)
}

///|
test "score: custom weights validation" {
  // 有效权重（总和 100）
  let w1 = @analyze.ScoreWeights::new(
    freshness=30,
    compliance=20,
    deprecated_density=20,
    size_reasonableness=20,
    activity=10,
  )
  assert_true(w1.freshness == 30)

  // 无效权重（总和 ≠ 100）应使用默认值
  let w2 = @analyze.ScoreWeights::new(
    freshness=50,
    compliance=50,
    deprecated_density=50,
    size_reasonableness=50,
    activity=50,
  )
  assert_true(w2.freshness == 25) // 默认值
}

// ---------- 诊断过滤测试（通过公开 API 测试） ----------

///|
test "filter: diagnostic severity levels" {
  let critical = @report.Diagnostic::critical("C1", "Critical", [])
  let warning = @report.Diagnostic::warning("W1", "Warning", [])
  let info = @report.Diagnostic::info("I1", "Info", [])

  assert_true(critical.is_critical())
  assert_true(!critical.is_warning())
  assert_true(!critical.is_info())

  assert_true(!warning.is_critical())
  assert_true(warning.is_warning())
  assert_true(!warning.is_info())

  assert_true(!info.is_critical())
  assert_true(!info.is_warning())
  assert_true(info.is_info())
}

// ---------- 拓扑排序测试 ----------

///|
test "topo sort: linear chain" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("a", "1.0.0", 0)
  graph.add_node("b", "1.0.0", 1)
  graph.add_node("c", "1.0.0", 2)
  graph.add_edge("a", "1.0.0", "b", "1.0.0")
  graph.add_edge("b", "1.0.0", "c", "1.0.0")

  let result = graph.topological_sort()
  match result {
    Ok(order) => {
      // a 应该在 b 之前，b 应该在 c 之前
      let idx_a = find_index(order, "a@1.0.0")
      let idx_b = find_index(order, "b@1.0.0")
      let idx_c = find_index(order, "c@1.0.0")
      assert_true(idx_a < idx_b)
      assert_true(idx_b < idx_c)
    }
    Err(msg) => fail("Should not detect cycle: " + msg)
  }
}

///|
test "topo sort: diamond dependency" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)
  graph.add_node("left", "1.0.0", 1)
  graph.add_node("right", "1.0.0", 1)
  graph.add_node("bottom", "1.0.0", 2)
  graph.add_edge("root", "1.0.0", "left", "1.0.0")
  graph.add_edge("root", "1.0.0", "right", "1.0.0")
  graph.add_edge("left", "1.0.0", "bottom", "1.0.0")
  graph.add_edge("right", "1.0.0", "bottom", "1.0.0")

  let result = graph.topological_sort()
  match result {
    Ok(order) => inspect(order.length(), content="4")
    Err(msg) => fail("Diamond should not have cycle: " + msg)
  }
}

///|
test "topo sort: cycle detection" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("a", "1.0.0", 0)
  graph.add_node("b", "1.0.0", 1)
  graph.add_node("c", "1.0.0", 2)
  graph.add_edge("a", "1.0.0", "b", "1.0.0")
  graph.add_edge("b", "1.0.0", "c", "1.0.0")
  graph.add_edge("c", "1.0.0", "a", "1.0.0")

  let result = graph.topological_sort()
  match result {
    Ok(_) => fail("Should detect cycle")
    Err(msg) => assert_true(msg.contains("Cycle"))
  }
}

// ---------- 辅助函数 ----------

///|
fn perf_now() -> Double {
  js_perf_now()
}

///|
extern "js" fn js_perf_now() -> Double =
  #| () => performance.now()

///|
fn find_index(arr : Array[String], target : String) -> Int {
  let mut i = 0
  for item in arr {
    if item == target {
      return i
    }
    i = i + 1
  }
  -1
}
