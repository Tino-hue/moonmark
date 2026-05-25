/// HTML 报告生成器
///
/// 生成单文件 HTML（内嵌 CSS），包含概览仪表盘、交互式依赖树（details+summary）、
/// 详细诊断列表。在浏览器中打开即可交互展开/折叠，无外部网络依赖。

// ========== 公共入口 ==========

/// 渲染完整的 HTML 报告
pub fn render_html_report(
  report : AnalysisReport,
  graph : @graph.DependencyGraph,
  root_id : String
) -> String {
  let html_parts : Array[String] = []
  html_parts.push("")
  html_parts.push("<!DOCTYPE html>")
  html_parts.push("<html lang=\"zh-CN\">")
  html_parts.push("<head>")
  html_parts.push("  <meta charset=\"UTF-8\">")
  html_parts.push("  <title>MoonBit Depsight Report</title>")
  html_parts.push("  <style>")
  html_parts.push(html_css())
  html_parts.push("  </style>")
  html_parts.push("</head>")
  html_parts.push("<body>")
  html_parts.push("  <div class=\"container\">")
  html_parts.push(html_header())
  html_parts.push(html_overview(report))
  html_parts.push(html_health_scores(report.health_scores))
  html_parts.push(html_diagnostics(report.diagnostics))
  html_parts.push(html_dependency_tree(graph, root_id))
  html_parts.push(html_footer())
  html_parts.push("  </div>")
  html_parts.push("</body>")
  html_parts.push("</html>")
  html_parts.push("")
  join_html_parts(html_parts)
}

// ========== HTML 区块 ==========

fn html_header() -> String {
  "<header class=\"header\"><h1>MoonBit Depsight</h1><p>Dependency Health Report</p></header>"
}

fn html_overview(report : AnalysisReport) -> String {
  let critical = count_level(report.diagnostics, @report.LEVEL_CRITICAL)
  let warning = count_level(report.diagnostics, @report.LEVEL_WARNING)
  let info = count_level(report.diagnostics, @report.LEVEL_INFO)

  let parts : Array[String] = []
  parts.push("<section class=\"overview\">")
  parts.push("<h2>Overview</h2>")
  parts.push("<div class=\"stats-grid\">")
  parts.push("<div class=\"stat-card\">")
  parts.push("<div class=\"stat-value\" id=\"overall-score\">" + report.overall_score.to_string() + "</div>")
  parts.push("<div class=\"stat-label\">Health Score</div>")
  parts.push("</div>")
  parts.push("<div class=\"stat-card\">")
  parts.push("<div class=\"stat-value\">" + report.node_count.to_string() + "</div>")
  parts.push("<div class=\"stat-label\">Nodes</div>")
  parts.push("</div>")
  parts.push("<div class=\"stat-card stat-critical\">")
  parts.push("<div class=\"stat-value\">" + critical.to_string() + "</div>")
  parts.push("<div class=\"stat-label\">Critical</div>")
  parts.push("</div>")
  parts.push("<div class=\"stat-card stat-warning\">")
  parts.push("<div class=\"stat-value\">" + warning.to_string() + "</div>")
  parts.push("<div class=\"stat-label\">Warnings</div>")
  parts.push("</div>")
  parts.push("<div class=\"stat-card stat-info\">")
  parts.push("<div class=\"stat-value\">" + info.to_string() + "</div>")
  parts.push("<div class=\"stat-label\">Info</div>")
  parts.push("</div>")
  parts.push("</div>")
  parts.push("</section>")
  join_html_parts(parts)
}

fn html_health_scores(scores : Array[HealthScore]) -> String {
  if scores.length() == 0 { return "" }
  let parts : Array[String] = []
  parts.push("<section class=\"health-scores\">")
  parts.push("<h2>Health Scores</h2>")
  parts.push("<table class=\"score-table\">")
  parts.push("<thead><tr><th>Node</th><th>Total</th><th>Fresh</th><th>Comply</th><th>DepDen</th><th>Size</th><th>Actv</th></tr></thead>")
  parts.push("<tbody>")
  for s in scores {
    let row_class = score_css_class(s.total)
    parts.push("<tr class=\"" + row_class + "\">")
    parts.push("<td>" + escape_html(s.node_id) + "</td>")
    parts.push("<td class=\"score-total\">" + s.total.to_string() + "</td>")
    parts.push("<td>" + s.freshness.to_string() + "</td>")
    parts.push("<td>" + s.compliance.to_string() + "</td>")
    parts.push("<td>" + s.deprecated_density.to_string() + "</td>")
    parts.push("<td>" + s.size_reasonableness.to_string() + "</td>")
    parts.push("<td>" + s.activity.to_string() + "</td>")
    parts.push("</tr>")
  }
  parts.push("</tbody>")
  parts.push("</table>")
  parts.push("</section>")
  join_html_parts(parts)
}

fn html_diagnostics(diagnostics : Array[@report.Diagnostic]) -> String {
  if diagnostics.length() == 0 {
    return "<section class=\"diagnostics\"><h2>Diagnostics</h2><p class=\"no-issues\">No issues found.</p></section>"
  }

  let parts : Array[String] = []
  parts.push("<section class=\"diagnostics\">")
  parts.push("<h2>Diagnostics</h2>")

  for d in diagnostics {
    let level_class = if d.is_critical() { "diag-critical" } else if d.is_warning() { "diag-warning" } else { "diag-info" }
    parts.push("<div class=\"diag-card " + level_class + "\">")
    parts.push("<div class=\"diag-header\">")
    parts.push("<span class=\"diag-level\">" + d.level + "</span>")
    parts.push("<span class=\"diag-code\">" + d.code + "</span>")
    parts.push("</div>")
    parts.push("<div class=\"diag-msg\">" + escape_html(d.message) + "</div>")

    if d.path.length() > 0 {
      parts.push("<div class=\"diag-path\">Path: " + escape_html(join_html_path(d.path)) + "</div>")
    }

    if d.suggestions.length() > 0 {
      parts.push("<div class=\"diag-suggestions\">")
      for s in d.suggestions {
        parts.push("<div class=\"suggestion\">→ " + escape_html(s) + "</div>")
      }
      parts.push("</div>")
    }

    parts.push("</div>")
  }

  parts.push("</section>")
  join_html_parts(parts)
}

fn html_dependency_tree(graph : @graph.DependencyGraph, root_id : String) -> String {
  let parts : Array[String] = []
  parts.push("<section class=\"dep-tree\">")
  parts.push("<h2>Dependency Tree</h2>")
  parts.push("<div class=\"tree-root\">")

  // 根节点标签
  let root_label = escape_html(root_id)
  let (root_name, root_ver) = split_at_id(root_id)
  let root_children = graph.get_children(root_name, root_ver)

  if root_children.length() > 0 {
    let child_parts : Array[String] = []
    for child in root_children {
      let child_html = html_tree_node(graph, child, 1)
      if child_html.length() > 0 {
        child_parts.push(child_html)
      }
    }
    parts.push("<details class=\"tree-branch\" open>")
    parts.push("<summary>" + root_label + "</summary>")
    parts.push("<div class=\"tree-children\">")
    for cp in child_parts { parts.push(cp) }
    parts.push("</div>")
    parts.push("</details>")
  } else {
    parts.push("<div class=\"tree-leaf\">" + root_label + "</div>")
  }

  parts.push("</div>")
  parts.push("</section>")
  join_html_parts(parts)
}

// 递归渲染树节点（用 details/summary 做折叠）
fn html_tree_node(graph : @graph.DependencyGraph, node_id : String, depth : Int) -> String {
  if depth >= 8 { return "" } // 限制递归深度
  let (name, ver) = split_at_id(node_id)
  let children = graph.get_children(name, ver)
  let has_children = children.length() > 0

  let label = escape_html(node_id)
  let margin = (depth * 20).to_string()

  if has_children {
    let child_parts : Array[String] = []
    for child in children {
      let child_html = html_tree_node(graph, child, depth + 1)
      if child_html.length() > 0 {
        child_parts.push(child_html)
      }
    }

    if child_parts.length() == 0 {
      return "<div class=\"tree-leaf\" style=\"margin-left:" + margin + "px\">" + label + "</div>"
    }

    let parts : Array[String] = []
    parts.push("<details class=\"tree-branch\" style=\"margin-left:" + margin + "px\">")
    parts.push("<summary>" + label + "</summary>")
    parts.push("<div class=\"tree-children\">")
    for cp in child_parts { parts.push(cp) }
    parts.push("</div>")
    parts.push("</details>")
    join_html_parts(parts)
  } else {
    "<div class=\"tree-leaf\" style=\"margin-left:" + margin + "px\">" + label + "</div>"
  }
}

fn html_footer() -> String {
  "<footer class=\"footer\"><p>Generated by MoonBit Depsight</p></footer>"
}

// ========== CSS ==========

fn html_css() -> String {
  let parts : Array[String] = []
  parts.push(":root{--bg:#0d1117;--fg:#c9d1d9;--card:#161b22;--border:#30363d;")
  parts.push("--green:#238636;--yellow:#d29922;--red:#da3633;--blue:#58a6ff;}")
  parts.push("body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;")
  parts.push("background:var(--bg);color:var(--fg);margin:0;padding:20px;}")
  parts.push(".container{max-width:900px;margin:0 auto;}")
  parts.push(".header{text-align:center;border-bottom:1px solid var(--border);padding-bottom:20px;margin-bottom:20px;}")
  parts.push(".header h1{margin:0;font-size:28px;}.header p{margin:6px 0 0;color:#8b949e;}")
  parts.push(".overview{margin-bottom:24px;}")
  parts.push(".stats-grid{display:grid;grid-template-columns:repeat(5,1fr);gap:12px;}")
  parts.push(".stat-card{background:var(--card);border:1px solid var(--border);border-radius:8px;padding:16px;text-align:center;}")
  parts.push(".stat-value{font-size:28px;font-weight:700;}.stat-label{font-size:12px;color:#8b949e;margin-top:4px;}")
  parts.push(".stat-critical .stat-value{color:var(--red);}.stat-warning .stat-value{color:var(--yellow);}.stat-info .stat-value{color:var(--green);}")
  parts.push(".score-good{color:var(--green);}.score-mid{color:var(--yellow);}.score-bad{color:var(--red);}")
  parts.push("#overall-score{color:var(--green);font-size:36px;}#overall-score.score-mid{color:var(--yellow);}#overall-score.score-bad{color:var(--red);}")
  parts.push(".score-table{width:100%;border-collapse:collapse;margin-top:12px;}")
  parts.push(".score-table th,.score-table td{padding:8px 12px;text-align:center;border:1px solid var(--border);}")
  parts.push(".score-table th{background:var(--card);font-weight:600;}.score-total{font-weight:700;font-size:16px;}")
  parts.push(".diagnostics{margin-top:24px;}")
  parts.push(".diag-card{background:var(--card);border:1px solid var(--border);border-radius:8px;padding:14px;margin-bottom:12px;border-left:4px solid var(--blue);}")
  parts.push(".diag-critical{border-left-color:var(--red);}.diag-warning{border-left-color:var(--yellow);}.diag-info{border-left-color:var(--green);}")
  parts.push(".diag-header{display:flex;gap:10px;align-items:center;margin-bottom:6px;}")
  parts.push(".diag-level{font-size:12px;font-weight:700;padding:2px 8px;border-radius:4px;background:var(--border);}")
  parts.push(".diag-critical .diag-level{background:var(--red);color:#fff;}.diag-warning .diag-level{background:var(--yellow);color:#000;}.diag-info .diag-level{background:var(--green);color:#fff;}")
  parts.push(".diag-code{font-family:monospace;color:var(--blue);font-size:13px;}.diag-msg{margin-bottom:6px;}")
  parts.push(".diag-path{font-size:13px;color:#8b949e;}.diag-suggestions{margin-top:8px;}")
  parts.push(".suggestion{font-size:13px;color:var(--blue);margin-top:2px;}.no-issues{color:var(--green);}")
  parts.push(".dep-tree{margin-top:24px;}")
  parts.push(".tree-root{background:var(--card);border:1px solid var(--border);border-radius:8px;padding:12px;}")
  parts.push(".tree-branch{margin:4px 0;}.tree-branch summary{cursor:pointer;font-family:monospace;padding:4px;border-radius:4px;}")
  parts.push(".tree-branch summary:hover{background:#21262d;}")
  parts.push(".tree-leaf{font-family:monospace;padding:4px 4px 4px 20px;color:#8b949e;}")
  parts.push(".footer{text-align:center;color:#8b949e;font-size:12px;margin-top:32px;padding-top:16px;border-top:1px solid var(--border);}")
  join_css_parts(parts)
}

fn join_css_parts(parts : Array[String]) -> String {
  let mut result = ""
  let mut i = 0
  while i < parts.length() {
    result = result + parts[i]
    i = i + 1
  }
  result
}

// ========== 工具函数 ==========

fn score_css_class(score : Int) -> String {
  if score >= 80 { "score-good" }
  else if score >= 50 { "score-mid" }
  else { "score-bad" }
}

/// 拆分 "name@version" 为 (name, version)
fn split_at_id(node_id : String) -> (String, String) {
  let mut i = 0
  while i < node_id.length() {
    if node_id[i] == '@' {
      return (node_id[:i].to_owned(), node_id[i + 1:].to_owned())
    }
    i = i + 1
  }
  (node_id, "")
}

fn count_level(diagnostics : Array[@report.Diagnostic], level : String) -> Int {
  let mut count = 0
  for d in diagnostics {
    if d.level == level { count = count + 1 }
  }
  count
}

fn escape_html(s : String) -> String {
  escape_html_loop(s, 0, [])
}

fn escape_html_loop(s : String, idx : Int, acc : Array[String]) -> String {
  if idx >= s.length() { return join_html_parts(acc) }
  let ch = s[idx]
  if ch == '&' { acc.push("&amp;") }
  else if ch == '<' { acc.push("&lt;") }
  else if ch == '>' { acc.push("&gt;") }
  else if ch == '"' { acc.push("&quot;") }
  else { acc.push(char_to_html_string(ch)) }
  escape_html_loop(s, idx + 1, acc)
}

fn char_to_html_string(ch : UInt16) -> String {
  let c = ch.to_int().unsafe_to_char()
  let arr : Array[String] = [c.to_string()]
  join_html_parts(arr)
}

fn join_html_path(path : Array[String]) -> String {
  let mut result = ""
  let mut i = 0
  while i < path.length() {
    if i > 0 { result = result + " -> " }
    result = result + path[i]
    i = i + 1
  }
  result
}

fn join_html_parts(parts : Array[String]) -> String {
  let mut result = ""
  let mut i = 0
  while i < parts.length() {
    result = result + parts[i]
    if i < parts.length() - 1 { result = result + "\n" }
    i = i + 1
  }
  result
}
