///|
/// Day 23 — 真实生态采样测试
/// 基于 10 个代表性 MoonBit 包的 fixture 数据，形成复杂 DAG，
/// 批量构建依赖图、运行完整分析、输出生态统计报告。

// ---------- 生态样本定义 ----------

fn make_ecosystem_registry() -> Map[String, @parse.Module] {
  let r : Map[String, @parse.Module] = Map([])

  // 1. moonbitlang/core — 生态基石，被几乎所有包依赖
  r["moonbitlang/core@0.1.0"] = @parse.Module::new(
    "moonbitlang/core",
    "0.1.0",
    Map([]),
  )

  // 2. moonbitlang/x — 实验性扩展包
  r["moonbitlang/x@0.4.44"] = @parse.Module::new("moonbitlang/x", "0.4.44", {
    "moonbitlang/core": "0.1.0",
  })

  // 3. Lampese/moonbit-chalk — 终端颜色
  r["Lampese/moonbit-chalk@0.4.0"] = @parse.Module::new(
    "Lampese/moonbit-chalk",
    "0.4.0",
    { "moonbitlang/core": "0.1.0" },
  )

  // 4. peter-jerry-ye/parser-combinator — 解析器组合子
  r["peter-jerry-ye/parser-combinator@0.9.1"] = @parse.Module::new(
    "peter-jerry-ye/parser-combinator",
    "0.9.1",
    { "moonbitlang/core": "0.1.0" },
  )

  // 5. xinyu-lv/json5 — JSON5 解析
  r["xinyu-lv/json5@0.1.3"] = @parse.Module::new("xinyu-lv/json5", "0.1.3", {
    "moonbitlang/core": "0.1.0",
    "peter-jerry-ye/parser-combinator": "0.9.1",
  })

  // 6. LittleFish/depsight — 本项目（自引用为根）
  r["LittleFish/depsight@0.1.0"] = @parse.Module::new(
    "LittleFish/depsight",
    "0.1.0",
    { "moonbitlang/core": "0.1.0", "moonbitlang/x": "0.4.44" },
  )

  // 7. yj-qin/regexp — 正则表达式
  r["yj-qin/regexp@0.3.0"] = @parse.Module::new("yj-qin/regexp", "0.3.0", {
    "moonbitlang/core": "0.1.0",
  })

  // 8. fantix/json — JSON 处理
  r["fantix/json@0.2.1"] = @parse.Module::new("fantix/json", "0.2.1", {
    "moonbitlang/core": "0.1.0",
    "yj-qin/regexp": "0.3.0",
  })

  // 9. chenxuuu/websocket — WebSocket 客户端
  r["chenxuuu/websocket@0.1.0"] = @parse.Module::new(
    "chenxuuu/websocket",
    "0.1.0",
    { "moonbitlang/core": "0.1.0", "moonbitlang/x": "0.4.44" },
  )

  // 10. demo/app — 一个假设的顶层应用，依赖多个包
  r["demo/app@1.0.0"] = @parse.Module::new("demo/app", "1.0.0", {
    "moonbitlang/core": "0.1.0",
    "moonbitlang/x": "0.4.44",
    "Lampese/moonbit-chalk": "0.4.0",
    "xinyu-lv/json5": "0.1.3",
    "fantix/json": "0.2.1",
    "chenxuuu/websocket": "0.1.0",
    "LittleFish/depsight": "0.1.0",
  })

  r
}

///|
fn make_mock_fetch(
  registry : Map[String, @parse.Module],
) -> (String, String) -> Result[@parse.Module, String] {
  fn fetch(name : String, version : String) -> Result[@parse.Module, String] {
    let id = name + "@" + version
    match registry.get(id) {
      Some(m) => Ok(m)
      None => Err("Package not found: " + id)
    }
  }
  fetch
}

// ---------- 生态统计 ----------

///|
/// 生态采样报告
struct EcosystemReport {
  total_packages : Int
  total_nodes : Int
  max_depth : Int
  avg_depth : Double
  cycle_detected : Bool
  most_depended : String
  most_depended_count : Int
  license_distribution : Map[String, Int]
  overall_health_score : Int
}

///|
/// 运行生态采样分析
fn run_ecosystem_sampling(
  root_name : String,
  root_version : String,
  registry : Map[String, @parse.Module],
) -> Result[
  (@graph.DependencyGraph, @analyze.AnalysisReport, EcosystemReport),
  String,
] {
  let fetch = make_mock_fetch(registry)
  let builder = @graph.GraphBuilder::new()

  let graph = match builder.build(root_name, root_version, fetch) {
    Ok(g) => g
    Err(e) => return Err(e)
  }

  // 构造元数据（模拟真实包的 license 信息）
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let license_map : Map[String, String] = {
    "moonbitlang/core@0.1.0": "Apache-2.0",
    "moonbitlang/x@0.4.44": "Apache-2.0",
    "Lampese/moonbit-chalk@0.4.0": "MIT",
    "peter-jerry-ye/parser-combinator@0.9.1": "MIT",
    "xinyu-lv/json5@0.1.3": "MIT",
    "LittleFish/depsight@0.1.0": "Apache-2.0",
    "yj-qin/regexp@0.3.0": "MIT",
    "fantix/json@0.2.1": "BSD-3-Clause",
    "chenxuuu/websocket@0.1.0": "MIT",
    "demo/app@1.0.0": "Apache-2.0",
  }

  for pair in license_map {
    let (id, spdx) = pair
    metas[id] = @analyze.NodeMeta::new(license=Some(spdx))
  }

  let report = @analyze.run_analysis(graph, metas)

  // 生态统计
  let eco = calculate_ecosystem_stats(graph, report, license_map)

  Ok((graph, report, eco))
}

///|
fn calculate_ecosystem_stats(
  graph : @graph.DependencyGraph,
  report : @analyze.AnalysisReport,
  license_map : Map[String, String],
) -> EcosystemReport {
  let ids = graph.get_all_node_ids()
  let total_nodes = ids.length()

  // 计算深度统计
  let mut max_depth = 0
  let mut total_depth = 0
  for id in ids {
    match graph.get_node_by_id(id) {
      Some(node) => {
        if node.depth > max_depth {
          max_depth = node.depth
        }
        total_depth = total_depth + node.depth
      }
      None => ()
    }
  }
  let avg_depth = if total_nodes > 0 {
    total_depth.to_double() / total_nodes.to_double()
  } else {
    0.0
  }

  // 计算被依赖次数
  let dep_count : Map[String, Int] = Map([])
  for id in ids {
    match graph.get_node_by_id(id) {
      Some(node) =>
        dep_count[node.name] = (match dep_count.get(node.name) {
            Some(c) => c
            None => 0
          }) +
          node.parents.length()
      None => ()
    }
  }

  let mut most_depended = ""
  let mut most_depended_count = 0
  for pair in dep_count {
    let (name, count) = pair
    if count > most_depended_count {
      most_depended = name
      most_depended_count = count
    }
  }

  // 许可证分布
  let license_dist : Map[String, Int] = Map([])
  for pair in license_map {
    let (_, spdx) = pair
    license_dist[spdx] = match license_dist.get(spdx) {
      Some(c) => c + 1
      None => 1
    }
  }

  let cycle_detected = report.diagnostics
    .iter()
    .any(fn(d) { d.code == "CYCLE-001" })

  EcosystemReport::{
    total_packages: license_map.length(),
    total_nodes,
    max_depth,
    avg_depth,
    cycle_detected,
    most_depended,
    most_depended_count,
    license_distribution: license_dist,
    overall_health_score: report.overall_score,
  }
}

// ---------- 测试 ----------

///|
test "ecosystem sampling builds complete graph" {
  let registry = make_ecosystem_registry()
  let result = run_ecosystem_sampling("demo/app", "1.0.0", registry)

  match result {
    Ok((graph, report, eco)) => {
      inspect(graph.size(), content="10")
      inspect(report.node_count, content="10")
      inspect(eco.total_nodes, content="10")
      inspect(eco.total_packages, content="10")
      inspect(eco.overall_health_score, content="98")
      inspect(eco.cycle_detected, content="false")
    }
    Err(msg) => fail("Ecosystem sampling failed: " + msg)
  }
}

///|
test "ecosystem stats identify core as most depended" {
  let registry = make_ecosystem_registry()
  let result = run_ecosystem_sampling("demo/app", "1.0.0", registry)

  match result {
    Ok((_, _, eco)) => {
      inspect(eco.most_depended, content="moonbitlang/core")
      inspect(eco.most_depended_count > 0, content="true")
    }
    Err(msg) => fail("Ecosystem sampling failed: " + msg)
  }
}

///|
test "ecosystem depth stats are reasonable" {
  let registry = make_ecosystem_registry()
  let result = run_ecosystem_sampling("demo/app", "1.0.0", registry)

  match result {
    Ok((_, _, eco)) => {
      inspect(eco.max_depth >= 0, content="true")
      inspect(eco.avg_depth >= 0.0, content="true")
    }
    Err(msg) => fail("Ecosystem sampling failed: " + msg)
  }
}

///|
test "ecosystem license distribution includes MIT and Apache" {
  let registry = make_ecosystem_registry()
  let result = run_ecosystem_sampling("demo/app", "1.0.0", registry)

  match result {
    Ok((_, _, eco)) => {
      let has_mit = match eco.license_distribution.get("MIT") {
        Some(c) => c > 0
        None => false
      }
      let has_apache = match eco.license_distribution.get("Apache-2.0") {
        Some(c) => c > 0
        None => false
      }
      inspect(has_mit, content="true")
      inspect(has_apache, content="true")
    }
    Err(msg) => fail("Ecosystem sampling failed: " + msg)
  }
}

///|
test "ecosystem sampling on smaller root" {
  let registry = make_ecosystem_registry()
  let result = run_ecosystem_sampling("xinyu-lv/json5", "0.1.3", registry)

  match result {
    Ok((graph, _, eco)) => {
      inspect(graph.size(), content="3")
      inspect(eco.total_nodes, content="3")
    }
    Err(msg) => fail("Ecosystem sampling failed: " + msg)
  }
}

///|
test "ecosystem sampling detects artificial cycle" {
  let registry = make_ecosystem_registry()
  // 人为制造循环: json5 -> parser -> json5
  registry["xinyu-lv/json5@0.1.3"] = @parse.Module::new(
    "xinyu-lv/json5",
    "0.1.3",
    { "moonbitlang/core": "0.1.0", "peter-jerry-ye/parser-combinator": "0.9.1" },
  )
  registry["peter-jerry-ye/parser-combinator@0.9.1"] = @parse.Module::new(
    "peter-jerry-ye/parser-combinator",
    "0.9.1",
    { "moonbitlang/core": "0.1.0", "xinyu-lv/json5": "0.1.3" },
  )

  let result = run_ecosystem_sampling("xinyu-lv/json5", "0.1.3", registry)

  match result {
    Ok((_, report, eco)) => {
      inspect(eco.cycle_detected, content="true")
      assert_true(report.diagnostics.length() > 0)
    }
    Err(msg) => fail("Ecosystem sampling failed: " + msg)
  }
}
