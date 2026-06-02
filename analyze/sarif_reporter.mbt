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
  let parts : Array[String] = []
  parts.push("{\"")
  parts.push("$schema\"")
  parts.push(
    "\":\"https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json\",\"",
  )
  parts.push("version\":\"2.1.0\",\"")
  parts.push("runs\":[")

  // tool.driver
  parts.push("{\"tool\":{\"driver\":{")
  parts.push("\"name\":\"MoonBit Depsight\",\"")
  parts.push("version\":\"0.4.0\",\"")
  parts.push("informationUri\":\"https://github.com/Tino-hue/moonmark\",\"")

  // rules
  parts.push("rules\":[")
  let rules = collect_rules(report.get_diagnostics())
  let mut ri = 0
  for rule in rules {
    if ri > 0 {
      parts.push(",")
    }
    parts.push(rule_to_json(rule))
    ri = ri + 1
  }
  parts.push("],\"")

  // properties (overall score)
  parts.push("properties\":{\"overall_score\":")
  parts.push(report.get_overall_score().to_string())
  parts.push(",\"node_count\":")
  parts.push(report.get_node_count().to_string())
  parts.push("}}},\"")

  // results
  parts.push("results\":[")
  let diags = report.get_diagnostics()
  let mut di = 0
  for d in diags {
    if di > 0 {
      parts.push(",")
    }
    parts.push(diag_to_sarif_result(d))
    di = di + 1
  }
  parts.push("]")

  parts.push("}]")
  parts.push("}")

  join_sarif_parts(parts)
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
  let seen : Map[String, Bool] = {}
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
fn rule_to_json(rule : SarifRule) -> String {
  let parts = ["{\"id\":\"", rule.id, "\",\""]
  parts.push("shortDescription\":{\"text\":\"")
  parts.push(sarif_escape(rule.message))
  parts.push("\"},\"")
  parts.push("defaultConfiguration\":{\"level\":\"")
  parts.push(rule.level)
  parts.push("\"}}")
  join_sarif_parts(parts)
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
fn diag_to_sarif_result(d : @report.Diagnostic) -> String {
  let parts : Array[String] = []
  parts.push("{\"ruleId\":\"")
  parts.push(d.code)
  parts.push("\",\"")
  parts.push("level\":\"")
  parts.push(diag_level_to_sarif(d.level))
  parts.push("\",\"")
  parts.push("message\":{\"text\":\"")
  parts.push(sarif_escape(d.message))
  parts.push("\"}")

  // locations
  if d.path.length() > 0 {
    parts.push(",\"locations\":[")
    let mut li = 0
    for loc in d.path {
      if li > 0 {
        parts.push(",")
      }
      parts.push("{\"physicalLocation\":{\"artifactLocation\":{\"uri\":\"")
      parts.push(sarif_escape(loc))
      parts.push("\"}}}")
      li = li + 1
    }
    parts.push("]")
  }

  // suggestions as fixes
  if d.suggestions.length() > 0 {
    parts.push(",\"fixes\":[")
    let mut fi = 0
    for sugg in d.suggestions {
      if fi > 0 {
        parts.push(",")
      }
      parts.push("{\"description\":{\"text\":\"")
      parts.push(sarif_escape(sugg))
      parts.push("\"}}")
      fi = fi + 1
    }
    parts.push("]")
  }

  parts.push("}")
  join_sarif_parts(parts)
}

///|
fn sarif_escape(s : String) -> String {
  // 简单转义：反斜杠、双引号、换行
  let parts = []
  for i = 0; i < s.length(); i = i + 1 {
    let ch = s[i]
    if ch == '\\' {
      parts.push("\\\\")
    } else if ch == '"' {
      parts.push("\\\"")
    } else if ch == '\n' {
      parts.push("\\n")
    } else {
      parts.push(char_to_string(ch))
    }
  }
  join_sarif_parts(parts)
}

///|
fn char_to_string(code : UInt16) -> String {
  let c = code.to_int().unsafe_to_char()
  let arr : Array[String] = [c.to_string()]
  join_sarif_parts(arr)
}

///|
fn join_sarif_parts(parts : Array[String]) -> String {
  let mut result = ""
  for i = 0; i < parts.length(); i = i + 1 {
    result = result + parts[i]
  }
  result
}
