///|
/// reporter.mbt 单元测试
/// 覆盖：报告标题、Summary 指标、健康分表、score_bar 三档、
/// 诊断列表与计数、无诊断提示

// ---------- 辅助 ----------

fn rpt_warn(code : String, msg : String) -> @report.Diagnostic {
  @report.Diagnostic::warning(code, msg, ["pkg@1.0.0"])
}

///|
fn rpt_crit(code : String, msg : String) -> @report.Diagnostic {
  @report.Diagnostic::critical(code, msg, ["pkg@1.0.0"])
}

///|
fn rpt_info(code : String, msg : String) -> @report.Diagnostic {
  @report.Diagnostic::info(code, msg, ["pkg@1.0.0"])
}

// ---------- 1. 报告标题与 Summary 指标 ----------

///|
test "reporter has title and summary metrics" {
  let report = AnalysisReport::new(overall_score=75, node_count=10)
  let s = render_report(report)

  assert_true(s.has_prefix("MoonBit Depsight Analysis Report"))
  assert_true(s.contains("Summary: 10 nodes analyzed"))
  assert_true(s.contains("Overall Health Score: 75/100"))
}

// ---------- 2. 健康分表存在且包含各节点 ----------

///|
test "reporter health scores table" {
  let scores = [
    HealthScore::new("root@1.0.0", 90),
    HealthScore::new("lib@2.0.0", 65),
  ]
  let report = AnalysisReport::new(
    health_scores=scores,
    overall_score=80,
    node_count=2,
  )
  let s = render_report(report)

  assert_true(s.contains("Per-Node Health Scores"))
  assert_true(s.contains("root@1.0.0 | 90/100"))
  assert_true(s.contains("lib@2.0.0 | 65/100"))
}

// ---------- 3. 无健康分时不显示健康分节 ----------

///|
test "reporter no health scores skips section" {
  let report = AnalysisReport::new(overall_score=85, node_count=1)
  let s = render_report(report)

  assert_true(!s.contains("Per-Node Health Scores"))
}

// ---------- 4. score_bar: 高分 GREEN ----------

///|
test "reporter score_bar green for high score" {
  let scores = [HealthScore::new("pkg@1.0.0", 95)]
  let report = AnalysisReport::new(
    health_scores=scores,
    overall_score=95,
    node_count=1,
  )
  let s = render_report(report)

  assert_true(s.contains("[GREEN]"))
  assert_true(!s.contains("[YELLOW]"))
  assert_true(!s.contains("[RED]"))
}

// ---------- 5. score_bar: 中等分 YELLOW ----------

///|
test "reporter score_bar yellow for medium score" {
  let scores = [HealthScore::new("pkg@1.0.0", 60)]
  let report = AnalysisReport::new(
    health_scores=scores,
    overall_score=60,
    node_count=1,
  )
  let s = render_report(report)

  assert_true(s.contains("[YELLOW]"))
  assert_true(!s.contains("[GREEN]"))
  assert_true(!s.contains("[RED]"))
}

// ---------- 6. score_bar: 低分 RED ----------

///|
test "reporter score_bar red for low score" {
  let scores = [HealthScore::new("pkg@1.0.0", 30)]
  let report = AnalysisReport::new(
    health_scores=scores,
    overall_score=30,
    node_count=1,
  )
  let s = render_report(report)

  assert_true(s.contains("[RED]"))
  assert_true(!s.contains("[GREEN]"))
  assert_true(!s.contains("[YELLOW]"))
}

// ---------- 7. score_bar 边界：80 分正好 GREEN ----------

///|
test "reporter score_bar boundary 80 is green" {
  let scores = [HealthScore::new("pkg@1.0.0", 80)]
  let report = AnalysisReport::new(
    health_scores=scores,
    overall_score=80,
    node_count=1,
  )
  let s = render_report(report)

  assert_true(s.contains("[GREEN]"))
}

// ---------- 8. score_bar 边界：50 分正好 YELLOW ----------

///|
test "reporter score_bar boundary 50 is yellow" {
  let scores = [HealthScore::new("pkg@1.0.0", 50)]
  let report = AnalysisReport::new(
    health_scores=scores,
    overall_score=50,
    node_count=1,
  )
  let s = render_report(report)

  assert_true(s.contains("[YELLOW]"))
}

// ---------- 9. score_bar 边界：49 分为 RED ----------

///|
test "reporter score_bar boundary 49 is red" {
  let scores = [HealthScore::new("pkg@1.0.0", 49)]
  let report = AnalysisReport::new(
    health_scores=scores,
    overall_score=49,
    node_count=1,
  )
  let s = render_report(report)

  assert_true(s.contains("[RED]"))
}

// ---------- 10. 诊断列表显示并带计数汇总 ----------

///|
test "reporter diagnostics list and summary counts" {
  let diags = [
    rpt_crit("CYCLE-001", "circular dependency"),
    rpt_warn("LICENSE-001", "GPL-3.0"),
    rpt_warn("DEPRECATED-001", "old fn"),
    rpt_info("LICENSE-002", "missing license"),
  ]
  let report = AnalysisReport::new(
    diagnostics=diags,
    overall_score=50,
    node_count=4,
  )
  let s = render_report(report)

  assert_true(s.contains("Diagnostics (4)"))
  assert_true(s.contains("CYCLE-001"))
  assert_true(s.contains("LICENSE-001"))
  assert_true(s.contains("DEPRECATED-001"))
  assert_true(s.contains("LICENSE-002"))
  // Summary 计数
  assert_true(s.contains("Summary: 1 critical, 2 warnings, 1 info"))
}

// ---------- 11. 无诊断时显示 No diagnostics found ----------

///|
test "reporter no diagnostics shows clean message" {
  let report = AnalysisReport::new(overall_score=100, node_count=1)
  let s = render_report(report)

  assert_true(s.contains("No diagnostics found."))
  assert_true(!s.contains("Diagnostics ("))
}

// ---------- 12. 全 Critical 诊断 ----------

///|
test "reporter all critical diagnostics" {
  let diags = [
    rpt_crit("CYCLE-001", "cycle a"),
    rpt_crit("CYCLE-001", "cycle b"),
  ]
  let report = AnalysisReport::new(
    diagnostics=diags,
    overall_score=20,
    node_count=2,
  )
  let s = render_report(report)

  assert_true(s.contains("Summary: 2 critical, 0 warnings, 0 info"))
}

// ---------- 13. 全 Info 诊断 ----------

///|
test "reporter all info diagnostics" {
  let diags = [
    rpt_info("LICENSE-002", "missing a"),
    rpt_info("LICENSE-002", "missing b"),
    rpt_info("LICENSE-002", "missing c"),
  ]
  let report = AnalysisReport::new(
    diagnostics=diags,
    overall_score=90,
    node_count=3,
  )
  let s = render_report(report)

  assert_true(s.contains("Summary: 0 critical, 0 warnings, 3 info"))
}
