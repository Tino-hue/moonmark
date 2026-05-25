/// 审计摘要报告渲染器
///
/// 类似 npm audit 的格式化输出：按风险等级分组、每条诊断含修复建议、底部汇总。
/// 支持 ANSI 终端输出和 JSON 输出两种模式。

// ========== 公共入口 ==========

/// 渲染终端审计报告（带 ANSI 颜色）
pub fn render_audit_report(report : AnalysisReport) -> String {
  let lines : Array[String] = []

  // 标题
  lines.push(bold("╔══ MoonBit Depsight Audit ══╗"))
  lines.push("")

  // 分组诊断
  let criticals : Array[@report.Diagnostic] = []
  let warnings : Array[@report.Diagnostic] = []
  let infos : Array[@report.Diagnostic] = []

  for d in report.diagnostics {
    if d.is_critical() { criticals.push(d) }
    else if d.is_warning() { warnings.push(d) }
    else { infos.push(d) }
  }

  // Critical 组
  if criticals.length() > 0 {
    lines.push(red(bold("  ── Critical ──")))
    for d in criticals {
      lines.push(render_audit_item(d))
      lines.push("")
    }
  }

  // Warning 组
  if warnings.length() > 0 {
    lines.push(yellow(bold("  ── Warning ──")))
    for d in warnings {
      lines.push(render_audit_item(d))
      lines.push("")
    }
  }

  // Info 组
  if infos.length() > 0 {
    lines.push(green(bold("  ── Info ──")))
    for d in infos {
      lines.push(render_audit_item(d))
      lines.push("")
    }
  }

  // 无诊断
  if report.diagnostics.length() == 0 {
    lines.push(green("  ✅ No issues found. All dependencies look healthy."))
    lines.push("")
  }

  // 汇总行（颜色包裹整个短语，确保 contains 可匹配）
  let crit_str = red(criticals.length().to_string() + " critical")
  let warn_str = yellow(warnings.length().to_string() + " warnings")
  let info_str = green(infos.length().to_string() + " info")
  let summary = "  " + crit_str + ", " + warn_str + ", " + info_str
  lines.push(bold("─── Summary ───"))
  lines.push(summary)
  lines.push("  Health Score: " + color_score(report.overall_score))

  join_audit_lines(lines)
}

/// 渲染 JSON 审计报告（供 CI 消费）
pub fn render_audit_json(report : AnalysisReport) -> String {
  let parts : Array[String] = []
  parts.push("{\"overall_score\":")
  parts.push(report.overall_score.to_string())
  parts.push(",\"node_count\":")
  parts.push(report.node_count.to_string())
  parts.push(",\"diagnostics\":[")

  let mut i = 0
  for d in report.diagnostics {
    if i > 0 { parts.push(",") }
    parts.push(d.to_json_string())
    i = i + 1
  }

  parts.push("],\"health_scores\":[")

  let mut j = 0
  for s in report.health_scores {
    if j > 0 { parts.push(",") }
    parts.push(health_score_to_json(s))
    j = j + 1
  }

  parts.push("],\"summary\":{\"critical\":")
  parts.push(count_by_level(report.diagnostics, @report.LEVEL_CRITICAL).to_string())
  parts.push(",\"warning\":")
  parts.push(count_by_level(report.diagnostics, @report.LEVEL_WARNING).to_string())
  parts.push(",\"info\":")
  parts.push(count_by_level(report.diagnostics, @report.LEVEL_INFO).to_string())
  parts.push("}}")

  join_audit_parts(parts)
}

// ========== 内部辅助 ==========

/// 渲染单条审计项（含修复建议）
fn render_audit_item(d : @report.Diagnostic) -> String {
  let level_tag = color_level(d.level)
  let header = "  " + level_tag + " " + bold(d.code) + " — " + d.message
  let mut result = header

  // 路径信息
  if d.path.length() > 0 {
    result = result + "\n    Path: " + join_path(d.path)
  }

  // 修复建议
  if d.suggestions.length() > 0 {
    let mut k = 0
    while k < d.suggestions.length() {
      result = result + "\n    " + dim("→ " + d.suggestions[k])
      k = k + 1
    }
  }

  result
}

/// 拼接路径（用 -> 连接）
fn join_path(path : Array[String]) -> String {
  let mut result = ""
  let mut i = 0
  while i < path.length() {
    if i > 0 { result = result + " -> " }
    result = result + path[i]
    i = i + 1
  }
  result
}

/// 统计指定级别的诊断数量
fn count_by_level(diagnostics : Array[@report.Diagnostic], level : String) -> Int {
  let mut count = 0
  for d in diagnostics {
    if d.level == level { count = count + 1 }
  }
  count
}

/// 将 HealthScore 转为 JSON
fn health_score_to_json(s : HealthScore) -> String {
  "{\"node_id\":\"" + s.node_id + "\",\"total\":" + s.total.to_string() + ",\"freshness\":" + s.freshness.to_string() + ",\"compliance\":" + s.compliance.to_string() + ",\"deprecated_density\":" + s.deprecated_density.to_string() + ",\"size_reasonableness\":" + s.size_reasonableness.to_string() + ",\"activity\":" + s.activity.to_string() + "}"
}

/// 拼接审计报告行
fn join_audit_lines(lines : Array[String]) -> String {
  let mut result = ""
  let mut i = 0
  while i < lines.length() {
    if i > 0 { result = result + "\n" }
    result = result + lines[i]
    i = i + 1
  }
  result
}

/// 拼接 JSON 片段
fn join_audit_parts(parts : Array[String]) -> String {
  let mut result = ""
  let mut i = 0
  while i < parts.length() {
    result = result + parts[i]
    i = i + 1
  }
  result
}
