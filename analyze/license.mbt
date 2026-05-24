/// 许可证检测结果
pub struct LicenseInfo {
  spdx_id : String
  name : String
  is_high_risk : Bool
} derive(Debug)

/// 从许可证文本中检测 SPDX 标识符（基于关键词匹配）
pub fn detect_license(text : String) -> String? {
  let t = to_lower(text)
  // 优先检查强 copyleft，避免被宽松协议误覆盖
  if contains_any(t, ["affero general public license", "agpl v3", "agpl-3.0"]) {
    return Some("AGPL-3.0")
  }
  if contains_any(t, ["server side public license", "sspl v1", "sspl-1.0"]) {
    return Some("SSPL-1.0")
  }
  if contains(t, "gnu general public license") &&
    not_contains(t, "lesser") &&
    not_contains(t, "affero") {
    return Some("GPL-3.0")
  }
  if contains_any(t, ["gnu lesser general public license", "lgpl v3", "lgpl-3.0"]) {
    return Some("LGPL-3.0")
  }
  if contains_any(t, ["apache license", "version 2.0", "apache-2.0", "licensed under the apache license"]) {
    return Some("Apache-2.0")
  }
  if contains(t, "mit license") || contains(t, "permission is hereby granted, free of charge") {
    return Some("MIT")
  }
  if contains_any(t, ["bsd 3-clause", "three-clause bsd", "redistribution and use in source and binary forms"]) {
    return Some("BSD-3-Clause")
  }
  if contains_any(t, ["bsd 2-clause", "two-clause bsd", "simplified bsd license"]) {
    return Some("BSD-2-Clause")
  }
  if contains_any(t, ["mozilla public license", "mpl 2.0", "mozilla public license 2.0"]) {
    return Some("MPL-2.0")
  }
  if contains_any(t, ["isc license", "permission to use, copy, modify, and/or distribute"]) {
    return Some("ISC")
  }
  if contains_any(t, ["unlicense", "this is free and unencumbered software", "public domain dedication"]) {
    return Some("Unlicense")
  }
  if contains_any(t, ["cc0 1.0", "creative commons zero", "cc0-1.0"]) {
    return Some("CC0-1.0")
  }
  // 兜底：提取 SPDX 标签
  match extract_spdx_tag(t) {
    Some(id) => Some(id)
    None => None
  }
}

/// 判断是否为高风险强 copyleft 协议
pub fn is_high_risk_license(spdx_id : String) -> Bool {
  match spdx_id {
    "GPL-3.0" | "GPL-2.0" | "AGPL-3.0" | "AGPL-2.0" | "SSPL-1.0" => true
    _ => false
  }
}

/// 获取许可证的友好名称
pub fn license_name(spdx_id : String) -> String {
  match spdx_id {
    "MIT" => "MIT License"
    "Apache-2.0" => "Apache License 2.0"
    "BSD-3-Clause" => "BSD 3-Clause License"
    "BSD-2-Clause" => "BSD 2-Clause License"
    "GPL-3.0" => "GNU General Public License v3.0"
    "GPL-2.0" => "GNU General Public License v2.0"
    "AGPL-3.0" => "GNU Affero General Public License v3.0"
    "LGPL-3.0" => "GNU Lesser General Public License v3.0"
    "MPL-2.0" => "Mozilla Public License 2.0"
    "ISC" => "ISC License"
    "SSPL-1.0" => "Server Side Public License v1.0"
    "Unlicense" => "The Unlicense"
    "CC0-1.0" => "Creative Commons Zero v1.0 Universal"
    _ => "Unknown License"
  }
}

// ---------- 内部辅助 ----------

fn to_lower(s : String) -> String {
  let mut result = ""
  let mut i = 0
  while i < s.length() {
    let code = s[i].to_int()
    if code >= 65 && code <= 90 {
      result = result + (code + 32).unsafe_to_char().to_string()
    } else {
      result = result + code.unsafe_to_char().to_string()
    }
    i = i + 1
  }
  result
}

fn contains(haystack : String, needle : String) -> Bool {
  if needle.length() == 0 { return true }
  if needle.length() > haystack.length() { return false }
  let max = haystack.length() - needle.length()
  let mut i = 0
  while i <= max {
    if starts_at(haystack, needle, i) { return true }
    i = i + 1
  }
  false
}

fn not_contains(haystack : String, needle : String) -> Bool {
  contains(haystack, needle) == false
}

fn contains_any(haystack : String, needles : Array[String]) -> Bool {
  for needle in needles {
    if contains(haystack, needle) { return true }
  }
  false
}

fn starts_at(haystack : String, needle : String, start : Int) -> Bool {
  let mut j = 0
  while j < needle.length() {
    if haystack[start + j] != needle[j] { return false }
    j = j + 1
  }
  true
}

fn extract_spdx_tag(text : String) -> String? {
  let lower = to_lower(text)
  let marker = "spdx-license-identifier:"
  let idx = index_of_string(lower, marker)
  if idx < 0 { return None }
  let start = idx + marker.length()
  let end = find_line_end(lower, start)
  let raw = substring(text, start, end - start) // 从原始文本提取，保持大小写
  let trimmed = trim(raw)
  if trimmed.length() == 0 { return None }
  Some(trimmed)
}

fn index_of_string(s : String, sub : String) -> Int {
  if sub.length() == 0 { return 0 }
  if sub.length() > s.length() { return -1 }
  let max = s.length() - sub.length()
  let mut i = 0
  while i <= max {
    if starts_at(s, sub, i) { return i }
    i = i + 1
  }
  -1
}

fn find_line_end(s : String, start : Int) -> Int {
  let mut i = start
  while i < s.length() {
    let ch = s[i].to_int()
    if ch == 10 || ch == 13 { return i }
    i = i + 1
  }
  s.length()
}

fn substring(s : String, start : Int, len : Int) -> String {
  if start < 0 || len <= 0 || start >= s.length() { return "" }
  let end = if start + len > s.length() { s.length() } else { start + len }
  let mut result = ""
  let mut i = start
  while i < end {
    result = result + s[i].to_int().unsafe_to_char().to_string()
    i = i + 1
  }
  result
}

fn trim(s : String) -> String {
  if s.length() == 0 { return "" }
  let mut start = 0
  let mut end = s.length()
  while start < end {
    let ch = s[start].to_int()
    if ch == 32 || ch == 9 || ch == 10 || ch == 13 {
      start = start + 1
    } else {
      break
    }
  }
  while end > start {
    let ch = s[end - 1].to_int()
    if ch == 32 || ch == 9 || ch == 10 || ch == 13 {
      end = end - 1
    } else {
      break
    }
  }
  if start >= end { return "" }
  substring(s, start, end - start)
}
