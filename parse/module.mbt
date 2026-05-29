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

/// 构造 Module（用于 blackbox test 直接构造）
pub fn Module::new(
  name : String,
  version : String,
  deps : Map[String, String]
) -> Module {
  { name, version, readme: None, repository: None, license: None, keywords: [], description: None, source: None, deps }
}

/// Parse a moon.mod.json content string into a Module struct
pub fn parse_mod_json(content : String) -> Result[Module, String] {
  let json = try {
    @json.parse(content)
  } catch {
    _ => return Err("Invalid JSON format")
  }
  guard json is Object(obj) else {
    return Err("Expected JSON object at root")
  }

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
      let result : Map[String, String] = {}
      for pair in dep_map {
        let (key, value) = pair
        guard value is String(v) else { continue }
        result[key] = v
      }
      result
    }
    _ => {}
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
  let deps : Map[String, String] = {}

  let lines = toml_split_lines(content)
  for line in lines {
    let trimmed = line.trim().to_string()
    if trimmed.is_empty() || trimmed.has_prefix("#") { continue }

    let eq_idx = toml_find_eq(trimmed)
    if eq_idx < 0 { continue }
    let key = trimmed.substring(start=0, end=eq_idx).trim().to_string()
    let raw_val = trimmed.substring(start=eq_idx + 1, end=trimmed.length()).trim().to_string()

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
        for k in arr { keywords.push(k) }
      }
      _ => ()
    }
  }

  if name.is_empty() { return Err("Missing required field 'name'") }
  if version.is_empty() { return Err("Missing required field 'version'") }

  Ok({ name, version, readme, repository, license, keywords, description, source, deps })
}

fn toml_split_lines(content : String) -> Array[String] {
  let result = []
  let mut start = 0
  let n = content.length()
  for i = 0; i < n; i = i + 1 {
    if content[i] == '\n' {
      result.push(content.substring(start=start, end=i))
      start = i + 1
    }
  }
  if start < n {
    result.push(content.substring(start=start, end=n))
  }
  result
}

fn toml_find_eq(s : String) -> Int {
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == '=' { return i }
  }
  -1
}

fn toml_strip_quotes(s : String) -> String {
  let t = s.trim().to_string()
  let n = t.length()
  if n >= 2 && t[0] == '"' && t[n - 1] == '"' {
    t.substring(start=1, end=n - 1)
  } else {
    t
  }
}

fn toml_parse_string_array(raw : String) -> Array[String] {
  let t = raw.trim().to_string()
  let n = t.length()
  if n < 2 || t[0] != '[' || t[n - 1] != ']' {
    return []
  }
  let inner = t.substring(start=1, end=n - 1)
  let result = []
  let mut start = 0
  for i = 0; i < inner.length(); i = i + 1 {
    if inner[i] == ',' {
      let item = inner.substring(start=start, end=i)
      let s = toml_strip_quotes(item)
      if !s.is_empty() { result.push(s) }
      start = i + 1
    }
  }
  if start < inner.length() {
    let s = toml_strip_quotes(inner.substring(start=start, end=inner.length()))
    if !s.is_empty() { result.push(s) }
  }
  result
}
