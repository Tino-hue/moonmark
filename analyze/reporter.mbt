///|
/// 将分析报告渲染为纯文本报告
pub fn render_report(report : AnalysisReport) -> String {
  let buf = StringBuilder()
  buf <+ "MoonBit Depsight Analysis Report\n"
  buf <+ "================================\n\n"
  buf <+ "Summary: "
  buf.write_string(report.node_count.to_string())
  buf <+ " nodes analyzed\n"
  buf <+ "Overall Health Score: "
  buf.write_string(report.overall_score.to_string())
  buf <+ "/100\n\n"

  // Health scores table
  if report.health_scores.length() > 0 {
    buf <+ "Per-Node Health Scores\n"
    buf <+ "----------------------\n"
    for s in report.health_scores {
      let bar = score_bar(s.total)
      buf.write_string(s.node_id)
      buf <+ " | "
      buf.write_string(s.total.to_string())
      buf <+ "/100 "
      buf.write_string(bar)
      buf <+ "\n"
    }
    buf <+ "\n"
  }

  // Diagnostics
  if report.diagnostics.length() > 0 {
    buf <+ "Diagnostics ("
    buf.write_string(report.diagnostics.length().to_string())
    buf <+ ")\n"
    buf <+ "----------------------\n"
    let mut critical = 0
    let mut warning = 0
    let mut info = 0
    for d in report.diagnostics {
      buf.write_string(d.to_string())
      buf <+ "\n"
      if d.is_critical() {
        critical = critical + 1
      } else if d.is_warning() {
        warning = warning + 1
      } else {
        info = info + 1
      }
    }
    buf <+ "\nSummary: "
    buf.write_string(critical.to_string())
    buf <+ " critical, "
    buf.write_string(warning.to_string())
    buf <+ " warnings, "
    buf.write_string(info.to_string())
    buf <+ " info"
  } else {
    buf <+ "No diagnostics found."
  }

  buf.to_string()
}

// ---------- 内部辅助 ----------

///|
fn score_bar(score : Int) -> String {
  if score >= 80 {
    return "[GREEN]"
  }
  if score >= 50 {
    return "[YELLOW]"
  }
  "[RED]"
}
