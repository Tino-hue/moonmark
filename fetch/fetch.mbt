///|
/// 包注册表：包名 -> 仓库地址
pub struct Registry {
  packages : Map[String, String]
  mut cache : @cache.CacheManager?
}

///|
/// 创建空注册表
pub fn Registry::new() -> Registry {
  { packages: {}, cache: None }
}

///|
/// 配置缓存管理器
pub fn Registry::with_cache(
  self : Registry,
  cache : @cache.CacheManager,
) -> Registry {
  self.cache = Some(cache)
  self
}

///|
/// 添加包映射
pub fn Registry::add(self : Registry, name : String, repo : String) -> Unit {
  self.packages[name] = repo
}

///|
/// 从注册表获取包元数据（原始字符串）。
/// 先尝试缓存，再尝试网络。
/// `offline` 为 true 时，仅使用缓存，不请求网络。
/// `http_get` 是平台相关的请求函数，如 JS FFI 或 mock。
pub fn Registry::fetch(
  self : Registry,
  http_get : (String) -> Result[String, String],
  name : String,
  version : String,
  offline : Bool,
) -> Result[String, String] {
  let cache_key = name + "@" + version

  // 1. 尝试读缓存
  match self.cache {
    Some(cm) =>
      match cm.get(cache_key) {
        Some(content) => return Ok(content)
        None => ()
      }
    None => ()
  }

  // 2. 离线模式：缓存未命中则报错
  if offline {
    return Err("Offline mode: cache miss for " + cache_key)
  }

  // 3. 多源回退策略
  // 优先级：预定义映射 > GitHub 智能推断 > mooncakes.io 文档页面
  match self.packages.get(name) {
    Some(repo) =>
      match fetch_package_meta(http_get, name, version, repo) {
        Ok(content) => {
          // 4. 写入缓存
          match self.cache {
            Some(cm) => cm.set(cache_key, content)
            None => ()
          }
          Ok(content)
        }
        Err(e) =>
          // 预定义映射失败，尝试智能推断
          match try_infer_github_repo(http_get, name, version) {
            Ok(content) => {
              match self.cache {
                Some(cm) => cm.set(cache_key, content)
                None => ()
              }
              Ok(content)
            }
            Err(_) => Err(e)
          }
      }
    None =>
      // 未知包，尝试智能推断
      match try_infer_github_repo(http_get, name, version) {
        Ok(content) => {
          match self.cache {
            Some(cm) => cm.set(cache_key, content)
            None => ()
          }
          Ok(content)
        }
        Err(_) =>
          Err(
            "Unknown package: " +
            name +
            ". Use --verbose to see inference attempts.",
          )
      }
  }
}

///|
/// 直接通过仓库地址获取包元数据。
pub fn fetch_package_meta(
  http_get : (String) -> Result[String, String],
  name : String,
  version : String,
  repo : String,
) -> Result[String, String] {
  let url = build_github_raw_url(repo, "main", "moon.mod.json")
  match http_get(url) {
    Ok(content) => Ok(content)
    Err(e) => {
      let url2 = build_github_raw_url(repo, "master", "moon.mod.json")
      match http_get(url2) {
        Ok(content) => Ok(content)
        Err(_) => Err("Failed to fetch " + name + "@" + version + ": " + e)
      }
    }
  }
}

// ---------- 内部辅助 ----------

///|
/// 将 GitHub 仓库地址转为 raw.githubusercontent.com 直链
pub fn build_github_raw_url(
  repo : String,
  branch : String,
  file : String,
) -> String {
  let prefix = "https://github.com/"
  if starts_with(repo, prefix) {
    let path = strip_prefix(repo, prefix)
    "https://raw.githubusercontent.com/" + path + "/" + branch + "/" + file
  } else {
    repo + "/" + branch + "/" + file
  }
}

///|
fn starts_with(s : String, prefix : String) -> Bool {
  if s.length() < prefix.length() {
    return false
  }
  starts_with_loop(s, prefix, 0)
}

///|
fn starts_with_loop(s : String, prefix : String, idx : Int) -> Bool {
  if idx >= prefix.length() {
    return true
  }
  if s[idx] != prefix[idx] {
    return false
  }
  starts_with_loop(s, prefix, idx + 1)
}

///|
fn strip_prefix(s : String, prefix : String) -> String {
  if starts_with(s, prefix) == false {
    return s
  }
  strip_prefix_loop(s, prefix.length(), 0, "")
}

///|
fn strip_prefix_loop(
  s : String,
  start : Int,
  idx : Int,
  acc : String,
) -> String {
  let pos = start + idx
  if pos >= s.length() {
    return acc
  }
  let ch = s[pos].to_int().unsafe_to_char()
  strip_prefix_loop(s, start, idx + 1, acc + ch.to_string())
}

// ---------- HTTP FFI ----------

///|
/// 通过 Node.js https 模块发起同步 GET 请求。
/// 内部使用 child_process.execSync 调用内联 node 脚本，完全跨平台。
extern "js" fn http_get_raw(url : String) -> String =
  #| (url) => {
  #|   const { execSync } = require('child_process');
  #|   const safeUrl = url.replace(/'/g, "\\'");
  #|   const script = "const https=require('https');https.get('" + safeUrl + "',(r)=>{let d='';r.on('data',(c)=>d+=c);r.on('end',()=>process.stdout.write(d));}).on('error',(e)=>process.stdout.write('__HTTP_ERROR__'+e.message));";
  #|   try {
  #|     return execSync('node -e "' + script.replace(/"/g, '\\"') + '"', { encoding: 'utf8', timeout: 12000, maxBuffer: 1024 * 1024 });
  #|   } catch (e) {
  #|     return '__HTTP_ERROR__' + (e.message || 'exec failed');
  #|   }
  #| }

///|
/// 发起 HTTP GET 请求，返回响应体或错误。
pub fn http_get(url : String) -> Result[String, String] {
  let raw = http_get_raw(url)
  if raw.is_empty() {
    return Err("Empty response from " + url)
  }
  if raw.has_prefix("__HTTP_ERROR__") {
    let msg = raw[14:].to_string()
    return Err("HTTP error: " + msg)
  }
  Ok(raw)
}

// ---------- GitHub 活跃度查询 ----------

///|
/// 从 GitHub 仓库 URL 提取 owner 和 repo 名称
fn extract_repo_owner_repo(repo : String) -> (String, String)? {
  let prefix = "https://github.com/"
  if !starts_with(repo, prefix) {
    return None
  }
  let path = strip_prefix(repo, prefix)
  let parts = split_path(path)
  if parts.length() < 2 {
    return None
  }
  Some((parts[0], parts[1]))
}

///|
fn split_path(path : String) -> Array[String] {
  let result = []
  let mut start = 0
  for i = 0; i < path.length(); i = i + 1 {
    if path[i] == '/' {
      if i > start {
        result.push(path[start:i].to_string())
      }
      start = i + 1
    }
  }
  if start < path.length() {
    result.push(path[start:path.length()].to_string())
  }
  result
}

///|
extern "js" fn js_now_ms() -> Int64 =
  #| () => Date.now()

///|
/// 获取 GitHub 仓库最后提交日期距离今天的天数。
/// 通过 GitHub API 获取最近一条 commit 的 committer date。
pub fn fetch_last_commit_days(
  http_get : (String) -> Result[String, String],
  repo_url : String,
) -> Result[Int, String] {
  let (owner, repo_name) = match extract_repo_owner_repo(repo_url) {
    Some(t) => t
    None => return Err("Not a GitHub repo URL: " + repo_url)
  }
  let api_url = "https://api.github.com/repos/" +
    owner +
    "/" +
    repo_name +
    "/commits?per_page=1"
  match http_get(api_url) {
    Ok(body) => {
      // GitHub API 返回 JSON 数组
      let json = @json.parse(body) catch {
        _ => return Err("Invalid JSON from GitHub API")
      }
      guard json is Array(arr) else {
        return Err("Expected JSON array from GitHub API")
      }
      if arr.length() == 0 {
        return Err("No commits found")
      }
      let first = arr[0]
      guard first is Object(commit_obj) else {
        return Err("Invalid commit object")
      }
      let date_str = match commit_obj.get("commit") {
        Some(Object(c)) =>
          match c.get("committer") {
            Some(Object(com)) =>
              match com.get("date") {
                Some(String(d)) => d
                _ => return Err("Missing committer date")
              }
            _ => return Err("Missing committer")
          }
        _ => return Err("Missing commit field")
      }
      match parse_iso_date_to_days_ago(date_str) {
        Ok(days) => Ok(days)
        Err(e) => Err(e)
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// 解析 ISO 8601 日期字符串（如 2026-05-15T10:30:00Z），返回距离今天的天数。
/// 使用 JS Date.now() 作为当前时间。
fn parse_iso_date_to_days_ago(date_str : String) -> Result[Int, String] {
  if date_str.length() < 10 {
    return Err("Date string too short")
  }
  let year_str = date_str[0:4].to_string()
  let month_str = date_str[5:7].to_string()
  let day_str = date_str[8:10].to_string()
  let year = match parse_int_simple(year_str) {
    Some(y) => y
    None => return Err("Invalid year")
  }
  let month = match parse_int_simple(month_str) {
    Some(m) => m
    None => return Err("Invalid month")
  }
  let day = match parse_int_simple(day_str) {
    Some(d) => d
    None => return Err("Invalid day")
  }

  let commit_ts = js_date_to_timestamp(year, month, day)
  let now_ts = js_now_ms()
  if now_ts < commit_ts {
    return Ok(0)
  }
  let diff_ms = now_ts - commit_ts
  let days = (diff_ms / (1000L * 60L * 60L * 24L)).to_int()
  Ok(days)
}

///|
extern "js" fn js_date_to_timestamp(
  year : Int,
  month : Int,
  day : Int,
) -> Int64 =
  #| (y, m, d) => new Date(y, m - 1, d).getTime()

///|
fn parse_int_simple(s : String) -> Int? {
  let mut result = 0
  for i = 0; i < s.length(); i = i + 1 {
    let code = s[i].to_int()
    if code < '0'.to_int() || code > '9'.to_int() {
      return None
    }
    result = result * 10 + (code - '0'.to_int())
  }
  Some(result)
}

// ---------- 智能包名推断 ----------

///|
/// 尝试从包名推断 GitHub 仓库地址。
/// 支持两种命名格式：
///   1. owner/repo 格式（如 moonbitlang/core）
///   2. 纯包名格式（如 mylib）
fn try_infer_github_repo(
  http_get : (String) -> Result[String, String],
  name : String,
  version : String,
) -> Result[String, String] {
  // 策略 1: owner/repo 格式 -> 直接作为 GitHub 仓库
  let parts = split_path(name)
  if parts.length() == 2 {
    let repo_url = "https://github.com/" + parts[0] + "/" + parts[1]
    match fetch_package_meta(http_get, name, version, repo_url) {
      Ok(content) => {
        if starts_with(content, "{") || starts_with(content, "[") {
          return Ok(content)
        }
        Err("Invalid JSON from inferred repo")
      }
      Err(e) => Err("Inference failed for " + name + ": " + e)
    }
  } else {
    // 策略 2: 尝试 moonbitlang/ 前缀
    let moonbit_repo = "https://github.com/moonbitlang/" + name
    match fetch_package_meta(http_get, name, version, moonbit_repo) {
      Ok(content) => {
        if starts_with(content, "{") || starts_with(content, "[") {
          return Ok(content)
        }
        Err("Invalid JSON from moonbitlang namespace")
      }
      Err(_) =>
        // 策略 3: 尝试 moonbit-community/ 前缀
        match
          fetch_package_meta(
            http_get,
            name,
            version,
            "https://github.com/moonbit-community/" + name,
          ) {
          Ok(content) => {
            if starts_with(content, "{") || starts_with(content, "[") {
              return Ok(content)
            }
            Err("Invalid JSON from moonbit-community namespace")
          }
          Err(_) => Err("Could not infer repo for " + name)
        }
    }
  }
}

// ---------- 默认包映射 ----------

///|
fn default_package_repos() -> Map[String, String] {
  let map : Map[String, String] = {}
  map["moonbitlang/core"] = "https://github.com/moonbitlang/core"
  map["moonbitlang/x"] = "https://github.com/moonbitlang/x"
  map["moonbitlang/json5"] = "https://github.com/moonbitlang/json5"
  map["moonbitlang/websocket"] = "https://github.com/moonbitlang/websocket"
  map["moonbitlang/parser-combinator"] = "https://github.com/moonbitlang/parser-combinator"
  map["moonbitlang/regexp"] = "https://github.com/moonbitlang/regexp"
  map["moonbitlang/json"] = "https://github.com/moonbitlang/json"
  map
}

///|
/// 将预置的常见包仓库映射填入注册表。
pub fn Registry::with_defaults(self : Registry) -> Registry {
  for name, repo in default_package_repos() {
    self.packages[name] = repo
  }
  self
}
