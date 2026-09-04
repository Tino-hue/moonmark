///|
/// 已废弃的库：包含多个 @deprecated 标记的公开 API，用于演示废弃 API 检测

///|
/// @deprecated Since 2.0.0 — use new_fn instead. This function has a known off-by-one bug.
pub fn old_fn(input : Int) -> Int {
  input + 1
}

///|
/// @deprecated Will be removed in v3.0. Use modern_api instead.
pub fn legacy_api(name : String) -> String {
  "Legacy: " + name
}

pub fn new_fn(input : Int) -> Int {
  input * 2
}

pub fn modern_api(name : String) -> String {
  "Modern: " + name
}

pub fn helper() -> String {
  "helper"
}

pub struct OldConfig {
  name : String
  value : Int
}
