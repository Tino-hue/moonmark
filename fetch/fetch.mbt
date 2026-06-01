/// 包注册表：包名 -> 仓库地址
pub struct Registry {
  packages : Map[String, String]
  mut cache : @cache.CacheManager?
}

/// 创建空注册表
pub fn Registry::new() -> Registry {
  { packages: {}, cache: None }
}

/// 配置缓存管理器
pub fn Registry::with_cache(self : Registry, cache : @cache.CacheManager) -> Registry {
  self.cache = Some(cache)
  self
}

/// 添加包映射
pub fn Registry::add(self : Registry, name : String, repo : String) -> Unit {
  self.packages[name] = repo
}

/// 从注册表获取包元数据（原始字符串）。
/// 先尝试缓存，再尝试网络。
/// `offline` 为 true 时，仅使用缓存，不请求网络。
/// `http_get` 是平台相关的请求函数，如 JS FFI 或 mock。
pub fn Registry::fetch(
  self : Registry,
  http_get : (String) -> Result[String, String],
  name : String,
  version : String,
  offline : Bool
) -> Result[String, String] {
  let cache_key = name + "@" + version

  // 1. 尝试读缓存
  match self.cache {
    Some(cm) => {
      match cm.get(cache_key) {
        Some(content) => return Ok(content)
        None => ()
      }
    }
    None => ()
  }

  // 2. 离线模式：缓存未命中则报错
  if offline {
    return Err("Offline mode: cache miss for " + cache_key)
  }

  // 3. 网络请求
  match self.packages.get(name) {
    Some(repo) => {
      match fetch_package_meta(http_get, name, version, repo) {
        Ok(content) => {
          // 4. 写入缓存
          match self.cache {
            Some(cm) => cm.set(cache_key, content)
            None => ()
          }
          Ok(content)
        }
        Err(e) => Err(e)
      }
    }
    None => Err("Unknown package: " + name)
  }
}

/// 直接通过仓库地址获取包元数据。
pub fn fetch_package_meta(
  http_get : (String) -> Result[String, String],
  name : String,
  version : String,
  repo : String
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

/// 将 GitHub 仓库地址转为 raw.githubusercontent.com 直链
pub fn build_github_raw_url(repo : String, branch : String, file : String) -> String {
  let prefix = "https://github.com/"
  if starts_with(repo, prefix) {
    let path = strip_prefix(repo, prefix)
    "https://raw.githubusercontent.com/" + path + "/" + branch + "/" + file
  } else {
    repo + "/" + branch + "/" + file
  }
}

fn starts_with(s : String, prefix : String) -> Bool {
  if s.length() < prefix.length() { return false }
  starts_with_loop(s, prefix, 0)
}

fn starts_with_loop(s : String, prefix : String, idx : Int) -> Bool {
  if idx >= prefix.length() { return true }
  if s[idx] != prefix[idx] { return false }
  starts_with_loop(s, prefix, idx + 1)
}

fn strip_prefix(s : String, prefix : String) -> String {
  if starts_with(s, prefix) == false {
    return s
  }
  strip_prefix_loop(s, prefix.length(), 0, "")
}

fn strip_prefix_loop(s : String, start : Int, idx : Int, acc : String) -> String {
  let pos = start + idx
  if pos >= s.length() { return acc }
  let ch = s[pos].to_int().unsafe_to_char()
  strip_prefix_loop(s, start, idx + 1, acc + ch.to_string())
}

// ---------- HTTP FFI ----------

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

// ---------- 默认包映射 ----------

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

/// 将预置的常见包仓库映射填入注册表。
pub fn Registry::with_defaults(self : Registry) -> Registry {
  for name, repo in default_package_repos() {
    self.packages[name] = repo
  }
  self
}
