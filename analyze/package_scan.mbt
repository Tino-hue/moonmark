///|
/// 包扫描工具：将 LICENSE 文件扫描、真实体积归因、废弃 API 检测
/// 三大能力集成到审计流程中。这些函数读取本地 `.mooncakes` 缓存中的
/// 包目录，以避免远程访问。

// ========== 公共 API ==========

///|
pub fn scan_license_from_dir(
  package_dir : String,
  fs : @cache.FileSystem,
  fallback_license : String?,
) -> String? {
  match fallback_license {
    Some(lic) => return Some(lic)
    None => ()
  }
  let candidates = [
    "LICENSE", "LICENSE.md", "LICENSE.txt", "license", "license.md", "COPYING", "COPYING.md",
  ]
  for name in candidates {
    let path = package_dir + "/" + name
    match (fs.read_file)(path) {
      Some(content) =>
        match detect_license(content) {
          Some(id) => return Some(id)
          None => ()
        }
      None => ()
    }
  }
  None
}

///|
pub fn compute_self_size_from_dir(
  package_dir : String,
  fs : @cache.FileSystem,
) -> Int {
  match (fs.readdir)(package_dir) {
    Some(entries) => {
      let mut total = 0
      for entry in entries {
        if ends_with_string(entry, ".mbt") {
          let path = package_dir + "/" + entry
          match (fs.read_file)(path) {
            Some(content) => total = total + content.length()
            None => ()
          }
        }
      }
      total
    }
    None => 0
  }
}

///|
pub fn scan_deprecated_from_dir(
  package_dir : String,
  fs : @cache.FileSystem,
) -> Array[DeprecatedApi] {
  let all_apis : Array[DeprecatedApi] = []
  match (fs.readdir)(package_dir) {
    Some(entries) =>
      for entry in entries {
        if ends_with_string(entry, ".mbt") &&
          !ends_with_string(entry, "_wbtest.mbt") &&
          !ends_with_string(entry, "_test.mbt") &&
          !ends_with_string(entry, "_bench_test.mbt") {
          let path = package_dir + "/" + entry
          match (fs.read_file)(path) {
            Some(content) => {
              let apis = scan_deprecated_apis(content)
              for api in apis {
                all_apis.push(api)
              }
            }
            None => ()
          }
        }
      }
    None => ()
  }
  all_apis
}

///|
pub fn build_realistic_node_meta(
  package_dir : String,
  fallback_license : String?,
  fs : @cache.FileSystem,
  latest_version : String?,
  last_commit_days_ago : Int?,
) -> NodeMeta {
  let license = scan_license_from_dir(package_dir, fs, fallback_license)
  let size = compute_self_size_from_dir(package_dir, fs)
  let deprecated_apis = scan_deprecated_from_dir(package_dir, fs)
  NodeMeta::new(
    license~,
    deprecated_apis~,
    latest_version~,
    self_size=size,
    last_commit_days_ago~,
  )
}

///|
pub fn locate_package_dir(cache_root : String, package_name : String) -> String {
  // 包名格式：owner/name（如 moonbitlang/core）
  // 用 split 后通过 collect 转为数组访问
  let parts = package_name.split("/").collect()
  if parts.length() == 2 {
    cache_root + "/" + parts[0].to_owned() + "/" + parts[1].to_owned()
  } else {
    cache_root + "/" + package_name
  }
}

///|
pub fn estimate_size_from_content(content : String) -> Int {
  let line_count = count_lines(content)
  line_count * 40
}

///|
fn count_lines(s : String) -> Int {
  if s.length() == 0 {
    return 0
  }
  let mut count = 1
  let mut i = 0
  while i < s.length() {
    let ch = s[i].to_int()
    if ch == 10 {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
fn ends_with_string(s : String, suffix : String) -> Bool {
  if suffix.length() > s.length() {
    return false
  }
  let offset = s.length() - suffix.length()
  let mut i = 0
  while i < suffix.length() {
    if s[offset + i].to_int() != suffix[i].to_int() {
      return false
    }
    i = i + 1
  }
  true
}
