/// SARIF (Static Analysis Results Interchange Format) v2.1.0 报告渲染器
///
/// 生成符合 SARIF 标准的 JSON，可直接上传至 GitHub Code Scanning。

// ---------- 公共入口 ----------

///|
/// 将 AnalysisReport 渲染为 SARIF v2.1.0 JSON 字符串
pub fn render_sarif_report(
  report : AnalysisReport,
  graph : @graph.DependencyGraph,
  root_id : String,
) -> String {
  // graph 和 root_id 保留给未来扩展（如 SARIF 中嵌入依赖图拓扑）
  let _ = graph
  let _ = root_id
  let buf = StringBuilder()
  buf <+ "{\""
  buf <+
    "$schema\":\"https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json\","
  buf <+ "\"version\":\"2.1.0\","
  buf <+ "\"runs\":[{"

  // tool.driver
  buf <+ "\"tool\":{\"driver\":{"
  buf <+ "\"name\":\"MoonBit Depsight\","
  buf <+ "\"version\":\"0.5.0\","
  buf <+ "\"informationUri\":\"https://github.com/Tino-hue/moonmark\","

  // rules
  buf <+ "\"rules\":["
  let rules = collect_rules(report.get_diagnostics())
  let mut ri = 0
  for rule in rules {
    if ri > 0 {
      buf <+ ","
    }
    rule_to_json(rule, buf)
    ri = ri + 1
  }
  buf <+ "],"

  // properties (overall score)
  let overall = report.get_overall_score()
  let node_count = report.get_node_count()
  buf <+
    $|"\"properties\":{\"overall_score\":\{overall},\"node_count\":\{node_count}}},"

  // results
  buf <+ "\"results\":["
  let diags = report.get_diagnostics()
  let mut di = 0
  for d in diags {
    if di > 0 {
      buf <+ ","
    }
    diag_to_sarif_result(d, buf)
    di = di + 1
  }
  buf <+ "]"

  buf <+ "}]}"

  buf.to_string()
}

// ---------- 内部辅助 ----------

///|
priv struct SarifRule {
  id : String
  level : String
  message : String
}

///|
fn collect_rules(diags : Array[@report.Diagnostic]) -> Array[SarifRule] {
  let seen : Map[String, Bool] = Map([])
  let result = []
  for d in diags {
    if seen.get(d.code) is None {
      seen[d.code] = true
      result.push({
        id: d.code,
        level: diag_level_to_sarif(d.level),
        message: d.message,
      })
    }
  }
  result
}

///|
fn rule_to_json(rule : SarifRule, buf : StringBuilder) -> Unit {
  buf <+ "{\"id\":\""
  buf.write_string(rule.id)
  buf <+ "\",\""
  buf <+ "\"shortDescription\":{\"text\":\""
  buf.write_string(sarif_escape(rule.message))
  buf <+ "\",\""
  buf <+ "\"defaultConfiguration\":{\"level\":\""
  buf.write_string(rule.level)
  buf <+ "\"}}"
}

///|
fn diag_level_to_sarif(level : String) -> String {
  if level == @report.level_critical() {
    "error"
  } else if level == @report.level_warning() {
    "warning"
  } else {
    "note"
  }
}

///|
fn diag_to_sarif_result(d : @report.Diagnostic, buf : StringBuilder) -> Unit {
  buf <+ "{\"ruleId\":\""
  buf.write_string(d.code)
  buf <+ "\",\""
  buf <+ "\"level\":\""
  buf.write_string(diag_level_to_sarif(d.level))
  buf <+ "\",\""
  buf <+ "\"message\":{\"text\":\""
  buf.write_string(sarif_escape(d.message))
  buf <+ "\"}"

  // locations
  if d.path.length() > 0 {
    buf <+ ",\"locations\":["
    let mut li = 0
    for loc in d.path {
      if li > 0 {
        buf <+ ","
      }
      buf <+ "{\"physicalLocation\":{\"artifactLocation\":{\"uri\":\""
      buf.write_string(sarif_escape(loc))
      buf <+ "\"}}}"
      li = li + 1
    }
    buf <+ "]"
  }

  // suggestions as fixes
  if d.suggestions.length() > 0 {
    buf <+ ",\"fixes\":["
    let mut fi = 0
    for sugg in d.suggestions {
      if fi > 0 {
        buf <+ ","
      }
      buf <+ "{\"description\":{\"text\":\""
      buf.write_string(sarif_escape(sugg))
      buf <+ "\"}}"
      fi = fi + 1
    }
    buf <+ "]"
  }

  buf <+ "}"
}

///|
fn sarif_escape(s : String) -> String {
  // 简单转义：反斜杠、双引号、换行
  let buf = StringBuilder()
  for i = 0; i < s.length(); i = i + 1 {
    let ch = s[i]
    if ch == '\\' {
      buf <+ "\\\\"
    } else if ch == '"' {
      buf <+ "\\\""
    } else if ch == '\n' {
      buf <+ "\\n"
    } else {
      buf.write_string(ch.to_string())
    }
  }
  buf.to_string()
}
