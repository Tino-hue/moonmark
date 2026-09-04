/// 终端格式化报告渲染器
///
/// 生成 ANSI 彩色对齐表格、增强型依赖树、审计摘要。
/// 所有输出均为纯字符串，可直接打印到终端。

// ========== 公共入口 ==========

///|
/// 渲染完整的终端报告：概览 + 健康分表 + 诊断列表 + 依赖树 + Top 5 体积罪犯
pub fn render_terminal_report(
  report : AnalysisReport,
  graph : @graph.DependencyGraph,
  root_id : String,
) -> String {
  let buf = StringBuilder()

  // 标题
  buf.write_string(
    bold("╔══ MoonBit Depsight ── Dependency Health Report ══╗"),
  )
  buf <+ "\n\n"

  // 概览行
  let score_str = color_score(report.overall_score)
  buf <+ "  Nodes: "
  buf.write_string(report.node_count.to_string())
  buf <+ "   |   Overall: "
  buf.write_string(score_str)
  buf <+ "   |   Diagnostics: "
  buf.write_string(report.diagnostics.length().to_string())
  buf <+ "\n\n"

  // 健康分表格
  if report.health_scores.length() > 0 {
    render_score_table(report.health_scores, buf)
    buf <+ "\n"
  }

  // 诊断汇总
  if report.diagnostics.length() > 0 {
    render_diagnostics_table(report.diagnostics, buf)
    buf <+ "\n"
  } else {
    buf.write_string(dim("  ✅ No diagnostics — all clear."))
    buf <+ "\n\n"
  }

  // 依赖树
  buf.write_string(bold("─── Dependency Tree ───"))
  buf <+ "\n"
  let tree = graph.render_tree(root_id, 99)
  buf.write_string(tree)

  // Top 5 体积罪犯（F02：基于传递体积排序）
  if report.size_offenders_top5.length() > 0 {
    buf <+ "\n"
    render_top_size_offenders(report.size_offenders_top5, buf)
  }

  buf.to_string()
}

// ========== 健康分表格 ==========

///|
fn render_score_table(scores : Array[HealthScore], buf : StringBuilder) -> Unit {
  let col_node = 28
  let col_total = 10
  let col_fresh = 7
  let col_comply = 8
  let col_depd = 9
  let col_size = 7
  let col_actv = 7

  // 表头
  buf <+ "┌"
  buf.write_string(repeat_char("─", col_node))
  buf <+ "┬"
  buf.write_string(repeat_char("─", col_total))
  buf <+ "┬"
  buf.write_string(repeat_char("─", col_fresh))
  buf <+ "┬"
  buf.write_string(repeat_char("─", col_comply))
  buf <+ "┬"
  buf.write_string(repeat_char("─", col_depd))
  buf <+ "┬"
  buf.write_string(repeat_char("─", col_size))
  buf <+ "┬"
  buf.write_string(repeat_char("─", col_actv))
  buf <+ "┐\n"

  buf <+ "│"
  buf.write_string(bold(pad_center("Node ID", col_node)))
  buf <+ "│"
  buf.write_string(bold(pad_center("Score", col_total)))
  buf <+ "│"
  buf.write_string(bold(pad_center("Fresh", col_fresh)))
  buf <+ "│"
  buf.write_string(bold(pad_center("Comply", col_comply)))
  buf <+ "│"
  buf.write_string(bold(pad_center("DepDen", col_depd)))
  buf <+ "│"
  buf.write_string(bold(pad_center("Size", col_size)))
  buf <+ "│"
  buf.write_string(bold(pad_center("Actv", col_actv)))
  buf <+ "│\n"

  buf <+ "├"
  buf.write_string(repeat_char("─", col_node))
  buf <+ "┼"
  buf.write_string(repeat_char("─", col_total))
  buf <+ "┼"
  buf.write_string(repeat_char("─", col_fresh))
  buf <+ "┼"
  buf.write_string(repeat_char("─", col_comply))
  buf <+ "┼"
  buf.write_string(repeat_char("─", col_depd))
  buf <+ "┼"
  buf.write_string(repeat_char("─", col_size))
  buf <+ "┼"
  buf.write_string(repeat_char("─", col_actv))
  buf <+ "┤\n"

  // 数据行
  for s in scores {
    let node_display = truncate(s.node_id, col_node - 2)
    buf <+ "│"
    buf.write_string(pad_left(node_display, col_node))
    buf <+ "│"
    buf.write_string(pad_right(color_score(s.total), col_total))
    buf <+ "│"
    buf.write_string(pad_right(dim_cell(s.freshness), col_fresh))
    buf <+ "│"
    buf.write_string(pad_right(dim_cell(s.compliance), col_comply))
    buf <+ "│"
    buf.write_string(pad_right(dim_cell(s.deprecated_density), col_depd))
    buf <+ "│"
    buf.write_string(pad_right(dim_cell(s.size_reasonableness), col_size))
    buf <+ "│"
    buf.write_string(pad_right(dim_cell(s.activity), col_actv))
    buf <+ "│\n"
  }

  buf <+ "└"
  buf.write_string(repeat_char("─", col_node))
  buf <+ "┴"
  buf.write_string(repeat_char("─", col_total))
  buf <+ "┴"
  buf.write_string(repeat_char("─", col_fresh))
  buf <+ "┴"
  buf.write_string(repeat_char("─", col_comply))
  buf <+ "┴"
  buf.write_string(repeat_char("─", col_depd))
  buf <+ "┴"
  buf.write_string(repeat_char("─", col_size))
  buf <+ "┴"
  buf.write_string(repeat_char("─", col_actv))
  buf <+ "┘\n"
}

///|
/// 截断过长字符串并附加省略号
fn truncate(text : String, max_len : Int) -> String {
  if text.length() <= max_len {
    return text
  }
  substring(text, 0, max_len - 1) + "\u{2026}"
}

///|
/// 单元格数值显示（暗淡色）
fn dim_cell(score : Int) -> String {
  dim(score.to_string())
}

// ========== 诊断汇总表格 ==========

///|
fn render_diagnostics_table(
  diagnostics : Array[@report.Diagnostic],
  buf : StringBuilder,
) -> Unit {
  let col_level = 8
  let col_code = 12
  let col_msg = 50

  buf <+ "┌"
  buf.write_string(repeat_char("─", col_level))
  buf <+ "┬"
  buf.write_string(repeat_char("─", col_code))
  buf <+ "┬"
  buf.write_string(repeat_char("─", col_msg))
  buf <+ "┐\n"

  buf <+ "│"
  buf.write_string(bold(pad_center("Level", col_level)))
  buf <+ "│"
  buf.write_string(bold(pad_center("Code", col_code)))
  buf <+ "│"
  buf.write_string(bold(pad_center("Message", col_msg)))
  buf <+ "│\n"

  buf <+ "├"
  buf.write_string(repeat_char("─", col_level))
  buf <+ "┼"
  buf.write_string(repeat_char("─", col_code))
  buf <+ "┼"
  buf.write_string(repeat_char("─", col_msg))
  buf <+ "┤\n"

  let mut critical = 0
  let mut warning = 0
  let mut info = 0

  for d in diagnostics {
    // F04：两种废弃诊断的视觉差异化
    //   DEPRECATED-001（直接废弃）：黄底暗橙徽章「DIR-API」
    //   DEPRECATED-002（传递暴露）：红底暗玫徽章「PROP」
    let base_level = color_level(d.level)
    let level_label = if d.code == "DEPRECATED-001" {
      yellow("DIR-API")
    } else if d.code == "DEPRECATED-002" {
      red("PROP")
    } else {
      base_level
    }
    let msg_text = truncate(d.message, col_msg - 2)
    buf <+ "│"
    buf.write_string(pad_left(level_label, col_level))
    buf <+ "│"
    buf.write_string(pad_left(d.code, col_code))
    buf <+ "│"
    buf.write_string(pad_left(msg_text, col_msg))
    buf <+ "│\n"

    // F04：DEPRECATED-002 路径链单独在下一行展示，可一眼看出源头
    if d.code == "DEPRECATED-002" && d.path.length() > 0 {
      let chain = join_strings_with_arrow(d.path)
      buf <+ "│"
      buf.write_string(repeat_char(" ", col_level))
      buf <+ "│"
      buf.write_string(repeat_char(" ", col_code))
      buf <+ "│"
      buf.write_string(dim("  path: " + chain))
      // 尾部补齐宽度（含 "  path: " + chain）
      let padding_len = col_msg - 2 - ("  path: " + chain).length()
      if padding_len > 0 {
        buf.write_string(repeat_char(" ", padding_len))
      }
      buf <+ "│\n"
    }

    if d.is_critical() {
      critical = critical + 1
    } else if d.is_warning() {
      warning = warning + 1
    } else {
      info = info + 1
    }
  }

  buf <+ "└"
  buf.write_string(repeat_char("─", col_level))
  buf <+ "┴"
  buf.write_string(repeat_char("─", col_code))
  buf <+ "┴"
  buf.write_string(repeat_char("─", col_msg))
  buf <+ "┘\n\n"

  buf <+ "  Summary: "
  buf.write_string(red(critical.to_string()))
  buf <+ " critical, "
  buf.write_string(yellow(warning.to_string()))
  buf <+ " warnings, "
  buf.write_string(green(info.to_string()))
  buf <+ " info\n"
}

// ========== Top 5 体积罪犯（F02） ==========

///|
/// 把体积罪犯按三列表格渲染：Rank / Node / Self Size / Transitive Size
fn render_top_size_offenders(
  offenders : Array[SizeInfo],
  buf : StringBuilder,
) -> Unit {
  let col_rank = 6
  let col_node = 34
  let col_self = 14
  let col_trans = 14

  buf.write_string(
    bold("─── Top 5 Size Offenders (Transitive) ───"),
  )
  buf <+ "\n"

  buf <+ "┌"
  buf.write_string(repeat_char("─", col_rank))
  buf <+ "┬"
  buf.write_string(repeat_char("─", col_node))
  buf <+ "┬"
  buf.write_string(repeat_char("─", col_self))
  buf <+ "┬"
  buf.write_string(repeat_char("─", col_trans))
  buf <+ "┐\n"

  buf <+ "│"
  buf.write_string(bold(pad_center("Rank", col_rank)))
  buf <+ "│"
  buf.write_string(bold(pad_center("Node", col_node)))
  buf <+ "│"
  buf.write_string(bold(pad_center("Self", col_self)))
  buf <+ "│"
  buf.write_string(bold(pad_center("Transitive", col_trans)))
  buf <+ "│\n"

  buf <+ "├"
  buf.write_string(repeat_char("─", col_rank))
  buf <+ "┼"
  buf.write_string(repeat_char("─", col_node))
  buf <+ "┼"
  buf.write_string(repeat_char("─", col_self))
  buf <+ "┼"
  buf.write_string(repeat_char("─", col_trans))
  buf <+ "┤\n"

  let mut i = 0
  for info in offenders {
    let rank = (i + 1).to_string()
    let node_display = truncate(info.node_id, col_node - 2)
    let self_s = format_size(info.self_size)
    let trans_s = format_size(info.transitive_size)
    buf <+ "│"
    buf.write_string(pad_left(rank, col_rank))
    buf <+ "│"
    buf.write_string(pad_left(node_display, col_node))
    buf <+ "│"
    buf.write_string(pad_left(self_s, col_self))
    buf <+ "│"
    buf.write_string(pad_left(trans_s, col_trans))
    buf <+ "│\n"
    i = i + 1
  }

  buf <+ "└"
  buf.write_string(repeat_char("─", col_rank))
  buf <+ "┴"
  buf.write_string(repeat_char("─", col_node))
  buf <+ "┴"
  buf.write_string(repeat_char("─", col_self))
  buf <+ "┴"
  buf.write_string(repeat_char("─", col_trans))
  buf <+ "┘\n"
}

// ========== 辅助：字符串链拼接 ==========

///|
/// F04：把 [S, B, A] 拼成 "S ⇒ B ⇒ A"，用于废弃传播链展示
fn join_strings_with_arrow(arr : Array[String]) -> String {
  if arr.length() == 0 {
    return ""
  }
  let mut s = arr[0]
  let mut i = 1
  while i < arr.length() {
    s = s + " ⇒ " + arr[i]
    i = i + 1
  }
  s
}
