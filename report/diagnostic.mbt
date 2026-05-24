/// 诊断级别常量
pub const LEVEL_CRITICAL : String = "Critical"
pub const LEVEL_WARNING : String = "Warning"
pub const LEVEL_INFO : String = "Info"

/// 单条诊断信息
///
/// `level`   — 严重级别，使用 `LEVEL_CRITICAL` / `LEVEL_WARNING` / `LEVEL_INFO`
/// `code`    — 诊断码，如 `"CYCLE-001"`
/// `message` — 人类可读的问题描述
/// `path`    — 问题涉及的节点/文件路径列表
/// `suggestions` — 修复建议
pub struct Diagnostic {
  pub level : String
  pub code : String
  pub message : String
  pub path : Array[String]
  pub suggestions : Array[String]
} derive(Debug)

/// 构造 Diagnostic（用于 blackbox test 直接构造）
pub fn Diagnostic::new(level : String, code : String, message : String, path : Array[String], suggestions : Array[String]) -> Diagnostic {
  { level, code, message, path, suggestions }
}

/// 创建一条 Critical 级别诊断
pub fn Diagnostic::critical(
  code : String,
  message : String,
  path : Array[String]
) -> Diagnostic {
  { level: LEVEL_CRITICAL, code, message, path, suggestions: [] }
}

/// 创建一条 Warning 级别诊断
pub fn Diagnostic::warning(
  code : String,
  message : String,
  path : Array[String]
) -> Diagnostic {
  { level: LEVEL_WARNING, code, message, path, suggestions: [] }
}

/// 创建一条 Info 级别诊断
pub fn Diagnostic::info(
  code : String,
  message : String,
  path : Array[String]
) -> Diagnostic {
  { level: LEVEL_INFO, code, message, path, suggestions: [] }
}

/// 添加修复建议（返回新的 Diagnostic，不改变原对象）
pub fn Diagnostic::with_suggestion(self : Diagnostic, suggestion : String) -> Diagnostic {
  let new_suggestions = []
  for s in self.suggestions {
    new_suggestions.push(s)
  }
  new_suggestions.push(suggestion)
  { level: self.level, code: self.code, message: self.message, path: self.path, suggestions: new_suggestions }
}

/// 将诊断转为可阅读的字符串（单行格式，适合终端表格）
pub fn Diagnostic::to_string(self : Diagnostic) -> String {
  let parts = [self.level, " [", self.code, "] ", self.message]
  if self.path.length() > 0 {
    parts.push(" (path: ")
    parts.push(join_strings(self.path, " -> "))
    parts.push(")")
  }
  if self.suggestions.length() > 0 {
    parts.push(" | suggestion: ")
    parts.push(self.suggestions[0])
  }
  join_string_array(parts)
}

/// 将诊断转为 JSON 字符串（供 CI / HTML 报告消费）
pub fn Diagnostic::to_json_string(self : Diagnostic) -> String {
  let parts = [
    "{\"level\":\"", self.level, "\",\"code\":\"", self.code,
    "\",\"message\":\"", escape_json(self.message), "\",\"path\":[",
    join_string_array(quote_array(self.path)), "],\"suggestions\":[",
    join_string_array(quote_array(self.suggestions)), "]}"
  ]
  join_string_array(parts)
}

// ---------- 内部辅助 ----------

fn join_strings(arr : Array[String], sep : String) -> String {
  join_strings_loop(arr, sep, 0, "")
}

fn join_strings_loop(arr : Array[String], sep : String, idx : Int, acc : String) -> String {
  if idx >= arr.length() { return acc }
  let new_acc = if idx == 0 { acc + arr[idx] } else { acc + sep + arr[idx] }
  join_strings_loop(arr, sep, idx + 1, new_acc)
}

fn join_string_array(arr : Array[String]) -> String {
  join_string_array_loop(arr, 0, "")
}

fn join_string_array_loop(arr : Array[String], idx : Int, acc : String) -> String {
  if idx >= arr.length() { return acc }
  join_string_array_loop(arr, idx + 1, acc + arr[idx])
}

fn quote_array(arr : Array[String]) -> Array[String] {
  quote_array_loop(arr, 0, [])
}

fn quote_array_loop(arr : Array[String], idx : Int, acc : Array[String]) -> Array[String] {
  if idx >= arr.length() { return acc }
  if idx > 0 {
    acc.push(",")
  }
  acc.push("\"")
  acc.push(escape_json(arr[idx]))
  acc.push("\"")
  quote_array_loop(arr, idx + 1, acc)
}

fn escape_json(s : String) -> String {
  escape_json_loop(s, 0, [])
}

fn escape_json_loop(s : String, idx : Int, acc : Array[String]) -> String {
  if idx >= s.length() { return join_string_array(acc) }
  let ch = s[idx]
  if ch == '"' {
    acc.push("\\\"")
  } else if ch == '\\' {
    acc.push("\\\\")
  } else if ch == '\n' {
    acc.push("\\n")
  } else {
    acc.push(char_to_string(ch))
  }
  escape_json_loop(s, idx + 1, acc)
}

fn char_to_string(ch : UInt16) -> String {
  let c = ch.to_int().unsafe_to_char()
  let arr : Array[String] = [c.to_string()]
  join_string_array(arr)
}
