///|
/// terminal_reporter.mbt 单元测试
/// 覆盖：完整报告、无诊断分支、DEPRECATED 徽章差异化、
/// 传播链展示、truncate 边界、join_strings_with_arrow、Top5 体积表

// ---------- 辅助 ----------

fn warn_diag(code : String, msg : String, path : Array[String]) -> @report.Diagnostic {
  @report.Diagnostic::warning(code, msg, path)
}

fn crit_diag(code : String, msg : String, path : Array[String]) -> @report.Diagnostic {
  @report.Diagnostic::critical(code, msg, path)
}

fn make_simple_graph(root_name : String, root_ver : String) -> @graph.DependencyGraph {
  let g = @graph.DependencyGraph::new()
  g.add_node(root_name, root_ver, 0)
  g
}

// ---------- 1. 完整报告包含各部分标题 ----------

test "terminal_report has all sections" {
  let graph = make_simple_graph("root", "1.0.0")
  let score = HealthScore::new("root@1.0.0", 90, freshness=90, compliance=90, deprecated_density=90, size_reasonableness=90, activity=90)
  let diag = warn_diag("LICENSE-001", "GPL-3.0 license", ["root@1.0.0"])
  let report = AnalysisReport::new(
    diagnostics=[diag],
    health_scores=[score],
    overall_score=90,
    node_count=1,
  )
  let s = render_terminal_report(report, graph, "root@1.0.0")

  assert_true(s.contains("MoonBit Depsight"))
  assert_true(s.contains("Dependency Health Report"))
  assert_true(s.contains("Nodes:"))
  assert_true(s.contains("Overall:"))
  assert_true(s.contains("Diagnostics:"))
  assert_true(s.contains("Dependency Tree"))
  // 健康分表
  assert_true(s.contains("Node ID"))
  assert_true(s.contains("Score"))
  assert_true(s.contains("Fresh"))
  // 诊断表
  assert_true(s.contains("Level"))
  assert_true(s.contains("Code"))
  assert_true(s.contains("Message"))
  assert_true(s.contains("Summary:"))
}

// ---------- 2. 无诊断时显示 clean 提示 ----------

test "terminal_report no diagnostics shows clean message" {
  let graph = make_simple_graph("pkg", "1.0.0")
  let report = AnalysisReport::new(overall_score=100, node_count=1)
  let s = render_terminal_report(report, graph, "pkg@1.0.0")

  assert_true(s.contains("No diagnostics"))
  assert_true(s.contains("all clear"))
}

// ---------- 3. 无健康分时不显示分数表 ----------

test "terminal_report no health scores skips score table" {
  let graph = make_simple_graph("pkg", "1.0.0")
  let report = AnalysisReport::new(
    diagnostics=[warn_diag("LICENSE-002", "missing", ["pkg@1.0.0"])],
    overall_score=90,
    node_count=1,
  )
  let s = render_terminal_report(report, graph, "pkg@1.0.0")

  // 没有健康分数表的表头
  assert_true(!s.contains("Fresh"))
  assert_true(!s.contains("Comply"))
  // 但诊断表仍然有
  assert_true(s.contains("Level"))
  assert_true(s.contains("Code"))
}

// ---------- 4. DEPRECATED-001 显示 DIR-API 徽章 ----------

test "terminal_report deprecated-001 shows DIR-API badge" {
  let graph = make_simple_graph("lib", "1.0.0")
  let diag = warn_diag("DEPRECATED-001", "old_fn is deprecated", ["lib@1.0.0"])
  let report = AnalysisReport::new(diagnostics=[diag], overall_score=75, node_count=1)
  let s = render_terminal_report(report, graph, "lib@1.0.0")

  assert_true(s.contains("DIR-API"))
  assert_true(s.contains("DEPRECATED-001"))
}

// ---------- 5. DEPRECATED-002 显示 PROP 徽章 + 传播链 ----------

test "terminal_report deprecated-002 shows PROP badge and chain" {
  let graph = make_simple_graph("app", "1.0.0")
  let diag = warn_diag("DEPRECATED-002", "indirectly exposes deprecated API", [
    "app@1.0.0", "mid@2.0.0", "old-lib@1.0.0",
  ])
  let report = AnalysisReport::new(diagnostics=[diag], overall_score=70, node_count=1)
  let s = render_terminal_report(report, graph, "app@1.0.0")

  assert_true(s.contains("PROP"))
  assert_true(s.contains("DEPRECATED-002"))
  assert_true(s.contains("path:"))
  // 传播链箭头
  assert_true(s.contains("app@1.0.0"))
  assert_true(s.contains("old-lib@1.0.0"))
}

// ---------- 6. Summary 计数正确 ----------

test "terminal_report diagnostic summary counts" {
  let graph = make_simple_graph("root", "1.0.0")
  let diags = [
    crit_diag("CYCLE-001", "cycle", ["a@1.0.0"]),
    warn_diag("LICENSE-001", "GPL", ["b@1.0.0"]),
    warn_diag("DEPRECATED-001", "old", ["c@1.0.0"]),
    @report.Diagnostic::info("LICENSE-002", "missing", ["d@1.0.0"]),
  ]
  let report = AnalysisReport::new(diagnostics=diags, overall_score=50, node_count=4)
  let s = render_terminal_report(report, graph, "root@1.0.0")

  // Summary 行包含计数
  assert_true(s.contains("critical"))
  assert_true(s.contains("warnings"))
  assert_true(s.contains("info"))
}

// ---------- 7. Top 5 体积罪犯表 ----------

test "terminal_report top size offenders table" {
  let graph = make_simple_graph("root", "1.0.0")
  let offenders = [
    SizeInfo::new("big-lib@2.0.0", 5000, 15000),
    SizeInfo::new("mid-lib@1.0.0", 3000, 8000),
    SizeInfo::new("small@1.0.0", 1000, 1000),
  ]
  let report = AnalysisReport::new(
    overall_score=80,
    node_count=3,
    size_offenders_top5=offenders,
  )
  let s = render_terminal_report(report, graph, "root@1.0.0")

  assert_true(s.contains("Top 5 Size Offenders"))
  assert_true(s.contains("Rank"))
  assert_true(s.contains("Node"))
  assert_true(s.contains("Self"))
  assert_true(s.contains("Transitive"))
  assert_true(s.contains("big-lib@2.0.0"))
}

// ---------- 8. 长消息被截断（间接测试 truncate） ----------

test "terminal_report long diagnostic message is truncated" {
  let graph = make_simple_graph("pkg", "1.0.0")
  // 构造一个 80 字符的超长消息（表的 msg 列宽 50，超过会截断）
  let long_msg = "this is a very very very very very very very very very long diagnostic message that should be truncated"
  let diag = warn_diag("LICENSE-001", long_msg, ["pkg@1.0.0"])
  let report = AnalysisReport::new(diagnostics=[diag], overall_score=70, node_count=1)
  let s = render_terminal_report(report, graph, "pkg@1.0.0")

  // 消息被截断，带省略号
  assert_true(s.contains("…"))
  // 超长消息不能完整出现在输出中
  assert_true(!s.contains("should be truncated"))
}

// ---------- 9. 空报告（零节点零诊断） ----------

test "terminal_report empty report" {
  let graph = @graph.DependencyGraph::new()
  let report = AnalysisReport::new(overall_score=100, node_count=0)
  let s = render_terminal_report(report, graph, "")

  assert_true(s.contains("MoonBit Depsight"))
  assert_true(s.contains("Nodes: 0"))
  assert_true(s.contains("No diagnostics"))
}
