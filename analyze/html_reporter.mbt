/// HTML 报告生成器
///
/// 生成单文件 HTML（内嵌 CSS），包含概览仪表盘、交互式依赖树（details+summary）、
/// 详细诊断列表。在浏览器中打开即可交互展开/折叠，无外部网络依赖。

// ========== 公共入口 ==========

///|
/// 渲染完整的 HTML 报告
pub fn render_html_report(
  report : AnalysisReport,
  graph : @graph.DependencyGraph,
  root_id : String,
) -> String {
  let buf = StringBuilder()
  buf <+ "\n<!DOCTYPE html>\n"
  buf <+ "<html lang=\"zh-CN\">\n"
  buf <+ "<head>\n"
  buf <+ "  <meta charset=\"UTF-8\">\n"
  buf <+ "  <title>MoonBit Depsight Report</title>\n"
  buf <+ "  <style>\n"
  buf.write_string(html_css())
  buf <+ "\n  </style>\n"
  buf <+ "</head>\n"
  buf <+ "<body>\n"
  buf <+ "  <div class=\"container\">\n"
  buf.write_string(html_header())
  buf <+ "\n"
  buf.write_string(html_overview(report))
  buf <+ "\n"
  buf.write_string(html_health_scores(report.health_scores))
  buf <+ "\n"
  buf.write_string(html_diagnostics(report.diagnostics))
  buf <+ "\n"
  buf.write_string(html_dependency_tree(graph, root_id))
  buf <+ "\n"
  buf.write_string(html_footer())
  buf <+ "\n  </div>\n"
  buf <+ "</body>\n"
  buf <+ "</html>\n"
  buf.to_string()
}

// ========== HTML 区块 ==========

///|
fn html_header() -> String {
  "<header class=\"header\"><h1>MoonBit Depsight</h1><p>Dependency Health Report</p></header>"
}

///|
fn html_overview(report : AnalysisReport) -> String {
  let critical = count_level(report.diagnostics, @report.level_critical())
  let warning = count_level(report.diagnostics, @report.level_warning())
  let info = count_level(report.diagnostics, @report.level_info())

  let buf = StringBuilder()
  buf <+ "<section class=\"overview\">\n"
  buf <+ "<h2>Overview</h2>\n"
  buf <+ "<div class=\"stats-grid\">\n"
  buf <+ "<div class=\"stat-card\">\n"
  buf <+ "<div class=\"stat-value\" id=\"overall-score\">"
  buf.write_string(report.overall_score.to_string())
  buf <+ "</div>\n"
  buf <+ "<div class=\"stat-label\">Health Score</div>\n"
  buf <+ "</div>\n"
  buf <+ "<div class=\"stat-card\">\n"
  buf <+ "<div class=\"stat-value\">"
  buf.write_string(report.node_count.to_string())
  buf <+ "</div>\n"
  buf <+ "<div class=\"stat-label\">Nodes</div>\n"
  buf <+ "</div>\n"
  buf <+ "<div class=\"stat-card stat-critical\">\n"
  buf <+ "<div class=\"stat-value\">"
  buf.write_string(critical.to_string())
  buf <+ "</div>\n"
  buf <+ "<div class=\"stat-label\">Critical</div>\n"
  buf <+ "</div>\n"
  buf <+ "<div class=\"stat-card stat-warning\">\n"
  buf <+ "<div class=\"stat-value\">"
  buf.write_string(warning.to_string())
  buf <+ "</div>\n"
  buf <+ "<div class=\"stat-label\">Warnings</div>\n"
  buf <+ "</div>\n"
  buf <+ "<div class=\"stat-card stat-info\">\n"
  buf <+ "<div class=\"stat-value\">"
  buf.write_string(info.to_string())
  buf <+ "</div>\n"
  buf <+ "<div class=\"stat-label\">Info</div>\n"
  buf <+ "</div>\n"
  buf <+ "</div>\n"
  buf <+ "</section>"
  buf.to_string()
}

///|
fn html_health_scores(scores : Array[HealthScore]) -> String {
  if scores.length() == 0 {
    return ""
  }
  let buf = StringBuilder()
  buf <+ "<section class=\"health-scores\">\n"
  buf <+ "<h2>Health Scores</h2>\n"
  buf <+ "<table class=\"score-table\">\n"
  buf <+
    "<thead><tr><th>Node</th><th>Total</th><th>Fresh</th><th>Comply</th><th>DepDen</th><th>Size</th><th>Actv</th></tr></thead>\n"
  buf <+ "<tbody>\n"
  for s in scores {
    let row_class = score_css_class(s.total)
    buf <+ "<tr class=\""
    buf.write_string(row_class)
    buf <+ "\">\n"
    buf <+ "<td>"
    buf.write_string(escape_html(s.node_id))
    buf <+ "</td>\n"
    buf <+ "<td class=\"score-total\">"
    buf.write_string(s.total.to_string())
    buf <+ "</td>\n"
    buf <+ "<td>"
    buf.write_string(s.freshness.to_string())
    buf <+ "</td>\n"
    buf <+ "<td>"
    buf.write_string(s.compliance.to_string())
    buf <+ "</td>\n"
    buf <+ "<td>"
    buf.write_string(s.deprecated_density.to_string())
    buf <+ "</td>\n"
    buf <+ "<td>"
    buf.write_string(s.size_reasonableness.to_string())
    buf <+ "</td>\n"
    buf <+ "<td>"
    buf.write_string(s.activity.to_string())
    buf <+ "</td>\n"
    buf <+ "</tr>\n"
  }
  buf <+ "</tbody>\n"
  buf <+ "</table>\n"
  buf <+ "</section>"
  buf.to_string()
}

///|
fn html_diagnostics(diagnostics : Array[@report.Diagnostic]) -> String {
  if diagnostics.length() == 0 {
    return "<section class=\"diagnostics\"><h2>Diagnostics</h2><p class=\"no-issues\">No issues found.</p></section>"
  }

  let buf = StringBuilder()
  buf <+ "<section class=\"diagnostics\">\n"
  buf <+ "<h2>Diagnostics</h2>\n"

  for d in diagnostics {
    let level_class = if d.is_critical() {
      "diag-critical"
    } else if d.is_warning() {
      "diag-warning"
    } else {
      "diag-info"
    }
    // F04 首创功能：DEPRECATED-002 传递废弃卡片用 <details> 折叠/展开，
    //   默认展开让用户第一眼看到，用户可以折叠节省空间。
    let is_propagate = d.code == "DEPRECATED-002"
    if is_propagate {
      buf <+ "<details class=\"diag-details\" open>\n"
      buf <+ "<summary class=\"diag-summary\">\n"
    }

    buf <+ "<div class=\"diag-card "
    buf.write_string(level_class)
    if is_propagate {
      buf <+ " diag-propagate"
    }
    buf <+ "\">\n"
    buf <+ "<div class=\"diag-header\">\n"
    buf <+ "<span class=\"diag-level\">"
    buf.write_string(d.level)
    buf <+ "</span>\n"
    buf <+ "<span class=\"diag-code\">"
    buf.write_string(d.code)
    if is_propagate {
      buf <+ " <small>(propagated)</small>"
    }
    buf <+ "</span>\n"
    buf <+ "</div>\n"
    buf <+ "<div class=\"diag-msg\">"
    buf.write_string(escape_html(d.message))
    buf <+ "</div>\n"

    if d.path.length() > 0 {
      if is_propagate {
        // F04：传播链用有序列表缩进展示，可一眼追溯源头
        buf <+ "<div class=\"diag-path-label\">Propagation chain ("
        buf.write_string((d.path.length() - 1).to_string())
        buf <+ " hops):</div>\n"
        buf <+ "<ol class=\"diag-chain\">\n"
        let n = d.path.length()
        let mut i = 0
        while i < n {
          let node = d.path[i]
          buf <+ "<li class=\""
          if i == 0 {
            buf <+ "chain-source"
          } else if i + 1 == n {
            buf <+ "chain-exposed"
          } else {
            buf <+ "chain-mid"
          }
          buf <+ "\">"
          buf.write_string(escape_html(node))
          if i + 1 < n {
            buf <+ " <span class=\"chain-arrow\">\u{2192}</span>"
          } else {
            buf <+ " <span class=\"chain-tag\">(exposed here)</span>"
          }
          if i == 0 {
            buf <+
              " <span class=\"chain-tag source-tag\">(deprecated source)</span>"
          }
          buf <+ "</li>\n"
          i = i + 1
        }
        buf <+ "</ol>\n"
      } else {
        buf <+ "<div class=\"diag-path\">Path: "
        buf.write_string(escape_html(join_html_path(d.path)))
        buf <+ "</div>\n"
      }
    }

    if d.suggestions.length() > 0 {
      buf <+ "<div class=\"diag-suggestions\">\n"
      for s in d.suggestions {
        buf <+ "<div class=\"suggestion\">\u{2192} "
        buf.write_string(escape_html(s))
        buf <+ "</div>\n"
      }
      buf <+ "</div>\n"
    }

    buf <+ "</div>\n"

    if is_propagate {
      buf <+ "</summary>\n"
      buf <+ "</details>\n"
    }
  }

  buf <+ "</section>"
  buf.to_string()
}

///|
fn html_dependency_tree(
  graph : @graph.DependencyGraph,
  root_id : String,
) -> String {
  let buf = StringBuilder()
  buf <+ "<section class=\"dep-tree\">\n"
  buf <+ "<h2>Dependency Tree</h2>\n"
  buf <+ "<div class=\"tree-root\">\n"

  // 根节点标签
  let root_label = escape_html(root_id)
  let (root_name, root_ver) = split_at_id(root_id)
  let root_children = graph.get_children(root_name, root_ver)

  if root_children.length() > 0 {
    buf <+ "<details class=\"tree-branch\" open>\n"
    buf <+ "<summary>"
    buf.write_string(root_label)
    buf <+ "</summary>\n"
    buf <+ "<div class=\"tree-children\">\n"
    for child in root_children {
      let child_html = html_tree_node(graph, child, 1)
      if child_html.length() > 0 {
        buf.write_string(child_html)
        buf <+ "\n"
      }
    }
    buf <+ "</div>\n"
    buf <+ "</details>\n"
  } else {
    buf <+ "<div class=\"tree-leaf\">"
    buf.write_string(root_label)
    buf <+ "</div>\n"
  }

  buf <+ "</div>\n"
  buf <+ "</section>"
  buf.to_string()
}

// 递归渲染树节点（用 details/summary 做折叠）

///|
fn html_tree_node(
  graph : @graph.DependencyGraph,
  node_id : String,
  depth : Int,
) -> String {
  if depth >= 8 {
    return ""
  } // 限制递归深度
  let (name, ver) = split_at_id(node_id)
  let children = graph.get_children(name, ver)
  let has_children = children.length() > 0

  let label = escape_html(node_id)
  let margin = (depth * 20).to_string()

  if has_children {
    let child_buf = StringBuilder()
    for child in children {
      let child_html = html_tree_node(graph, child, depth + 1)
      if child_html.length() > 0 {
        child_buf.write_string(child_html)
        child_buf <+ "\n"
      }
    }
    let child_str = child_buf.to_string()

    if child_str.length() == 0 {
      let buf = StringBuilder()
      buf <+ "<div class=\"tree-leaf\" style=\"margin-left:"
      buf.write_string(margin)
      buf <+ "px\">"
      buf.write_string(label)
      buf <+ "</div>"
      return buf.to_string()
    }

    let buf = StringBuilder()
    buf <+ "<details class=\"tree-branch\" style=\"margin-left:"
    buf.write_string(margin)
    buf <+ "px\">\n"
    buf <+ "<summary>"
    buf.write_string(label)
    buf <+ "</summary>\n"
    buf <+ "<div class=\"tree-children\">\n"
    buf.write_string(child_str)
    buf <+ "</div>\n"
    buf <+ "</details>"
    buf.to_string()
  } else {
    let buf = StringBuilder()
    buf <+ "<div class=\"tree-leaf\" style=\"margin-left:"
    buf.write_string(margin)
    buf <+ "px\">"
    buf.write_string(label)
    buf <+ "</div>"
    buf.to_string()
  }
}

///|
fn html_footer() -> String {
  "<footer class=\"footer\"><p>Generated by MoonBit Depsight</p></footer>"
}

// ========== CSS ==========

///|
fn html_css() -> String {
  let buf = StringBuilder()
  buf <+ ":root{--bg:#0d1117;--fg:#c9d1d9;--card:#161b22;--border:#30363d;"
  buf <+ "--green:#238636;--yellow:#d29922;--red:#da3633;--blue:#58a6ff;}"
  buf <+ "body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;"
  buf <+ "background:var(--bg);color:var(--fg);margin:0;padding:20px;}"
  buf <+ ".container{max-width:900px;margin:0 auto;}"
  buf <+
    ".header{text-align:center;border-bottom:1px solid var(--border);padding-bottom:20px;margin-bottom:20px;}"
  buf <+
    ".header h1{margin:0;font-size:28px;}.header p{margin:6px 0 0;color:#8b949e;}"
  buf <+ ".overview{margin-bottom:24px;}"
  buf <+
    ".stats-grid{display:grid;grid-template-columns:repeat(5,1fr);gap:12px;}"
  buf <+
    ".stat-card{background:var(--card);border:1px solid var(--border);border-radius:8px;padding:16px;text-align:center;}"
  buf <+
    ".stat-value{font-size:28px;font-weight:700;}.stat-label{font-size:12px;color:#8b949e;margin-top:4px;}"
  buf <+
    ".stat-critical .stat-value{color:var(--red);}.stat-warning .stat-value{color:var(--yellow);}.stat-info .stat-value{color:var(--green);}"
  buf <+
    ".score-good{color:var(--green);}.score-mid{color:var(--yellow);}.score-bad{color:var(--red);}"
  buf <+
    "#overall-score{color:var(--green);font-size:36px;}#overall-score.score-mid{color:var(--yellow);}#overall-score.score-bad{color:var(--red);}"
  buf <+ ".score-table{width:100%;border-collapse:collapse;margin-top:12px;}"
  buf <+
    ".score-table th,.score-table td{padding:8px 12px;text-align:center;border:1px solid var(--border);}"
  buf <+
    ".score-table th{background:var(--card);font-weight:600;}.score-total{font-weight:700;font-size:16px;}"
  buf <+ ".diagnostics{margin-top:24px;}"
  buf <+
    ".diag-card{background:var(--card);border:1px solid var(--border);border-radius:8px;padding:14px;margin-bottom:12px;border-left:4px solid var(--blue);}"
  buf <+
    ".diag-critical{border-left-color:var(--red);}.diag-warning{border-left-color:var(--yellow);}.diag-info{border-left-color:var(--green);}"
  buf <+
    ".diag-header{display:flex;gap:10px;align-items:center;margin-bottom:6px;}"
  buf <+
    ".diag-level{font-size:12px;font-weight:700;padding:2px 8px;border-radius:4px;background:var(--border);}"
  buf <+
    ".diag-critical .diag-level{background:var(--red);color:#fff;}.diag-warning .diag-level{background:var(--yellow);color:#000;}.diag-info .diag-level{background:var(--green);color:#fff;}"
  buf <+
    ".diag-code{font-family:monospace;color:var(--blue);font-size:13px;}.diag-msg{margin-bottom:6px;}"
  buf <+
    ".diag-path{font-size:13px;color:#8b949e;}.diag-suggestions{margin-top:8px;}"
  buf <+
    ".suggestion{font-size:13px;color:var(--blue);margin-top:2px;}.no-issues{color:var(--green);}"
  // F04：DEPRECATED-002 传播可视化 CSS
  buf <+ ".diag-details{margin-bottom:12px;}"
  buf <+
    ".diag-details .diag-summary{list-style:none;cursor:pointer;}.diag-details .diag-summary::-webkit-details-marker{display:none;}"
  buf <+
    ".diag-card.diag-propagate{border-left:4px solid #a371f7;background:linear-gradient(90deg,rgba(163,113,247,.08),var(--card));}"
  buf <+ ".diag-propagate .diag-code small{color:#a371f7;font-weight:500;}"
  buf <+
    ".diag-path-label{font-size:12px;color:#a371f7;font-weight:600;margin-top:10px;margin-bottom:6px;text-transform:uppercase;letter-spacing:.4px;}"
  buf <+ "ol.diag-chain{margin:4px 0 6px 0;padding-left:22px;}"
  buf <+ "ol.diag-chain li{font-family:monospace;font-size:13px;padding:3px 0;}"
  buf <+ "ol.diag-chain li.chain-source{color:#ff7b72;font-weight:600;}"
  buf <+ "ol.diag-chain li.chain-mid{color:#f0883e;}"
  buf <+ "ol.diag-chain li.chain-exposed{color:#a371f7;font-weight:700;}"
  buf <+ "ol.diag-chain .chain-arrow{color:#30363d;margin:0 6px;}"
  buf <+
    "ol.diag-chain .chain-tag{font-weight:500;font-size:11px;margin-left:6px;padding:1px 6px;border-radius:4px;background:var(--border);}"
  buf <+
    "ol.diag-chain .source-tag{color:#ff7b72;border:1px solid rgba(255,123,114,.4);background:rgba(255,123,114,.08);}"
  buf <+ ".dep-tree{margin-top:24px;}"
  buf <+
    ".tree-root{background:var(--card);border:1px solid var(--border);border-radius:8px;padding:12px;}"
  buf <+
    ".tree-branch{margin:4px 0;}.tree-branch summary{cursor:pointer;font-family:monospace;padding:4px;border-radius:4px;}"
  buf <+ ".tree-branch summary:hover{background:#21262d;}"
  buf <+
    ".tree-leaf{font-family:monospace;padding:4px 4px 4px 20px;color:#8b949e;}"
  buf <+
    ".footer{text-align:center;color:#8b949e;font-size:12px;margin-top:32px;padding-top:16px;border-top:1px solid var(--border);}"
  buf.to_string()
}

// ========== 工具函数 ==========

///|
fn score_css_class(score : Int) -> String {
  if score >= 80 {
    "score-good"
  } else if score >= 50 {
    "score-mid"
  } else {
    "score-bad"
  }
}

///|
/// 拆分 "name@version" 为 (name, version)
fn split_at_id(node_id : String) -> (String, String) {
  let mut i = 0
  while i < node_id.length() {
    if node_id[i].to_int() == '@'.to_int() {
      return (
        substring(node_id, 0, i),
        substring(node_id, i + 1, node_id.length() - i - 1),
      )
    }
    i = i + 1
  }
  (node_id, "")
}

///|
fn count_level(diagnostics : Array[@report.Diagnostic], level : String) -> Int {
  let mut count = 0
  for d in diagnostics {
    if d.level == level {
      count = count + 1
    }
  }
  count
}

///|
fn escape_html(s : String) -> String {
  let buf = StringBuilder()
  for i = 0; i < s.length(); i = i + 1 {
    let code = s[i].to_int()
    if code == '&'.to_int() {
      buf <+ "&amp;"
    } else if code == '<'.to_int() {
      buf <+ "&lt;"
    } else if code == '>'.to_int() {
      buf <+ "&gt;"
    } else if code == '"'.to_int() {
      buf <+ "&quot;"
    } else {
      let c = s[i].to_int().unsafe_to_char()
      buf.write_string(c.to_string())
    }
  }
  buf.to_string()
}

///|
fn join_html_path(path : Array[String]) -> String {
  let buf = StringBuilder()
  let mut first = true
  for p in path {
    if !first {
      buf <+ " -> "
    }
    buf.write_string(p)
    first = false
  }
  buf.to_string()
}
