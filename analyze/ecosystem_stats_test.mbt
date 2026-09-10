///|
/// EcosystemStats 单元测试
/// 覆盖：空图、链式图、菱形图、健康分分段、许可证分布、
/// JSON 渲染、format_double_1 边界、json_escape 特殊字符

// ---------- 辅助：构造最小的图 + 报告 + metas ----------

fn make_empty_report() -> AnalysisReport {
  AnalysisReport::new()
}

// ---------- 1. 空图零值 ----------

///|
test "ecosystem_stats empty graph yields all zeros" {
  let graph = @graph.DependencyGraph::new()
  let metas : Map[String, NodeMeta] = Map([])
  let report = make_empty_report()
  let stats = calculate_ecosystem_stats(graph, report, metas, "")
  inspect(stats.total_nodes, content="0")
  inspect(stats.total_unique_packages, content="0")
  inspect(stats.total_edges, content="0")
  inspect(stats.max_depth, content="0")
  // 空图 avg_depth 为 0.0（通过 JSON 渲染验证格式）
  let json_empty = render_ecosystem_stats_json(stats)
  assert_true(json_empty.contains("\"avg_depth\":0.0"))
  inspect(stats.leaf_package_count, content="0")
  inspect(stats.cycle_detected, content="false")
  inspect(stats.overall_health_score, content="100")
  inspect(stats.average_node_score, content="0")
  inspect(stats.deprecated_source_packages, content="0")
  inspect(stats.total_transitive_size_bytes, content="0")
  inspect(stats.license_species, content="0")
}

// ---------- 2. 链式图 root -> a -> b ----------

///|
test "ecosystem_stats chain graph 3 nodes depth 2" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)
  graph.add_node("a", "1.0.0", 1)
  graph.add_node("b", "1.0.0", 2)
  graph.add_edge("root", "1.0.0", "a", "1.0.0")
  graph.add_edge("a", "1.0.0", "b", "1.0.0")

  let metas : Map[String, NodeMeta] = Map([])
  let report = make_empty_report()
  let stats = calculate_ecosystem_stats(graph, report, metas, "root@1.0.0")

  inspect(stats.total_nodes, content="3")
  inspect(stats.total_unique_packages, content="3")
  inspect(stats.total_edges, content="2")
  inspect(stats.max_depth, content="2")
  // avg_depth 通过 JSON 渲染来验证（确保 format_double_1 的 1 位小数格式）
  let json = render_ecosystem_stats_json(stats)
  assert_true(json.contains("\"avg_depth\":1.0"))
  inspect(stats.leaf_package_count, content="1") // b 是叶子
  inspect(stats.root_id, content="root@1.0.0")
  // most-depended: b 入度 1, a 入度 1, root 入度 0 → 最先遇到的是 a 或 b
  inspect(stats.most_depended_count >= 1, content="true")
}

// ---------- 3. 菱形图：root -> a, root -> b, a -> c, b -> c ----------

///|
test "ecosystem_stats diamond graph most-depended by in-degree" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)
  graph.add_node("a", "1.0.0", 1)
  graph.add_node("b", "1.0.0", 1)
  graph.add_node("c", "1.0.0", 2)
  graph.add_edge("root", "1.0.0", "a", "1.0.0")
  graph.add_edge("root", "1.0.0", "b", "1.0.0")
  graph.add_edge("a", "1.0.0", "c", "1.0.0")
  graph.add_edge("b", "1.0.0", "c", "1.0.0")

  let metas : Map[String, NodeMeta] = Map([])
  let report = make_empty_report()
  let stats = calculate_ecosystem_stats(graph, report, metas, "root@1.0.0")

  inspect(stats.total_nodes, content="4")
  inspect(stats.total_edges, content="4")
  inspect(stats.max_depth, content="2")
  inspect(stats.leaf_package_count, content="1") // c
  // c 被 a 和 b 同时依赖 → 入度 2，最多
  inspect(stats.most_depended_package, content="c")
  inspect(stats.most_depended_count, content="2")
}

// ---------- 4. 同名不同版本的去重 ----------

///|
test "ecosystem_stats same name different versions dedup" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)
  graph.add_node("lib", "1.0.0", 1)
  graph.add_node("lib", "2.0.0", 1)
  graph.add_edge("root", "1.0.0", "lib", "1.0.0")
  graph.add_edge("root", "1.0.0", "lib", "2.0.0")

  let metas : Map[String, NodeMeta] = Map([])
  let report = make_empty_report()
  let stats = calculate_ecosystem_stats(graph, report, metas, "root@1.0.0")

  inspect(stats.total_nodes, content="3") // 3 个 name@version 节点
  inspect(stats.total_unique_packages, content="2") // root + lib
}

// ---------- 5. 健康分分段计数 ----------

///|
test "ecosystem_stats health score buckets" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("a", "1.0.0", 0)
  graph.add_node("b", "1.0.0", 0)
  graph.add_node("c", "1.0.0", 0)
  graph.add_node("d", "1.0.0", 0)
  graph.add_node("e", "1.0.0", 0)

  let scores : Array[HealthScore] = [
    HealthScore::new("a@1.0.0", 95), // ≥85 安全
    HealthScore::new("b@1.0.0", 84), // 70-84 警戒
    HealthScore::new("c@1.0.0", 70), // 70-84 警戒（边界）
    HealthScore::new("d@1.0.0", 69), // <70 风险（边界）
    HealthScore::new("e@1.0.0", 50), // <70 风险
  ]
  let report = AnalysisReport::new(health_scores=scores, overall_score=80)

  let metas : Map[String, NodeMeta] = Map([])
  let stats = calculate_ecosystem_stats(graph, report, metas, "a@1.0.0")

  inspect(stats.overall_health_score, content="80")
  // avg = (95+84+70+69+50)/5 = 368/5 = 73
  inspect(stats.average_node_score, content="73")
  inspect(stats.nodes_at_risk_below_70, content="2") // d + e
  inspect(stats.nodes_warning_70_85, content="2") // b + c
}

// ---------- 6. 许可证分布 ----------

///|
test "ecosystem_stats license distribution and unknown" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("mit-pkg", "1.0.0", 0)
  graph.add_node("apache-pkg", "1.0.0", 0)
  graph.add_node("unknown-pkg", "1.0.0", 0)
  graph.add_node("no-meta-pkg", "1.0.0", 0)

  let metas : Map[String, NodeMeta] = {
    "mit-pkg@1.0.0": NodeMeta::new(license=Some("MIT")),
    "apache-pkg@1.0.0": NodeMeta::new(license=Some("Apache-2.0")),
    "unknown-pkg@1.0.0": NodeMeta::new(license=None),
    // no-meta-pkg 完全没有 meta 条目 → 应记为 Unknown
  }

  let report = make_empty_report()
  let stats = calculate_ecosystem_stats(graph, report, metas, "mit-pkg@1.0.0")

  inspect(stats.license_species, content="3") // MIT + Apache-2.0 + Unknown
  // Unknown 应该有 2 个（unknown-pkg 的 None + no-meta-pkg 的缺失）
  match stats.license_distribution.get("Unknown") {
    Some(n) => inspect(n, content="2")
    None => inspect(0, content="2") // 触发失败
  }
  match stats.license_distribution.get("MIT") {
    Some(n) => inspect(n, content="1")
    None => inspect(0, content="1")
  }
}

// ---------- 7. 诊断分级计数 ----------

///|
test "ecosystem_stats diagnostic level counting" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)

  let diagnostics : Array[@report.Diagnostic] = [
    @report.Diagnostic::critical("CYCLE-001", "root@1.0.0", ["cycle"]),
    @report.Diagnostic::warning("LICENSE-001", "root@1.0.0", ["GPL"]),
    @report.Diagnostic::warning("DEPRECATED-001", "root@1.0.0", ["old"]),
    @report.Diagnostic::info("LICENSE-002", "root@1.0.0", ["missing"]),
  ]
  let report = AnalysisReport::new(diagnostics~)

  let metas : Map[String, NodeMeta] = Map([])
  let stats = calculate_ecosystem_stats(graph, report, metas, "root@1.0.0")

  inspect(stats.diagnostics_critical, content="1")
  inspect(stats.diagnostics_warning, content="2")
  inspect(stats.diagnostics_info, content="1")
  inspect(stats.cycle_detected, content="true")
}

// ---------- 8. JSON 渲染包含所有关键字段 ----------

///|
test "ecosystem_stats json render has key fields" {
  let stats = EcosystemStats::new(
    total_nodes=5,
    total_unique_packages=3,
    total_edges=4,
    max_depth=2,
    avg_depth=1.5,
    overall_health_score=88,
    root_id="root@1.0.0",
    license_species=2,
    cycle_detected=true,
  )
  let json = render_ecosystem_stats_json(stats)
  assert_true(json.has_prefix("{"))
  assert_true(json.has_suffix("}"))
  assert_true(json.contains("\"total_nodes\":5"))
  assert_true(json.contains("\"total_unique_packages\":3"))
  assert_true(json.contains("\"total_edges\":4"))
  assert_true(json.contains("\"max_depth\":2"))
  assert_true(json.contains("\"avg_depth\":1.5"))
  assert_true(json.contains("\"cycle_detected\":true"))
  assert_true(json.contains("\"root_id\":\"root@1.0.0\""))
  assert_true(json.contains("\"overall_health_score\":88"))
  assert_true(json.contains("\"license_species\":2"))
}

// ---------- 9. format_double_1 边界值 ----------

// 私有函数通过集成方式间接测：构造 avg_depth 场景

///|
test "ecosystem_stats avg_depth rounding half up" {
  let graph = @graph.DependencyGraph::new()
  // 5 个节点，深度和 = 7 → 7/5 = 1.4
  graph.add_node("a", "1.0.0", 0)
  graph.add_node("b", "1.0.0", 1)
  graph.add_node("c", "1.0.0", 1)
  graph.add_node("d", "1.0.0", 2)
  graph.add_node("e", "1.0.0", 3)
  // total_depth = 0+1+1+2+3 = 7
  // avg = 7/5 = 1.4

  let metas : Map[String, NodeMeta] = Map([])
  let report = make_empty_report()
  let stats = calculate_ecosystem_stats(graph, report, metas, "a@1.0.0")

  // 验证 JSON 里的 avg_depth 字段正确格式化
  let json = render_ecosystem_stats_json(stats)
  assert_true(json.contains("\"avg_depth\":1.4"))
}

// ---------- 10. json_escape 特殊字符 ----------

///|
test "ecosystem_stats json escapes special chars in root_id" {
  let stats = EcosystemStats::new(
    root_id="test\"quote\\backslash\nnewline\ttab",
    total_nodes=1,
  )
  let json = render_ecosystem_stats_json(stats)
  assert_true(json.contains("test\\\"quote"))
  assert_true(json.contains("\\\\backslash"))
  assert_true(json.contains("\\nnewline"))
  assert_true(json.contains("\\ttab"))
}

// ---------- 11. 终端渲染包含表头和表尾 ----------

///|
test "ecosystem_stats terminal render has table frame" {
  let stats = EcosystemStats::new(
    total_nodes=1,
    total_unique_packages=1,
    root_id="root@1.0.0",
  )
  let s = render_ecosystem_stats_terminal(stats)
  assert_true(s.contains("Ecosystem Stats"))
  assert_true(s.contains("Overview"))
  assert_true(s.contains("Graph"))
  assert_true(s.contains("Health"))
  assert_true(s.contains("Total nodes"))
  assert_true(s.contains("Overall health score"))
  assert_true(s.contains("└")) // 表尾
}
