///|
/// Day 24 — 性能基准测试
/// 使用 JS FFI Date.now() 测量各阶段耗时（微秒）
extern "js" fn date_now() -> Double =
  #| () => Date.now()

///|
/// 简易基准测试：返回单次迭代平均耗时（微秒）
fn simple_bench(f : () -> Unit, iterations : Int) -> Double {
  // warmup
  for _ in 0..<3 {
    f()
  }
  let start = date_now()
  for _ in 0..<iterations {
    f()
  }
  let end = date_now()
  (end - start) * 1000.0 / iterations.to_double()
}

// ---------- 测试数据生成器 ----------

///|
fn make_bench_registry_chain(n : Int) -> Map[String, @parse.Module] {
  let r : Map[String, @parse.Module] = Map([])
  let mut i = 0
  while i < n {
    let name = "p" + i.to_string()
    let version = "1.0.0"
    let deps : Map[String, String] = Map([])
    if i + 1 < n {
      deps["p" + (i + 1).to_string()] = "1.0.0"
    }
    r[name + "@" + version] = @parse.Module::new(name, version, deps)
    i = i + 1
  }
  r
}

///|
fn make_bench_mock_fetch(
  registry : Map[String, @parse.Module],
) -> (String, String) -> Result[@parse.Module, String] {
  fn fetch(name : String, version : String) -> Result[@parse.Module, String] {
    let id = name + "@" + version
    match registry.get(id) {
      Some(m) => Ok(m)
      None => Err("not found")
    }
  }
  fetch
}

///|
fn build_graph(registry : Map[String, @parse.Module]) -> @graph.DependencyGraph {
  let fetch = make_bench_mock_fetch(registry)
  let builder = @graph.GraphBuilder::new()
  match builder.build("p0", "1.0.0", fetch) {
    Ok(g) => g
    Err(_) => @graph.DependencyGraph::new()
  }
}

///|
fn build_and_analyze(
  registry : Map[String, @parse.Module],
) -> (@graph.DependencyGraph, @analyze.AnalysisReport) {
  let graph = build_graph(registry)
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let report = @analyze.run_analysis(graph, metas)
  (graph, report)
}

// ---------- 小规模（5 节点）----------

///|
#skip("slow benchmarking test")
test "benchmark: small graph build (5 nodes)" {
  let registry = make_bench_registry_chain(5)
  let mean_us = simple_bench(
    () => {
      let fetch = make_bench_mock_fetch(registry)
      let builder = @graph.GraphBuilder::new()
      ignore(builder.build("p0", "1.0.0", fetch))
    },
    100,
  )
  // 图构建应 < 50ms（50,000 微秒）
  assert_true(mean_us < 50000.0)
}

///|
#skip("slow benchmarking test")
test "benchmark: small full pipeline (5 nodes)" {
  let registry = make_bench_registry_chain(5)
  let mean_us = simple_bench(
    () => {
      let (graph, report) = build_and_analyze(registry)
      ignore(@analyze.render_audit_report(report))
      ignore(@analyze.render_terminal_report(report, graph, "p0@1.0.0"))
      ignore(@analyze.render_html_report(report, graph, "p0@1.0.0"))
      ignore(@analyze.render_audit_json(report))
    },
    50,
  )
  // 完整流程应 < 200ms
  assert_true(mean_us < 200000.0)
}

// ---------- 中规模（50 节点）----------

///|
#skip("slow benchmarking test")
test "benchmark: medium graph build (50 nodes)" {
  let registry = make_bench_registry_chain(50)
  let mean_us = simple_bench(
    () => {
      let fetch = make_bench_mock_fetch(registry)
      let builder = @graph.GraphBuilder::new()
      ignore(builder.build("p0", "1.0.0", fetch))
    },
    20,
  )
  // 图构建应 < 200ms
  assert_true(mean_us < 200000.0)
}

///|
#skip("slow benchmarking test")
test "benchmark: medium analysis (50 nodes)" {
  let registry = make_bench_registry_chain(50)
  let graph = build_graph(registry)
  let mean_us = simple_bench(
    () => {
      let metas : Map[String, @analyze.NodeMeta] = Map([])
      ignore(@analyze.run_analysis(graph, metas))
    },
    20,
  )
  // 分析应 < 100ms
  assert_true(mean_us < 100000.0)
}

///|
#skip("slow benchmarking test")
test "benchmark: medium full pipeline (50 nodes)" {
  let registry = make_bench_registry_chain(50)
  let mean_us = simple_bench(
    () => {
      let (graph, report) = build_and_analyze(registry)
      ignore(@analyze.render_audit_report(report))
      ignore(@analyze.render_terminal_report(report, graph, "p0@1.0.0"))
      ignore(@analyze.render_html_report(report, graph, "p0@1.0.0"))
      ignore(@analyze.render_audit_json(report))
    },
    10,
  )
  // 完整流程应 < 1s
  assert_true(mean_us < 1000000.0)
}

// ---------- 大规模（200 节点）----------

///|
#skip("slow benchmarking test")
test "benchmark: large graph build (200 nodes)" {
  let registry = make_bench_registry_chain(200)
  let mean_us = simple_bench(
    () => {
      let fetch = make_bench_mock_fetch(registry)
      let builder = @graph.GraphBuilder::new()
      ignore(builder.build("p0", "1.0.0", fetch))
    },
    5,
  )
  // 图构建应 < 1s
  assert_true(mean_us < 1000000.0)
}

///|
#skip("slow benchmarking test")
test "benchmark: large analysis (200 nodes)" {
  let registry = make_bench_registry_chain(200)
  let graph = build_graph(registry)
  let mean_us = simple_bench(
    () => {
      let metas : Map[String, @analyze.NodeMeta] = Map([])
      ignore(@analyze.run_analysis(graph, metas))
    },
    5,
  )
  // 分析应 < 500ms
  assert_true(mean_us < 500000.0)
}

///|
#skip("slow benchmarking test")
test "benchmark: large report rendering (200 nodes)" {
  let registry = make_bench_registry_chain(200)
  let (graph, report) = build_and_analyze(registry)
  let mean_us = simple_bench(
    () => {
      ignore(@analyze.render_audit_report(report))
      ignore(@analyze.render_terminal_report(report, graph, "p0@1.0.0"))
      ignore(@analyze.render_html_report(report, graph, "p0@1.0.0"))
      ignore(@analyze.render_audit_json(report))
    },
    5,
  )
  // 报告渲染应 < 2s
  assert_true(mean_us < 2000000.0)
}

///|
#skip("slow benchmarking test")
test "benchmark: large full pipeline (200 nodes)" {
  let registry = make_bench_registry_chain(200)
  let mean_us = simple_bench(
    () => {
      let (graph, report) = build_and_analyze(registry)
      ignore(@analyze.render_audit_report(report))
      ignore(@analyze.render_terminal_report(report, graph, "p0@1.0.0"))
      ignore(@analyze.render_html_report(report, graph, "p0@1.0.0"))
      ignore(@analyze.render_audit_json(report))
    },
    3,
  )
  // 验收标准 < 10s，留一倍余量到 < 5s
  assert_true(mean_us < 5000000.0)
}
