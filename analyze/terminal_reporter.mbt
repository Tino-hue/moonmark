/// 终端格式化报告渲染器
///
/// 生成 ANSI 彩色对齐表格、增强型依赖树、审计摘要。
/// 所有输出均为纯字符串，可直接打印到终端。

// ========== 公共入口 ==========

/// 渲染完整的终端报告：概览 + 健康分表 + 诊断列表 + 依赖树
pub fn render_terminal_report(
  report : AnalysisReport,
  graph : @graph.DependencyGraph,
  root_id : String,
) -> String {
  let lines : Array[String] = []

  // 标题
  lines.push(bold("╔══ MoonBit Depsight ── Dependency Health Report ══╗"))
  lines.push("")

  // 概览行（单行拼接）
  let score_str = color_score(report.overall_score)
  let overview = "  Nodes: " + report.node_count.to_string() + "   |   Overall: " + score_str + "   |   Diagnostics: " + report.diagnostics.length().to_string()
  lines.push(overview)
  lines.push("")

  // 健康分表格
  if report.health_scores.length() > 0 {
    let table = render_score_table(report.health_scores)
    for row in table {
      lines.push(row)
    }
    lines.push("")
  }

  // 诊断汇总
  if report.diagnostics.length() > 0 {
    let diag_section = render_diagnostics_table(report.diagnostics)
    for row in diag_section {
      lines.push(row)
    }
    lines.push("")
  } else {
    lines.push(dim("  ✅ No diagnostics — all clear."))
    lines.push("")
  }

  // 依赖树
  lines.push(bold("─── Dependency Tree ───"))
  let tree = graph.render_tree(root_id, 99)
  lines.push(tree)

  join_term_lines(lines)
}

// ========== 健康分表格 ==========

fn render_score_table(scores : Array[HealthScore]) -> Array[String] {
  let result = []
  let col_node = 28
  let col_total = 10
  let col_fresh = 7
  let col_comply = 8
  let col_depd = 9
  let col_size = 7
  let col_actv = 7

  // 表头 — 全部单行拼接
  let top_border = "┌" + repeat_char("─", col_node) + "┬" + repeat_char("─", col_total) + "┬" + repeat_char("─", col_fresh) + "┬" + repeat_char("─", col_comply) + "┬" + repeat_char("─", col_depd) + "┬" + repeat_char("─", col_size) + "┬" + repeat_char("─", col_actv) + "┐"
  result.push(top_border)

  let header = "│" + bold(pad_center("Node ID", col_node)) + "│" + bold(pad_center("Score", col_total)) + "│" + bold(pad_center("Fresh", col_fresh)) + "│" + bold(pad_center("Comply", col_comply)) + "│" + bold(pad_center("DepDen", col_depd)) + "│" + bold(pad_center("Size", col_size)) + "│" + bold(pad_center("Actv", col_actv)) + "│"
  result.push(header)

  let sep_line = "├" + repeat_char("─", col_node) + "┼" + repeat_char("─", col_total) + "┼" + repeat_char("─", col_fresh) + "┼" + repeat_char("─", col_comply) + "┼" + repeat_char("─", col_depd) + "┼" + repeat_char("─", col_size) + "┼" + repeat_char("─", col_actv) + "┤"
  result.push(sep_line)

  // 数据行
  for s in scores {
    let node_display = truncate(s.node_id, col_node - 2)
    let row = "│" + pad_left(node_display, col_node) + "│" + pad_right(color_score(s.total), col_total) + "│" + pad_right(dim_cell(s.freshness), col_fresh) + "│" + pad_right(dim_cell(s.compliance), col_comply) + "│" + pad_right(dim_cell(s.deprecated_density), col_depd) + "│" + pad_right(dim_cell(s.size_reasonableness), col_size) + "│" + pad_right(dim_cell(s.activity), col_actv) + "│"
    result.push(row)
  }

  let bottom = "└" + repeat_char("─", col_node) + "┴" + repeat_char("─", col_total) + "┴" + repeat_char("─", col_fresh) + "┴" + repeat_char("─", col_comply) + "┴" + repeat_char("─", col_depd) + "┴" + repeat_char("─", col_size) + "┴" + repeat_char("─", col_actv) + "┘"
  result.push(bottom)
  result
}

/// 截断过长字符串并附加省略号
fn truncate(text : String, max_len : Int) -> String {
  if text.length() <= max_len { return text }
  substring(text, 0, max_len - 1) + "\u{2026}"
}

/// 单元格数值显示（暗淡色）
fn dim_cell(score : Int) -> String {
  dim(score.to_string())
}

// ========== 诊断汇总表格 ==========

fn render_diagnostics_table(diagnostics : Array[@report.Diagnostic]) -> Array[String] {
  let result = []
  let col_level = 8
  let col_code = 12
  let col_msg = 50

  let top = "┌" + repeat_char("─", col_level) + "┬" + repeat_char("─", col_code) + "┬" + repeat_char("─", col_msg) + "┐"
  result.push(top)

  let hdr = "│" + bold(pad_center("Level", col_level)) + "│" + bold(pad_center("Code", col_code)) + "│" + bold(pad_center("Message", col_msg)) + "│"
  result.push(hdr)

  let sep = "├" + repeat_char("─", col_level) + "┼" + repeat_char("─", col_code) + "┼" + repeat_char("─", col_msg) + "┤"
  result.push(sep)

  let mut critical = 0
  let mut warning = 0
  let mut info = 0

  for d in diagnostics {
    let level_label = color_level(d.level)
    let msg_text = truncate(d.message, col_msg - 2)
    let row = "│" + pad_left(level_label, col_level) + "│" + pad_left(d.code, col_code) + "│" + pad_left(msg_text, col_msg) + "│"
    result.push(row)

    if d.is_critical() { critical = critical + 1 }
    else if d.is_warning() { warning = warning + 1 }
    else { info = info + 1 }
  }

  let bot = "└" + repeat_char("─", col_level) + "┴" + repeat_char("─", col_code) + "┴" + repeat_char("─", col_msg) + "┘"
  result.push(bot)
  result.push("")
  let summary = "  Summary: " + red(critical.to_string()) + " critical, " + yellow(warning.to_string()) + " warnings, " + green(info.to_string()) + " info"
  result.push(summary)
  result
}

// ========== 内部辅助 ==========

fn join_term_lines(lines : Array[String]) -> String {
  let mut result = ""
  let mut i = 0
  while i < lines.length() {
    if i > 0 { result = result + "\n" }
    result = result + lines[i]
    i = i + 1
  }
  result
}
