///|
/// diff.mbt 单元测试
/// 覆盖：相同报告、新增、移除、同时增删、分数/节点变化、
/// 空基线、终端渲染、diag_key 多段路径、无变动提示

// ---------- 辅助构造 ----------

fn diag(code : String, message : String, path : Array[String]) -> @report.Diagnostic {
  // 用 warning 作为默认级别，不影响 diff 逻辑（diff 按 code+path 匹配，不按级别）
  @report.Diagnostic::warning(code, message, path)
}

fn make_report(diags : Array[@report.Diagnostic], score : Int, nodes : Int) -> AnalysisReport {
  AnalysisReport::new(diagnostics=diags, overall_score=score, node_count=nodes)
}

// ---------- 1. 完全相同的报告 → 全部不变 ----------

test "diff identical reports all unchanged" {
  let d = diag("LICENSE-001", "GPL-3.0", ["pkg@1.0.0"])
  let current = make_report([d], 80, 5)
  let baseline = make_report([d], 80, 5)
  let diff = diff_reports(current, baseline)

  inspect(diff.added.length(), content="0")
  inspect(diff.removed.length(), content="0")
  inspect(diff.unchanged.length(), content="1")
  inspect(diff.score_delta, content="0")
  inspect(diff.node_count_delta, content="0")
}

// ---------- 2. 新增 1 条诊断 ----------

test "diff added diagnostic" {
  let d1 = diag("LICENSE-001", "GPL", ["a@1.0.0"])
  let d2 = diag("DEPRECATED-001", "old_fn", ["b@1.0.0"])
  let current = make_report([d1, d2], 70, 5)
  let baseline = make_report([d1], 80, 5)
  let diff = diff_reports(current, baseline)

  inspect(diff.added.length(), content="1")
  inspect(diff.removed.length(), content="0")
  inspect(diff.unchanged.length(), content="1")
  // 分数下降：70 - 80 = -10
  inspect(diff.score_delta, content="-10")
}

// ---------- 3. 修复 1 条诊断 ----------

test "diff removed diagnostic (fixed)" {
  let d1 = diag("LICENSE-001", "GPL", ["a@1.0.0"])
  let current = make_report([], 95, 5)
  let baseline = make_report([d1], 70, 5)
  let diff = diff_reports(current, baseline)

  inspect(diff.added.length(), content="0")
  inspect(diff.removed.length(), content="1")
  inspect(diff.unchanged.length(), content="0")
  inspect(diff.score_delta, content="25") // 95 - 70
}

// ---------- 4. 同时新增 + 移除 ----------

test "diff both added and removed" {
  let d1 = diag("LICENSE-001", "GPL", ["a@1.0.0"])
  let d2 = diag("DEPRECATED-001", "old", ["b@1.0.0"])
  let d3 = diag("CYCLE-001", "cycle", ["c@1.0.0"])
  let current = make_report([d1, d2], 60, 6)
  let baseline = make_report([d1, d3], 75, 5)
  let diff = diff_reports(current, baseline)

  inspect(diff.added.length(), content="1")    // d2
  inspect(diff.removed.length(), content="1")  // d3
  inspect(diff.unchanged.length(), content="1") // d1
  inspect(diff.score_delta, content="-15")
  inspect(diff.node_count_delta, content="1")  // 6 - 5
}

// ---------- 5. diag_key 按 code + path 匹配，多段路径 ----------

test "diff matches by code plus multi-segment path" {
  // 同 code 但 path 不同 → 视为不同诊断
  let d1 = diag("DEPRECATED-002", "via dep", ["root@1.0.0", "mid@1.0.0", "lib@1.0.0"])
  let d2 = diag("DEPRECATED-002", "direct", ["root@1.0.0", "lib@1.0.0"])
  let current = make_report([d1, d2], 50, 4)
  let baseline = make_report([d1], 60, 3)
  let diff = diff_reports(current, baseline)

  // d1 不变，d2 是新增
  inspect(diff.added.length(), content="1")
  inspect(diff.unchanged.length(), content="1")
}

// ---------- 6. 空基线 vs 空当前 ----------

test "diff both empty reports" {
  let current = make_report([], 100, 0)
  let baseline = make_report([], 100, 0)
  let diff = diff_reports(current, baseline)

  inspect(diff.added.length(), content="0")
  inspect(diff.removed.length(), content="0")
  inspect(diff.unchanged.length(), content="0")
  inspect(diff.score_delta, content="0")
  inspect(diff.node_count_delta, content="0")
}

// ---------- 7. 终端渲染：新增区段 ----------

test "diff terminal render shows added section" {
  let d = diag("LICENSE-001", "GPL-3.0", ["pkg@1.0.0"])
  let current = make_report([d], 70, 3)
  let baseline = make_report([], 100, 2)
  let diff = diff_reports(current, baseline)
  let s = render_diff_terminal(diff)

  assert_true(s.contains("Added (1)"))
  assert_true(s.contains("LICENSE-001"))
  assert_true(s.contains("+")) // 新增标记
  assert_true(s.contains("-30")) // 分数下降 70-100=-30
  assert_true(s.contains("Node Count")) // 节点数变化了才显示
}

// ---------- 8. 终端渲染：修复区段 ----------

test "diff terminal render shows fixed section" {
  let d = diag("DEPRECATED-001", "old_fn", ["pkg@1.0.0"])
  let current = make_report([], 95, 3)
  let baseline = make_report([d], 70, 3)
  let diff = diff_reports(current, baseline)
  let s = render_diff_terminal(diff)

  assert_true(s.contains("Fixed (1)"))
  assert_true(s.contains("-")) // 修复标记
  assert_true(s.contains("+25")) // 分数上升 95-70=+25
}

// ---------- 9. 终端渲染：无变动时显示提示 ----------

test "diff terminal render no changes message" {
  let current = make_report([], 100, 5)
  let baseline = make_report([], 100, 5)
  let diff = diff_reports(current, baseline)
  let s = render_diff_terminal(diff)

  assert_true(s.contains("No changes since baseline"))
}

// ---------- 10. 节点数为 0 时不显示 Node Count 行 ----------

test "diff terminal render hides node count when zero" {
  let current = make_report([], 80, 5)
  let baseline = make_report([], 80, 5)
  let diff = diff_reports(current, baseline)
  let s = render_diff_terminal(diff)

  // 节点数没变化 → 不显示 Node Count 行
  assert_true(!s.contains("Node Count"))
  // 分数没变 → 显示 0（dim 颜色）
  assert_true(s.contains("Overall Score"))
}

// ---------- 11. 多个诊断的增删查全量场景 ----------

test "diff full scenario with mixed changes" {
  let a = diag("LICENSE-001", "GPL", ["a@1.0.0"])
  let b = diag("DEPRECATED-001", "old", ["b@1.0.0"])
  let c = diag("CYCLE-001", "cycle", ["c@1.0.0"])
  let d = diag("LICENSE-002", "missing", ["d@1.0.0"])

  let current = make_report([a, d], 65, 8)  // a 不变, d 新增, b 和 c 已修复
  let baseline = make_report([a, b, c], 50, 6) // a 不变, b 和 c 存在

  let diff = diff_reports(current, baseline)

  inspect(diff.added.length(), content="1")     // d
  inspect(diff.removed.length(), content="2")   // b, c
  inspect(diff.unchanged.length(), content="1") // a
  inspect(diff.score_delta, content="15")       // 65 - 50
  inspect(diff.node_count_delta, content="2")   // 8 - 6
}
