/// 将分析报告渲染为纯文本报告
pub fn render_report(report : AnalysisReport) -> String {
  let lines : Array[String] = []
  lines.push("MoonBit Depsight Analysis Report")
  lines.push("================================")
  lines.push("")
  lines.push("Summary: " + report.node_count.to_string() + " nodes analyzed")
  lines.push("Overall Health Score: " + report.overall_score.to_string() + "/100")
  lines.push("")

  // Health scores table
  if report.health_scores.length() > 0 {
    lines.push("Per-Node Health Scores")
    lines.push("----------------------")
    for s in report.health_scores {
      let bar = score_bar(s.total)
      lines.push(s.node_id + " | " + s.total.to_string() + "/100 " + bar)
    }
    lines.push("")
  }

  // Diagnostics
  if report.diagnostics.length() > 0 {
    lines.push("Diagnostics (" + report.diagnostics.length().to_string() + ")")
    lines.push("----------------------")
    let mut critical = 0
    let mut warning = 0
    let mut info = 0
    for d in report.diagnostics {
      lines.push(d.to_string())
      if d.is_critical() { critical = critical + 1 }
      else if d.is_warning() { warning = warning + 1 }
      else { info = info + 1 }
    }
    lines.push("")
    lines.push("Summary: " + critical.to_string() + " critical, " + warning.to_string() + " warnings, " + info.to_string() + " info")
  } else {
    lines.push("No diagnostics found.")
  }

  join_report_lines(lines)
}

// ---------- 内部辅助 ----------

fn score_bar(score : Int) -> String {
  if score >= 80 { return "[GREEN]" }
  if score >= 50 { return "[YELLOW]" }
  "[RED]"
}

fn join_report_lines(lines : Array[String]) -> String {
  let mut result = ""
  let mut i = 0
  while i < lines.length() {
    if i > 0 { result = result + "\n" }
    result = result + lines[i]
    i = i + 1
  }
  result
}
