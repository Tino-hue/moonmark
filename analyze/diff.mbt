///|
/// 报告差异结构
pub struct ReportDiff {
  added : Array[@report.Diagnostic]
  removed : Array[@report.Diagnostic]
  unchanged : Array[@report.Diagnostic]
  score_delta : Int
  node_count_delta : Int
}

///|
/// 构造 ReportDiff（用于测试）
pub fn ReportDiff::new(
  added? : Array[@report.Diagnostic] = [],
  removed? : Array[@report.Diagnostic] = [],
  unchanged? : Array[@report.Diagnostic] = [],
  score_delta? : Int = 0,
  node_count_delta? : Int = 0,
) -> ReportDiff {
  { added, removed, unchanged, score_delta, node_count_delta, }
}

///|
/// 比较两份分析报告，返回差异
pub fn diff_reports(
  current : AnalysisReport,
  baseline : AnalysisReport,
) -> ReportDiff {
  let current_map = diag_map(current.get_diagnostics())
  let baseline_map = diag_map(baseline.get_diagnostics())

  let added = []
  let removed = []
  let unchanged = []

  // 新增：current 里有但 baseline 里没有
  for pair in current_map {
    let (key, diag) = pair
    if baseline_map.get(key) is None {
      added.push(diag)
    } else {
      unchanged.push(diag)
    }
  }

  // 修复：baseline 里有但 current 里没有
  for pair in baseline_map {
    let (key, diag) = pair
    if current_map.get(key) is None {
      removed.push(diag)
    }
  }

  let score_delta = current.get_overall_score() - baseline.get_overall_score()
  let node_count_delta = current.get_node_count() - baseline.get_node_count()

  { added, removed, unchanged, score_delta, node_count_delta, }
}

///|
/// 用 code + path 作为诊断的唯一标识
fn diag_key(d : @report.Diagnostic) -> String {
  let buf = StringBuilder()
  buf.write_string(d.code)
  buf <+ "::"
  let mut first = true
  for p in d.path {
    if !first {
      buf <+ "->"
    }
    buf.write_string(p)
    first = false
  }
  buf.to_string()
}

///|
fn diag_map(
  diags : Array[@report.Diagnostic],
) -> Map[String, @report.Diagnostic] {
  let result : Map[String, @report.Diagnostic] = Map([])
  for d in diags {
    result[diag_key(d)] = d
  }
  result
}

///|
/// 渲染 diff 为终端可读格式
pub fn render_diff_terminal(diff : ReportDiff) -> String {
  let buf = StringBuilder()
  buf.write_string(bold("╔══ MoonBit Depsight Diff ══╗"))
  buf <+ "\n\n"

  // 分数变化
  let score_color = if diff.score_delta > 0 {
    green
  } else if diff.score_delta < 0 {
    red
  } else {
    dim
  }
  let score_sign = if diff.score_delta > 0 { "+" } else { "" }
  buf <+ "  Overall Score: "
  buf.write_string(score_color(score_sign + diff.score_delta.to_string()))
  buf <+ "\n"
  if diff.node_count_delta != 0 {
    let node_sign = if diff.node_count_delta > 0 { "+" } else { "" }
    buf <+ "  Node Count:    "
    buf.write_string(node_sign + diff.node_count_delta.to_string())
    buf <+ "\n"
  }
  buf <+ "\n"

  // 新增
  if diff.added.length() > 0 {
    buf.write_string(
      red(
        bold("  ── Added (" + diff.added.length().to_string() + ") ──"),
      ),
    )
    buf <+ "\n"
    for d in diff.added {
      buf.write_string(render_diff_item(d, "+"))
      buf <+ "\n"
    }
    buf <+ "\n"
  }

  // 修复
  if diff.removed.length() > 0 {
    buf.write_string(
      green(
        bold(
          "  ── Fixed (" + diff.removed.length().to_string() + ") ──",
        ),
      ),
    )
    buf <+ "\n"
    for d in diff.removed {
      buf.write_string(render_diff_item(d, "-"))
      buf <+ "\n"
    }
    buf <+ "\n"
  }

  // 不变
  if diff.unchanged.length() > 0 {
    buf.write_string(
      dim(
        bold(
          "  ── Unchanged (" +
          diff.unchanged.length().to_string() +
          ") ──",
        ),
      ),
    )
    buf <+ "\n"
    for d in diff.unchanged {
      buf.write_string(render_diff_item(d, " "))
      buf <+ "\n"
    }
    buf <+ "\n"
  }

  if diff.added.is_empty() && diff.removed.is_empty() {
    buf.write_string(green("  ✅ No changes since baseline."))
    buf <+ "\n\n"
  }

  buf.to_string()
}

///|
fn render_diff_item(d : @report.Diagnostic, marker : String) -> String {
  let level_tag = color_level(d.level)
  "  " + marker + " " + level_tag + " " + bold(d.code) + " — " + d.message
}
