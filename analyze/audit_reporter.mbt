/// 审计摘要报告渲染器
///
/// 类似 npm audit 的格式化输出：按风险等级分组、每条诊断含修复建议、底部汇总。
/// 支持 ANSI 终端输出和 JSON 输出两种模式。

// ========== 公共入口 ==========

///|
/// 渲染终端审计报告（带 ANSI 颜色）
pub fn render_audit_report(report : AnalysisReport) -> String {
  let buf = StringBuilder()

  // 标题
  buf.write_string(bold("╔══ MoonBit Depsight Audit ══╗"))
  buf <+ "\n\n"

  // 分组诊断
  let criticals : Array[@report.Diagnostic] = []
  let warnings : Array[@report.Diagnostic] = []
  let infos : Array[@report.Diagnostic] = []

  for d in report.diagnostics {
    if d.is_critical() {
      criticals.push(d)
    } else if d.is_warning() {
      warnings.push(d)
    } else {
      infos.push(d)
    }
  }

  // Critical 组
  if criticals.length() > 0 {
    buf.write_string(red(bold("  ── Critical ──")))
    buf <+ "\n"
    for d in criticals {
      render_audit_item(d, buf)
      buf <+ "\n\n"
    }
  }

  // Warning 组
  if warnings.length() > 0 {
    buf.write_string(yellow(bold("  ── Warning ──")))
    buf <+ "\n"
    for d in warnings {
      render_audit_item(d, buf)
      buf <+ "\n\n"
    }
  }

  // Info 组
  if infos.length() > 0 {
    buf.write_string(green(bold("  ── Info ──")))
    buf <+ "\n"
    for d in infos {
      render_audit_item(d, buf)
      buf <+ "\n\n"
    }
  }

  // 无诊断
  if report.diagnostics.length() == 0 {
    buf.write_string(
      green("  ✅ No issues found. All dependencies look healthy."),
    )
    buf <+ "\n\n"
  }

  // 汇总行
  let crit_str = red(criticals.length().to_string() + " critical")
  let warn_str = yellow(warnings.length().to_string() + " warnings")
  let info_str = green(infos.length().to_string() + " info")
  buf.write_string(bold("─── Summary ───"))
  buf <+ "\n  "
  buf.write_string(crit_str)
  buf <+ ", "
  buf.write_string(warn_str)
  buf <+ ", "
  buf.write_string(info_str)
  buf <+ "\n"
  buf <+ "  Health Score: "
  buf.write_string(color_score(report.overall_score))

  buf.to_string()
}

///|
/// 渲染 JSON 审计报告（供 CI 消费）
pub fn render_audit_json(report : AnalysisReport) -> String {
  let buf = StringBuilder()
  buf <+ "{\"overall_score\":"
  buf.write_string(report.overall_score.to_string())
  buf <+ ",\"node_count\":"
  buf.write_string(report.node_count.to_string())
  buf <+ ",\"diagnostics\":["

  let mut i = 0
  for d in report.diagnostics {
    if i > 0 {
      buf <+ ","
    }
    buf.write_string(d.to_json_string())
    i = i + 1
  }

  buf <+ "],\"health_scores\":["

  let mut j = 0
  for s in report.health_scores {
    if j > 0 {
      buf <+ ","
    }
    health_score_to_json(s, buf)
    j = j + 1
  }

  let crit_count = count_by_level(report.diagnostics, @report.level_critical())
  let warn_count = count_by_level(report.diagnostics, @report.level_warning())
  let info_count = count_by_level(report.diagnostics, @report.level_info())
  buf <+ "],\"summary\":{\"critical\":"
  buf.write_string(crit_count.to_string())
  buf <+ ",\"warning\":"
  buf.write_string(warn_count.to_string())
  buf <+ ",\"info\":"
  buf.write_string(info_count.to_string())
  buf <+ "}}"

  buf.to_string()
}

// ========== 内部辅助 ==========

///|
/// 渲染单条审计项（含修复建议），直接写入 buf
fn render_audit_item(d : @report.Diagnostic, buf : StringBuilder) -> Unit {
  let level_tag = color_level(d.level)
  buf <+ "  "
  buf.write_string(level_tag)
  buf <+ " "
  buf.write_string(bold(d.code))
  buf <+ " — "
  buf.write_string(d.message)

  // 路径信息
  if d.path.length() > 0 {
    buf <+ "\n    Path: "
    buf.write_string(join_path(d.path))
  }

  // 修复建议
  if d.suggestions.length() > 0 {
    let mut k = 0
    while k < d.suggestions.length() {
      buf <+ "\n    "
      buf.write_string(dim("→ " + d.suggestions[k]))
      k = k + 1
    }
  }
}

///|
/// 拼接路径（用 -> 连接）
fn join_path(path : Array[String]) -> String {
  let mut result = ""
  let mut i = 0
  while i < path.length() {
    if i > 0 {
      result = result + " -> "
    }
    result = result + path[i]
    i = i + 1
  }
  result
}

///|
/// 统计指定级别的诊断数量
fn count_by_level(
  diagnostics : Array[@report.Diagnostic],
  level : String,
) -> Int {
  let mut count = 0
  for d in diagnostics {
    if d.level == level {
      count = count + 1
    }
  }
  count
}

///|
/// 将 HealthScore 写入 buf
fn health_score_to_json(s : HealthScore, buf : StringBuilder) -> Unit {
  buf <+ "{\"node_id\":\""
  buf.write_string(s.node_id)
  buf <+ "\",\"total\":"
  buf.write_string(s.total.to_string())
  buf <+ ",\"freshness\":"
  buf.write_string(s.freshness.to_string())
  buf <+ ",\"compliance\":"
  buf.write_string(s.compliance.to_string())
  buf <+ ",\"deprecated_density\":"
  buf.write_string(s.deprecated_density.to_string())
  buf <+ ",\"size_reasonableness\":"
  buf.write_string(s.size_reasonableness.to_string())
  buf <+ ",\"activity\":"
  buf.write_string(s.activity.to_string())
  buf <+ "}"
}

///|
/// 从 JSON 字符串解析 Audit 报告（用于 --baseline diff）
pub fn parse_audit_json(content : String) -> Result[AnalysisReport, String] {
  let json = @json.parse(content) catch {
    _ => return Err("Invalid JSON format")
  }
  guard json is Object(obj) else { return Err("Expected JSON object at root") }

  let overall_score = match obj.get("overall_score") {
    Some(Number(n, ..)) => n.to_int()
    _ => 0
  }
  let node_count = match obj.get("node_count") {
    Some(Number(n, ..)) => n.to_int()
    _ => 0
  }

  let diagnostics = match obj.get("diagnostics") {
    Some(Array(arr)) => {
      let result = []
      for item in arr {
        guard item is Object(dobj) else { continue }
        let level = match dobj.get("level") {
          Some(String(s)) => s
          _ => continue
        }
        let code = match dobj.get("code") {
          Some(String(s)) => s
          _ => continue
        }
        let message = match dobj.get("message") {
          Some(String(s)) => s
          _ => continue
        }
        let path = match dobj.get("path") {
          Some(Array(parr)) => {
            let pr = []
            for p in parr {
              guard p is String(ps) else { continue }
              pr.push(ps)
            }
            pr
          }
          _ => []
        }
        let suggestions = match dobj.get("suggestions") {
          Some(Array(sarr)) => {
            let sr = []
            for s in sarr {
              guard s is String(ss) else { continue }
              sr.push(ss)
            }
            sr
          }
          _ => []
        }
        result.push(
          @report.Diagnostic::new(level, code, message, path, suggestions),
        )
      }
      result
    }
    _ => []
  }

  Ok(AnalysisReport::new(diagnostics~, overall_score~, node_count~))
}
