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
/// 统计单个 MoonBit 源文件中对外公开的 API 数量。
/// 计为一条公共 API 的形态：
///   pub fn / pub let / pub const / pub struct /
///   pub enum / pub trait / pub type
///
/// 实现策略：基于「源码行」的正则风格匹配，足够覆盖绝大多数手写代码场景。
/// 对于多行（将 `pub` 与后续关键字用 `\` 折行）等罕见形态采用保守估计——
/// 不统计也不算错，因为真实代码极少这样写。
/// 注释 / 字符串内的「pub」字样不统计（因为 pub 必须作为 declaration
/// 起始 token 才能被识别，而注释行首以 `//` 或在 `///` 块中，字符串
/// 字面量里也不会把 "pub fn" 放在"行首空白后首个 token"位置。本函数
/// 刻意采用「行首空白后 pub <space> <keyword>」规则，以避免误计。）
pub fn count_public_apis_from_source(source : String) -> Int {
  let lines = split_lines(source)
  let mut count = 0
  let keywords : Array[String] = [
    "fn", "let", "const", "struct", "enum", "trait", "type",
  ]
  let mut i = 0
  while i < lines.length() {
    let line = lines[i]
    // 跳过 doc comment（/// ...）与 block comment 行（// ...），以及空白行
    let trimmed = trim_start(line)
    if trimmed.length() == 0 {
      i = i + 1
      continue
    }
    if starts_with(trimmed, "//") {
      i = i + 1
      continue
    }
    // 在多行注释 /* ... */ 中，这里做简单处理：如果当前行出现 /* 但未成对结束，
    // 就跳过到出现 */。对于 MoonBit 常见写法几乎不会触发，但为严谨保留。
    if contains_sub(trimmed, "/*") && !contains_sub(trimmed, "*/") {
      i = i + 1
      while i < lines.length() {
        let nxt = lines[i]
        if contains_sub(nxt, "*/") {
          break
        }
        i = i + 1
      }
      i = i + 1
      continue
    }
    if starts_with(trimmed, "pub ") {
      let rest = trim_start(substring(trimmed, 4, trimmed.length()))
      for kw in keywords {
        if starts_with(rest, kw) {
          // 确认是完整 keyword：后一个字符必须不是标识符字符
          let after_kw = rest.length() == kw.length() ||
            !is_ident_code(rest[kw.length()])
          if after_kw {
            count = count + 1
            break
          }
        }
      }
    }
    i = i + 1
  }
  count
}

///|
/// 扫描包目录下所有非测试用的 .mbt 文件，汇总公共 API 总数。
/// 过滤后缀：_test.mbt / _wbtest.mbt / _bench_test.mbt（与废弃 API 扫描保持一致）。
pub fn count_public_apis_from_dir(
  package_dir : String,
  fs : @cache.FileSystem,
) -> Int {
  match (fs.readdir)(package_dir) {
    Some(entries) => {
      let mut total = 0
      for entry in entries {
        if ends_with_string(entry, ".mbt") &&
          !ends_with_string(entry, "_wbtest.mbt") &&
          !ends_with_string(entry, "_test.mbt") &&
          !ends_with_string(entry, "_bench_test.mbt") {
          let path = package_dir + "/" + entry
          match (fs.read_file)(path) {
            Some(content) =>
              total = total + count_public_apis_from_source(content)
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
  let total_api_count = count_public_apis_from_dir(package_dir, fs)
  NodeMeta::new(
    license~,
    deprecated_apis~,
    latest_version~,
    self_size=size,
    last_commit_days_ago~,
    total_api_count~,
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

// ---------- 计数相关字符串辅助 ----------

///|
/// 去除左侧空白字符（空格、制表符、换行、回车）
fn trim_start(s : String) -> String {
  let n = s.length()
  let mut i = 0
  while i < n {
    let ch = s[i].to_int()
    if ch == 32 || ch == 9 || ch == 10 || ch == 13 {
      i = i + 1
    } else {
      break
    }
  }
  if i == 0 {
    s
  } else {
    substring(s, i, n - i)
  }
}

///|
fn contains_sub(s : String, needle : String) -> Bool {
  let n = s.length()
  let m = needle.length()
  if m == 0 {
    return true
  }
  if m > n {
    return false
  }
  let mut i = 0
  while i + m <= n {
    let mut j = 0
    while j < m && s[i + j].to_int() == needle[j].to_int() {
      j = j + 1
    }
    if j == m {
      return true
    }
    i = i + 1
  }
  false
}

///|
/// 判断 UTF-16 code unit (UInt16) 是否属于 MoonBit 标识符继续字符：
/// 字母 / 数字 / 下划线。
fn is_ident_code(code : UInt16) -> Bool {
  let i = code.to_int()
  // 'A'..='Z'
  if i >= 65 && i <= 90 {
    return true
  }
  // 'a'..='z'
  if i >= 97 && i <= 122 {
    return true
  }
  // '0'..='9'
  if i >= 48 && i <= 57 {
    return true
  }
  // '_'
  i == 95
}
