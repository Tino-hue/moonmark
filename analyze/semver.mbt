///|
/// SemVer 版本结构体
pub struct Version {
  major : Int
  minor : Int
  patch : Int
  prerelease : String?
} derive(Debug)

///|
/// 解析版本字符串，如 "1.2.3" 或 "1.2.3-alpha"
pub fn parse_version(s : String) -> Result[Version, String] {
  if s.length() == 0 {
    return Err("Empty version string")
  }

  // 分离 prerelease 部分（以 '-' 为界）
  let mut core_part = ""
  let mut pre_part : String? = None
  let pre_idx = index_of_char(s, '-')
  if pre_idx >= 0 {
    core_part = substring(s, 0, pre_idx)
    pre_part = Some(substring(s, pre_idx + 1, s.length() - pre_idx - 1))
  } else {
    core_part = s
  }

  // 按 '.' 分割 major.minor.patch
  let parts = split_by_dot(core_part)
  if parts.length() != 3 {
    return Err("Expected MAJOR.MINOR.PATCH format, got: " + core_part)
  }

  let major = match parse_int(parts[0]) {
    Some(n) =>
      if n < 0 {
        return Err("Negative major version: " + parts[0])
      } else {
        n
      }
    None => return Err("Invalid major version: " + parts[0])
  }
  let minor = match parse_int(parts[1]) {
    Some(n) =>
      if n < 0 {
        return Err("Negative minor version: " + parts[1])
      } else {
        n
      }
    None => return Err("Invalid minor version: " + parts[1])
  }
  let patch = match parse_int(parts[2]) {
    Some(n) =>
      if n < 0 {
        return Err("Negative patch version: " + parts[2])
      } else {
        n
      }
    None => return Err("Invalid patch version: " + parts[2])
  }

  Ok({ major, minor, patch, prerelease: pre_part })
}

///|
/// 比较两个版本，返回 -1 / 0 / 1
pub fn compare(v1 : Version, v2 : Version) -> Int {
  if v1.major != v2.major {
    return if v1.major < v2.major { -1 } else { 1 }
  }
  if v1.minor != v2.minor {
    return if v1.minor < v2.minor { -1 } else { 1 }
  }
  if v1.patch != v2.patch {
    return if v1.patch < v2.patch { -1 } else { 1 }
  }
  // core 相同，比较 prerelease：有 prerelease 的版本 < 无 prerelease 的版本
  match (v1.prerelease, v2.prerelease) {
    (None, None) => 0
    (Some(_), None) => -1
    (None, Some(_)) => 1
    (Some(p1), Some(p2)) => compare_prerelease(p1, p2)
  }
}

///|
/// 判断当前版本是否已过时（latest 更新）
pub fn is_outdated(current : Version, latest : Version) -> Bool {
  compare(current, latest) < 0
}

///|
/// 判断版本是否满足约束字符串
/// 支持：^x.y.z, ~x.y.z, >=x.y.z, >x.y.z, <=x.y.z, <x.y.z, =x.y.z, x.y.z
pub fn satisfies(version : Version, constraint : String) -> Bool {
  let c = trim(constraint)
  if c.length() == 0 {
    return false
  }

  // ^ 兼容版本
  if starts_with(c, "^") {
    let v_str = trim(substring(c, 1, c.length() - 1))
    match parse_version(v_str) {
      Ok(base) => satisfies_caret(version, base)
      Err(_) => false
    }
  } else if starts_with(c, "~>") {
    // ~> 近似版本（MoonBit 风格，等价于 ~）
    let v_str = trim(substring(c, 2, c.length() - 2))
    match parse_version(v_str) {
      Ok(base) => satisfies_tilde(version, base)
      Err(_) => false
    }
  } else if starts_with(c, "~") {
    // ~ 近似版本
    let v_str = trim(substring(c, 1, c.length() - 1))
    match parse_version(v_str) {
      Ok(base) => satisfies_tilde(version, base)
      Err(_) => false
    }
  } else if starts_with(c, ">=") {
    let v_str = trim(substring(c, 2, c.length() - 2))
    match parse_version(v_str) {
      Ok(base) => compare(version, base) >= 0
      Err(_) => false
    }
  } else if starts_with(c, ">") {
    let v_str = trim(substring(c, 1, c.length() - 1))
    match parse_version(v_str) {
      Ok(base) => compare(version, base) > 0
      Err(_) => false
    }
  } else if starts_with(c, "<=") {
    let v_str = trim(substring(c, 2, c.length() - 2))
    match parse_version(v_str) {
      Ok(base) => compare(version, base) <= 0
      Err(_) => false
    }
  } else if starts_with(c, "<") {
    let v_str = trim(substring(c, 1, c.length() - 1))
    match parse_version(v_str) {
      Ok(base) => compare(version, base) < 0
      Err(_) => false
    }
  } else if starts_with(c, "=") {
    let v_str = trim(substring(c, 1, c.length() - 1))
    match parse_version(v_str) {
      Ok(base) => compare(version, base) == 0
      Err(_) => false
    }
  } else {
    // 裸版本号，精确匹配
    match parse_version(c) {
      Ok(base) => compare(version, base) == 0
      Err(_) => false
    }
  }
}

// ---------- 内部辅助 ----------

///|
fn char_at(s : String, i : Int) -> Char {
  s[i].to_int().unsafe_to_char()
}

///|
fn satisfies_caret(version : Version, base : Version) -> Bool {
  if version.major != base.major {
    return false
  }
  if base.major == 0 {
    // ^0.y.z 行为类似 ~0.y.z：只允许 patch 升级
    if version.minor != base.minor {
      return false
    }
    if version.patch < base.patch {
      return false
    }
    return true
  }
  // ^x.y.z (x > 0)：允许 minor 和 patch 升级，不允许 major 升级
  if version.minor < base.minor {
    return false
  }
  if version.minor == base.minor && version.patch < base.patch {
    return false
  }
  true
}

///|
fn satisfies_tilde(version : Version, base : Version) -> Bool {
  if version.major != base.major {
    return false
  }
  if version.minor != base.minor {
    return false
  }
  version.patch >= base.patch
}

///|
fn compare_prerelease(p1 : String, p2 : String) -> Int {
  let parts1 = split_by_dot(p1)
  let parts2 = split_by_dot(p2)
  let len = if parts1.length() < parts2.length() {
    parts1.length()
  } else {
    parts2.length()
  }
  let mut i = 0
  while i < len {
    let n1 = parse_int(parts1[i])
    let n2 = parse_int(parts2[i])
    match (n1, n2) {
      (Some(v1), Some(v2)) =>
        if v1 != v2 {
          return if v1 < v2 { -1 } else { 1 }
        }
      (Some(_), None) => return -1 // 数字 < 字符串
      (None, Some(_)) => return 1
      (None, None) => {
        let cmp = compare_string(parts1[i], parts2[i])
        if cmp != 0 {
          return cmp
        }
      }
    }
    i = i + 1
  }
  if parts1.length() == parts2.length() {
    0
  } else if parts1.length() < parts2.length() {
    -1
  } else {
    1
  }
}

///|
fn compare_string(s1 : String, s2 : String) -> Int {
  let len = if s1.length() < s2.length() { s1.length() } else { s2.length() }
  let mut i = 0
  while i < len {
    if char_at(s1, i) != char_at(s2, i) {
      return if char_at(s1, i) < char_at(s2, i) { -1 } else { 1 }
    }
    i = i + 1
  }
  if s1.length() == s2.length() {
    0
  } else if s1.length() < s2.length() {
    -1
  } else {
    1
  }
}

///|
fn index_of_char(s : String, ch : Char) -> Int {
  let mut i = 0
  while i < s.length() {
    if char_at(s, i) == ch {
      return i
    }
    i = i + 1
  }
  -1
}

///|
fn split_by_dot(s : String) -> Array[String] {
  let result : Array[String] = []
  let mut current = ""
  let mut i = 0
  while i < s.length() {
    if char_at(s, i) == '.' {
      result.push(current)
      current = ""
    } else {
      current = current + char_at(s, i).to_string()
    }
    i = i + 1
  }
  result.push(current)
  result
}

///|
fn parse_int(s : String) -> Int? {
  if s.length() == 0 {
    return None
  }
  let mut sign = 1
  let mut start = 0
  if char_at(s, 0) == '-' {
    sign = -1
    start = 1
  }
  let mut result = 0
  let mut i = start
  while i < s.length() {
    let ch = char_at(s, i)
    if ch < '0' || ch > '9' {
      return None
    }
    result = result * 10 + (ch.to_int() - '0'.to_int())
    i = i + 1
  }
  Some(sign * result)
}

///|
fn trim(s : String) -> String {
  let mut start = 0
  let mut end = s.length()
  while start < end && is_whitespace(char_at(s, start)) {
    start = start + 1
  }
  while end > start && is_whitespace(char_at(s, end - 1)) {
    end = end - 1
  }
  substring(s, start, end - start)
}

///|
fn is_whitespace(ch : Char) -> Bool {
  ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r'
}

///|
fn starts_with(s : String, prefix : String) -> Bool {
  if s.length() < prefix.length() {
    return false
  }
  let mut i = 0
  while i < prefix.length() {
    if char_at(s, i) != char_at(prefix, i) {
      return false
    }
    i = i + 1
  }
  true
}
