/// Represents a parsed moon.mod.json module configuration
pub struct Module {
  pub name : String
  pub version : String
  pub readme : String?
  pub repository : String?
  pub license : String?
  pub keywords : Array[String]
  pub description : String?
  pub source : String?
  pub deps : Map[String, String]
} derive(Debug)

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
