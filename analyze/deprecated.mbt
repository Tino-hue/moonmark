///|
/// 废弃 API 信息
pub struct DeprecatedApi {
  name : String
  since : String?
  message : String?
} derive(Debug)

///|
/// 构造 DeprecatedApi（用于测试）
pub fn DeprecatedApi::new(
  name : String,
  since? : String? = None,
  message? : String? = None,
) -> DeprecatedApi {
  { name, since, message }
}

///|
/// 扫描 MoonBit 源码，提取所有标记 @deprecated 的 API
pub fn scan_deprecated_apis(source : String) -> Array[DeprecatedApi] {
  let lines = split_lines(source)
  let apis : Array[DeprecatedApi] = []
  let mut i = 0
  while i < lines.length() {
    let line = trim(lines[i])
    // 收集连续的 doc comment
    if starts_with(line, "///") {
      let comment_lines : Array[String] = [line]
      i = i + 1
      while i < lines.length() {
        let next = trim(lines[i])
        if starts_with(next, "///") {
          comment_lines.push(next)
          i = i + 1
        } else {
          break
        }
      }
      // 检查是否有 @deprecated
      let mut deprecated_since : String? = None
      let mut deprecated_msg : String? = None
      let mut has_deprecated = false
      for c in comment_lines {
        if contains(c, "@deprecated") {
          has_deprecated = true
          let (s, m) = parse_deprecated_comment(c)
          if s is Some(_) {
            deprecated_since = s
          }
          if m is Some(_) {
            deprecated_msg = m
          }
        }
      }
      if has_deprecated && i < lines.length() {
        let def_line = trim(lines[i])
        match extract_definition_name(def_line) {
          Some(name) =>
            apis.push({ name, since: deprecated_since, message: deprecated_msg })
          None => ()
        }
      }
    }
    i = i + 1
  }
  apis
}

// ---------- 内部辅助 ----------

///|
fn split_lines(s : String) -> Array[String] {
  let lines : Array[String] = []
  let mut start = 0
  let mut i = 0
  while i < s.length() {
    let ch = s[i].to_int()
    if ch == 10 {
      lines.push(substring(s, start, i - start))
      start = i + 1
    } else if ch == 13 {
      lines.push(substring(s, start, i - start))
      if i + 1 < s.length() && s[i + 1].to_int() == 10 {
        i = i + 1
      }
      start = i + 1
    }
    i = i + 1
  }
  if start < s.length() {
    lines.push(substring(s, start, s.length() - start))
  }
  lines
}

///|
fn parse_deprecated_comment(line : String) -> (String?, String?) {
  let idx = index_of_string(line, "@deprecated")
  if idx < 0 {
    return (None, None)
  }
  let rest = substring(
    line,
    idx + "@deprecated".length(),
    line.length() - idx - "@deprecated".length(),
  )
  let trimmed = trim(rest)
  if trimmed.length() == 0 {
    return (None, None)
  }

  // 提取 since
  let since = if starts_with(trimmed, "since ") {
    let after = trim(
      substring(
        trimmed,
        "since ".length(),
        trimmed.length() - "since ".length(),
      ),
    )
    let end = find_word_end(after)
    let ver = trim(substring(after, 0, end))
    if ver.length() > 0 {
      Some(ver)
    } else {
      None
    }
  } else {
    None
  }

  // 提取 message（since 之后的所有内容，或整行）
  let msg = match since {
    Some(ver) => {
      let prefix = "since " + ver
      let rest2 = trim(
        substring(trimmed, prefix.length(), trimmed.length() - prefix.length()),
      )
      if rest2.length() > 0 {
        Some(rest2)
      } else {
        None
      }
    }
    None => Some(trimmed)
  }

  (since, msg)
}

///|
fn extract_definition_name(line : String) -> String? {
  let s = trim(line)
  // 跳过访问修饰符
  let mut body = s
  if starts_with(body, "pub ") {
    body = trim(substring(body, 4, body.length() - 4))
  }

  // fn name(... or fn name[T](...
  if starts_with(body, "fn ") {
    let after = trim(substring(body, 3, body.length() - 3))
    let end = find_char(after, '(')
    let name = trim(substring(after, 0, end))
    if name.length() > 0 {
      return Some(name)
    }
  }

  // let name = ... / const NAME = ...
  if starts_with(body, "let ") {
    let after = trim(substring(body, 4, body.length() - 4))
    let end = find_char(after, '=')
    let name = trim(substring(after, 0, end))
    if name.length() > 0 {
      return Some(name)
    }
  }
  if starts_with(body, "const ") {
    let after = trim(substring(body, 6, body.length() - 6))
    let end = find_char(after, '=')
    let name = trim(substring(after, 0, end))
    if name.length() > 0 {
      return Some(name)
    }
  }

  // struct Name { ... / enum Name { ... / trait Name { ... / type Name ...
  if starts_with(body, "struct ") ||
    starts_with(body, "enum ") ||
    starts_with(body, "trait ") ||
    starts_with(body, "type ") {
    let keyword_len = if starts_with(body, "struct ") {
      7
    } else if starts_with(body, "enum ") {
      5
    } else if starts_with(body, "trait ") {
      6
    } else {
      5
    }
    let after = trim(substring(body, keyword_len, body.length() - keyword_len))
    let end = find_char(after, '{')
    let name = trim(substring(after, 0, end))
    if name.length() > 0 {
      return Some(name)
    }
  }

  None
}

///|
fn find_word_end(s : String) -> Int {
  let mut i = 0
  while i < s.length() {
    let ch = s[i].to_int()
    if ch == 32 || ch == 9 || ch == 10 || ch == 13 {
      return i
    }
    i = i + 1
  }
  s.length()
}

///|
fn find_char(s : String, target : Char) -> Int {
  let mut i = 0
  while i < s.length() {
    if s[i].to_int().unsafe_to_char() == target {
      return i
    }
    i = i + 1
  }
  s.length()
}
