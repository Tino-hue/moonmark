///|
/// Represents a parsed moon.mod.json module configuration
pub struct Module {
  name : String
  version : String
  readme : String?
  repository : String?
  license : String?
  keywords : Array[String]
  description : String?
  source : String?
  deps : Map[String, String]
} derive(Debug)

///|
/// 构造 Module（用于 blackbox test 直接构造）
pub fn Module::new(
  name : String,
  version : String,
  deps : Map[String, String],
) -> Module {
  {
    name,
    version,
    readme: None,
    repository: None,
    license: None,
    keywords: [],
    description: None,
    source: None,
    deps,
  }
}

///|
/// Parse a moon.mod.json content string into a Module struct
pub fn parse_mod_json(content : String) -> Result[Module, String] {
  let json = @json.parse(content) catch {
    _ => return Err("Invalid JSON format")
  }
  guard json is Object(obj) else { return Err("Expected JSON object at root") }

  // Extract required fields
  let name = match obj.get("name") {
    Some(String(s)) => s
    _ => return Err("Missing or invalid field 'name'")
  }
  let version = match obj.get("version") {
    Some(String(s)) => s
    _ => return Err("Missing or invalid field 'version'")
  }

  // Extract optional fields with defaults
  let readme = match obj.get("readme") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let repository = match obj.get("repository") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let license = match obj.get("license") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let description = match obj.get("description") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let source = match obj.get("source") {
    Some(String(s)) => Some(s)
    _ => None
  }

  // Parse keywords array
  let keywords = match obj.get("keywords") {
    Some(Array(arr)) => {
      let result = []
      for item in arr {
        guard item is String(s) else { continue }
        result.push(s)
      }
      result
    }
    _ => []
  }

  // Parse deps object
  let deps = match obj.get("deps") {
    Some(Object(dep_map)) => {
      let result : Map[String, String] = Map([])
      for pair in dep_map {
        let (key, value) = pair
        guard value is String(v) else { continue }
        result[key] = v
      }
      result
    }
    _ => Map([])
  }

  Ok({
    name,
    version,
    readme,
    repository,
    license,
    keywords,
    description,
    source,
    deps,
  })
}

///|
/// Parse a moon.mod (TOML-like) content string into a Module struct.
/// Only supports simple key = "value" and key = ["a", "b"] patterns.
pub fn parse_mod_toml(content : String) -> Result[Module, String] {
  let mut name = ""
  let mut version = ""
  let mut readme : String? = None
  let mut repository : String? = None
  let mut license : String? = None
  let mut description : String? = None
  let mut source : String? = None
  let keywords : Array[String] = []
  let deps : Map[String, String] = Map([])

  let lines = toml_split_entries(content)
  for line in lines {
    let trimmed = line.trim().to_owned()
    if trimmed.is_empty() || trimmed.has_prefix("#") {
      continue
    }

    let eq_idx = toml_find_eq(trimmed)
    if eq_idx < 0 {
      continue
    }
    let key = trimmed[0:eq_idx].trim().to_owned()
    let raw_val = trimmed[eq_idx + 1:].trim().to_owned()

    match key {
      "name" => name = toml_strip_quotes(raw_val)
      "version" => version = toml_strip_quotes(raw_val)
      "readme" => readme = Some(toml_strip_quotes(raw_val))
      "repository" => repository = Some(toml_strip_quotes(raw_val))
      "license" => license = Some(toml_strip_quotes(raw_val))
      "description" => description = Some(toml_strip_quotes(raw_val))
      "source" => source = Some(toml_strip_quotes(raw_val))
      "keywords" => {
        let arr = toml_parse_string_array(raw_val)
        for k in arr {
          keywords.push(k)
        }
      }
      _ => ()
    }
  }

  if name.is_empty() {
    return Err("Missing required field 'name'")
  }
  if version.is_empty() {
    return Err("Missing required field 'version'")
  }

  Ok({
    name,
    version,
    readme,
    repository,
    license,
    keywords,
    description,
    source,
    deps,
  })
}

///|
/// 解析简单配置 TOML，返回 key->value 字典（支持 key = "value" 和 [section] 格式）
/// section 内的 key 会被编码为 "section.key"
pub fn parse_config_toml(content : String) -> Map[String, String] {
  let result : Map[String, String] = Map([])
  let lines = toml_split_lines(content)
  let mut current_section = ""
  for line in lines {
    let trimmed = line.trim().to_owned()
    if trimmed.is_empty() || trimmed.has_prefix("#") {
      continue
    }
    // section header: [section]
    if trimmed[0] == '[' {
      let end = str_find_char(trimmed, ']'.to_int().to_uint16())
      if end > 0 {
        current_section = trimmed[1:end].trim().to_owned()
      }
      continue
    }
    let eq_idx = toml_find_eq(trimmed)
    if eq_idx < 0 {
      continue
    }
    let key = trimmed[0:eq_idx].trim().to_owned()
    let raw_val = trimmed[eq_idx + 1:].trim().to_owned()
    let full_key = if current_section.is_empty() {
      key
    } else {
      current_section + "." + key
    }
    result[full_key] = toml_strip_quotes(raw_val)
  }
  result
}

///|
fn str_find_char(s : String, ch : UInt16) -> Int {
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == ch {
      return i
    }
  }
  -1
}

///|
fn toml_split_lines(content : String) -> Array[String] {
  let result = []
  let mut start = 0
  for i = 0; i < content.length(); i = i + 1 {
    if content[i] == '\n' {
      result.push(content[start:i].to_owned())
      start = i + 1
    }
  }
  if start < content.length() {
    result.push(content[start:].to_owned())
  }
  result
}

///|
fn is_toml_key_char(ch : UInt16) -> Bool {
  let c = ch.to_int().unsafe_to_char()
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '-' ||
  c == '.'
}

///|
fn toml_split_entries(content : String) -> Array[String] {
  let result = []
  let n = content.length()
  let mut i = 0
  while i < n {
    // 跳过空白字符
    while i < n {
      let ch = content[i]
      if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
        i = i + 1
      } else {
        break
      }
    }
    if i >= n {
      break
    }

    // 跳过注释
    if content[i] == '#' {
      while i < n && content[i] != '\n' {
        i = i + 1
      }
      continue
    }

    // 读取 key
    let key_start = i
    while i < n && is_toml_key_char(content[i]) {
      i = i + 1
    }
    if key_start == i {
      i = i + 1
      continue
    }
    let key = content[key_start:i].trim().to_owned()

    // 跳过空白
    while i < n && (content[i] == ' ' || content[i] == '\t') {
      i = i + 1
    }
    if i >= n || content[i] != '=' {
      continue
    }
    i = i + 1 // skip '='

    // 跳过空白
    while i < n && (content[i] == ' ' || content[i] == '\t') {
      i = i + 1
    }
    if i >= n {
      continue
    }

    // 读取 value
    let mut val_start = i
    let mut val_end = i
    if content[i] == '"' {
      val_start = i
      i = i + 1
      while i < n && content[i] != '"' {
        i = i + 1
      }
      if i < n && content[i] == '"' {
        i = i + 1
      }
      val_end = i
    } else if content[i] == '[' {
      val_start = i
      i = i + 1
      while i < n && content[i] != ']' {
        i = i + 1
      }
      if i < n && content[i] == ']' {
        i = i + 1
      }
      val_end = i
    } else {
      while i < n &&
            content[i] != ' ' &&
            content[i] != '\t' &&
            content[i] != '\n' &&
            content[i] != '\r' {
        i = i + 1
      }
      val_end = i
    }

    let val = content[val_start:val_end].trim().to_owned()
    result.push(key + " = " + val)
  }
  result
}

///|
fn toml_find_eq(s : String) -> Int {
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == '=' {
      return i
    }
  }
  -1
}

///|
fn toml_strip_quotes(s : String) -> String {
  let t = s.trim().to_owned()
  let n = t.length()
  if n >= 2 && t[0] == '"' && t[n - 1] == '"' {
    t[1:n - 1].to_owned()
  } else {
    t
  }
}

///|
fn toml_parse_string_array(raw : String) -> Array[String] {
  let t = raw.trim().to_owned()
  let n = t.length()
  if n < 2 || t[0] != '[' || t[n - 1] != ']' {
    return []
  }
  let inner = t[1:n - 1]
  let result = []
  let mut start = 0
  for i = 0; i < inner.length(); i = i + 1 {
    if inner[i] == ',' {
      let item = inner[start:i].to_owned()
      let s = toml_strip_quotes(item)
      if !s.is_empty() {
        result.push(s)
      }
      start = i + 1
    }
  }
  if start < inner.length() {
    let s = toml_strip_quotes(inner[start:].to_owned())
    if !s.is_empty() {
      result.push(s)
    }
  }
  result
}
