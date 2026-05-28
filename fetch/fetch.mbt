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
