///|
/// markdown_reporter.mbt 单元测试
/// 覆盖：概览表、健康分表、三级诊断分组、无诊断提示、
/// 依赖树代码块、suggestions 子列表、节点截断、页脚

// ---------- 辅助 ----------

fn warn(code : String, msg : String) -> @report.Diagnostic {
  @report.Diagnostic::warning(code, msg, ["pkg@1.0.0"])
}

fn crit(code : String, msg : String) -> @report.Diagnostic {
  @report.Diagnostic::critical(code, msg, ["pkg@1.0.0"])
}

fn info(code : String, msg : String) -> @report.Diagnostic {
  @report.Diagnostic::info(code, msg, ["pkg@1.0.0"])
}

fn make_graph(name : String, ver : String) -> @graph.DependencyGraph {
  let g = @graph.DependencyGraph::new()
  g.add_node(name, ver, 0)
  g
}

// ---------- 1. 概览表包含关键指标 ----------

test "markdown_report overview table has key metrics" {
  let graph = make_graph("root", "1.0.0")
  let diags = [
    crit("CYCLE-001", "circular dependency"),
    warn("LICENSE-001", "GPL-3.0"),
    warn("DEPRECATED-001", "old fn"),
    info("LICENSE-002", "missing license"),
  ]
  let report = AnalysisReport::new(diagnostics=diags, overall_score=65, node_count=5)
  let s = render_markdown_report(report, graph, "root@1.0.0")

  assert_true(s.has_prefix("# MoonBit Depsight Report"))
  assert_true(s.contains("## Overview"))
  assert_true(s.contains("| Health Score | **65**/100 |"))
  assert_true(s.contains("| Total Nodes | 5 |"))
  assert_true(s.contains("| Critical | 1 |"))
  assert_true(s.contains("| Warning | 2 |"))
  assert_true(s.contains("| Info | 1 |"))
}

// ---------- 2. 健康分表 ----------

test "markdown_report health scores table" {
  let graph = make_graph("root", "1.0.0")
  let scores = [
    HealthScore::new("root@1.0.0", 90, freshness=95, compliance=100, deprecated_density=85, size_reasonableness=80, activity=90),
    HealthScore::new("lib@1.0.0", 70, freshness=60, compliance=100, deprecated_density=65, size_reasonableness=75, activity=50),
  ]
  let report = AnalysisReport::new(health_scores=scores, overall_score=80, node_count=2)
  let s = render_markdown_report(report, graph, "root@1.0.0")

  assert_true(s.contains("## Health Scores"))
  assert_true(s.contains("| Node | Total | Fresh | Comply | DepDen | Size | Actv |"))
  assert_true(s.contains("| root@1.0.0 | 90 | 95 | 100 | 85 | 80 | 90 |"))
  assert_true(s.contains("| lib@1.0.0 | 70 | 60 | 100 | 65 | 75 | 50 |"))
}

// ---------- 3. 无健康分时不显示 Health Scores 节 ----------

test "markdown_report no health scores skips section" {
  let graph = make_graph("root", "1.0.0")
  let report = AnalysisReport::new(overall_score=85, node_count=1)
  let s = render_markdown_report(report, graph, "root@1.0.0")

  assert_true(!s.contains("## Health Scores"))
}

// ---------- 4. 诊断分三级显示 ----------

test "markdown_report diagnostics grouped by level" {
  let graph = make_graph("root", "1.0.0")
  let diags = [
    crit("CYCLE-001", "a cycle"),
    warn("LICENSE-001", "GPL"),
    info("LICENSE-002", "missing"),
  ]
  let report = AnalysisReport::new(diagnostics=diags, overall_score=50, node_count=3)
  let s = render_markdown_report(report, graph, "root@1.0.0")

  assert_true(s.contains("## Diagnostics"))
  assert_true(s.contains("### Critical"))
  assert_true(s.contains("### Warning"))
  assert_true(s.contains("### Info"))
  assert_true(s.contains("**CYCLE-001**"))
  assert_true(s.contains("**LICENSE-001**"))
  assert_true(s.contains("**LICENSE-002**"))
}

// ---------- 5. 只有 Critical 时不显示 Warning/Info 节 ----------

test "markdown_report only critical hides other sections" {
  let graph = make_graph("root", "1.0.0")
  let diags = [crit("CYCLE-001", "cycle")]
  let report = AnalysisReport::new(diagnostics=diags, overall_score=30, node_count=2)
  let s = render_markdown_report(report, graph, "root@1.0.0")

  assert_true(s.contains("### Critical"))
  assert_true(!s.contains("### Warning"))
  assert_true(!s.contains("### Info"))
}

// ---------- 6. 无诊断时显示 No issues found ----------

test "markdown_report no diagnostics shows clean" {
  let graph = make_graph("root", "1.0.0")
  let report = AnalysisReport::new(overall_score=100, node_count=1)
  let s = render_markdown_report(report, graph, "root@1.0.0")

  assert_true(s.contains("## Diagnostics"))
  assert_true(s.contains("No issues found."))
  assert_true(!s.contains("### Critical"))
  assert_true(!s.contains("### Warning"))
  assert_true(!s.contains("### Info"))
}

// ---------- 7. 诊断带 suggestions ----------

test "markdown_report diagnostic with suggestions" {
  let graph = make_graph("root", "1.0.0")
  let d = warn("LICENSE-001", "GPL")
    .with_suggestion("Replace with MIT-licensed alternative")
    .with_suggestion("Add license exception");
  let report = AnalysisReport::new(diagnostics=[d], overall_score=70, node_count=1)
  let s = render_markdown_report(report, graph, "root@1.0.0")

  assert_true(s.contains("Replace with MIT-licensed alternative"))
  assert_true(s.contains("Add license exception"))
  // suggestions 是子列表（缩进）
  assert_true(s.contains("  - Replace with MIT-licensed alternative"))
}

// ---------- 8. 依赖树在代码块内 ----------

test "markdown_report dependency tree in code block" {
  let graph = make_graph("my-app", "2.0.0")
  let report = AnalysisReport::new(overall_score=95, node_count=1)
  let s = render_markdown_report(report, graph, "my-app@2.0.0")

  assert_true(s.contains("## Dependency Tree"))
  assert_true(s.contains("```"))
  assert_true(s.contains("my-app@2.0.0"))
}

// ---------- 9. 长 node_id 被截断为最后一段（md_truncate_node_id 间接测） ----------

test "markdown_report long node_id truncated to last segment" {
  let graph = make_graph("root", "1.0.0")
  // 构造一个超长 node_id（>30 字符，含 /）
  let long_id = "very-long-organization-name/very-long-package-name@1.0.0"
  let scores = [HealthScore::new(long_id, 80)]
  let report = AnalysisReport::new(health_scores=scores, overall_score=85, node_count=1)
  let s = render_markdown_report(report, graph, "root@1.0.0")

  // 应该被截断为包名的最后一段（@version 之前？不，找的是最后一个 /）
  // 即 "very-long-package-name@1.0.0"
  assert_true(s.contains("very-long-package-name@1.0.0"))
  // 不会完整显示超长的 organization 部分
  assert_true(!s.contains("very-long-organization-name/very-long-package-name@1.0.0"))
}

// ---------- 10. 短 node_id 保持原样 ----------

test "markdown_report short node_id unchanged" {
  let graph = make_graph("root", "1.0.0")
  let scores = [HealthScore::new("short@1.0.0", 90)]
  let report = AnalysisReport::new(health_scores=scores, overall_score=90, node_count=1)
  let s = render_markdown_report(report, graph, "root@1.0.0")

  assert_true(s.contains("| short@1.0.0 | 90 |"))
}

// ---------- 11. 页脚存在 ----------

test "markdown_report has footer" {
  let graph = make_graph("root", "1.0.0")
  let report = AnalysisReport::new(overall_score=100, node_count=1)
  let s = render_markdown_report(report, graph, "root@1.0.0")

  assert_true(s.contains("---"))
  assert_true(s.contains("Generated by MoonBit Depsight"))
}
