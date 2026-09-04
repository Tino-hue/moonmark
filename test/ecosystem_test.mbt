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
/// 生态采样报告（沿用旧字段名以兼容现有 6 个测试；内部复用新公共 F05 API）
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

  // 生态统计（复用 F05 公共 API，然后把字段名适配回旧 EcosystemReport）
  let root_id = root_name + "@" + root_version
  let stats = @analyze.calculate_ecosystem_stats(graph, report, metas, root_id)
  let eco = {
    total_packages: stats.total_unique_packages,
    total_nodes: stats.total_nodes,
    max_depth: stats.max_depth,
    avg_depth: stats.avg_depth,
    cycle_detected: stats.cycle_detected,
    most_depended: stats.most_depended_package,
    most_depended_count: stats.most_depended_count,
    license_distribution: stats.license_distribution,
    overall_health_score: stats.overall_health_score,
  }

  Ok((graph, report, eco))
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
      // F02 之前：meta.self_size 默认 0 被误当 <10KB → size_reasonableness=100 → 98
      // F02 之后：没有真实体积元数据时 transitive_size=None → size_reasonableness=80 → 每节点 -4，整体 → 94
      inspect(eco.overall_health_score, content="94")
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
