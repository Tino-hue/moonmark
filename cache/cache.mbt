/// 文件系统抽象接口，用于支持测试 mock 和不同平台
pub struct FileSystem {
  read_file : (String) -> String?
  write_file : (String, String) -> Unit
  exists : (String) -> Bool
  readdir : (String) -> Array[String]?
  stat_mtime : (String) -> Double?
  unlink : (String) -> Unit
  rmdir : (String) -> Unit
  mkdir : (String) -> Unit
  timestamp_ms : () -> Double
}

/// 缓存管理器：本地文件缓存，支持 TTL 和过期清理
pub struct CacheManager {
  dir : String
  ttl_ms : Double
  fs : FileSystem
}

let default_ttl_ms : Double = 86400000.0

/// 创建缓存管理器
pub fn CacheManager::new(dir : String, fs : FileSystem, ttl_ms~ : Double = default_ttl_ms) -> CacheManager {
  { dir, ttl_ms, fs }
}

/// 读取缓存内容。若缓存不存在或已过期，返回 None。
pub fn CacheManager::get(self : CacheManager, key : String) -> String? {
  let path = self.cache_file_path(key)
  if (self.fs.exists)(path) == false {
    return None
  }
  match (self.fs.read_file)(path) {
    Some(text) => {
      match deserialize_cache_entry(text) {
        Some((content, timestamp)) => {
          let now = (self.fs.timestamp_ms)()
          if now - timestamp > self.ttl_ms {
            None
          } else {
            Some(content)
          }
        }
        None => None
      }
    }
    None => None
  }
}

/// 写入缓存内容
pub fn CacheManager::set(self : CacheManager, key : String, content : String) -> Unit {
  let path = self.cache_file_path(key)
  (self.fs.mkdir)(self.dir)
  let json = serialize_cache_entry(content, (self.fs.timestamp_ms)())
  (self.fs.write_file)(path, json)
}

/// 清理所有过期的缓存文件
pub fn CacheManager::purge_expired(self : CacheManager) -> Unit {
  match (self.fs.readdir)(self.dir) {
    Some(files) => {
      let now = (self.fs.timestamp_ms)()
      for file in files {
        let path = join_path(self.dir, file)
        match (self.fs.stat_mtime)(path) {
          Some(mtime) => {
            if now - mtime > self.ttl_ms {
              (self.fs.unlink)(path)
            }
          }
          None => ()
        }
      }
    }
    None => ()
  }
}

/// 清理整个缓存目录（包括未过期文件）
pub fn CacheManager::clear(self : CacheManager) -> Unit {
  match (self.fs.readdir)(self.dir) {
    Some(files) => {
      for file in files {
        (self.fs.unlink)(join_path(self.dir, file))
      }
      (self.fs.rmdir)(self.dir)
    }
    None => ()
  }
}

// ---------- 内部辅助 ----------

fn CacheManager::cache_file_path(self : CacheManager, key : String) -> String {
  join_path(self.dir, sanitize_key(key) + ".json")
}

fn sanitize_key(key : String) -> String {
  replace_char(key, '@', '_')
}

fn replace_char(s : String, old : Char, new : Char) -> String {
  let mut result = ""
  let mut i = 0
  while i < s.length() {
    let c = char_at(s, i)
    if c == old {
      result = result + new.to_string()
    } else {
      result = result + c.to_string()
    }
    i = i + 1
  }
  result
}

fn char_at(s : String, i : Int) -> Char {
  s[i].to_int().unsafe_to_char()
}

fn serialize_cache_entry(content : String, timestamp : Double) -> String {
  let parts = [
    "{\"timestamp\":\"", timestamp.to_string(),
    "\",\"content\":\"", escape_json(content), "\"}"
  ]
  join_string_array(parts)
}

fn join_string_array(arr : Array[String]) -> String {
  join_string_array_loop(arr, 0, "")
}

fn join_string_array_loop(arr : Array[String], idx : Int, acc : String) -> String {
  if idx >= arr.length() { return acc }
  join_string_array_loop(arr, idx + 1, acc + arr[idx])
}

fn escape_json(s : String) -> String {
  let parts : Array[String] = []
  let mut i = 0
  while i < s.length() {
    let c = char_at(s, i)
    if c == '"' {
      parts.push("\\\"")
    } else if c == '\\' {
      parts.push("\\\\")
    } else if c == '\n' {
      parts.push("\\n")
    } else if c == '\r' {
      parts.push("\\r")
    } else if c == '\t' {
      parts.push("\\t")
    } else {
      parts.push(c.to_string())
    }
    i = i + 1
  }
  join_string_array(parts)
}

fn deserialize_cache_entry(text : String) -> (String, Double)? {
  let json = try {
    @json.parse(text)
  } catch {
    _ => return None
  }
  guard json is Object(obj) else { return None }
  let ts_str = match obj.get("timestamp") {
    Some(String(s)) => s
    _ => return None
  }
  let content = match obj.get("content") {
    Some(String(s)) => s
    _ => return None
  }
  match parse_double(ts_str) {
    Some(ts) => Some((content, ts))
    None => None
  }
}

fn parse_double(s : String) -> Double? {
  if s.length() == 0 { return None }
  let mut result : Double = 0.0
  let mut i = 0
  while i < s.length() {
    let c = char_at(s, i)
    if c < '0' || c > '9' { return None }
    let digit : Double = (c.to_int() - '0'.to_int()).to_double()
    result = result * 10.0 + digit
    i = i + 1
  }
  Some(result)
}

// ---------- Node.js FFI (JS target only) ----------

extern "js" fn fs_read_file_sync(path : String) -> String? =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     return fs.readFileSync(path, 'utf8');
  #|   } catch (e) {
  #|     return undefined;
  #|   }
  #| }

extern "js" fn fs_write_file_sync(path : String, content : String) -> Unit =
  #| (path, content) => {
  #|   const fs = require('fs');
  #|   const path_mod = require('path');
  #|   const dir = path_mod.dirname(path);
  #|   if (!fs.existsSync(dir)) {
  #|     fs.mkdirSync(dir, { recursive: true });
  #|   }
  #|   fs.writeFileSync(path, content, 'utf8');
  #| }

extern "js" fn fs_exists_sync(path : String) -> Bool =
  #| (path) => {
  #|   const fs = require('fs');
  #|   return fs.existsSync(path);
  #| }

extern "js" fn fs_readdir_sync(path : String) -> Array[String]? =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     return { $tag: 1, _0: fs.readdirSync(path) };
  #|   } catch (e) {
  #|     return { $tag: 0 };
  #|   }
  #| }

extern "js" fn fs_stat_mtime_sync(path : String) -> Double? =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     return { $tag: 1, _0: fs.statSync(path).mtimeMs };
  #|   } catch (e) {
  #|     return { $tag: 0 };
  #|   }
  #| }

extern "js" fn fs_unlink_sync(path : String) -> Unit =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     fs.unlinkSync(path);
  #|   } catch (e) {}
  #| }

extern "js" fn fs_rmdir_sync(path : String) -> Unit =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     fs.rmdirSync(path);
  #|   } catch (e) {}
  #| }

extern "js" fn fs_mkdir_sync(path : String) -> Unit =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     fs.mkdirSync(path, { recursive: true });
  #|   } catch (e) {}
  #| }

extern "js" fn get_timestamp_ms() -> Double =
  #| () => Date.now()

extern "js" fn os_homedir() -> String =
  #| () => require('os').homedir()

extern "js" fn path_join(a : String, b : String) -> String =
  #| (a, b) => require('path').join(a, b)

extern "js" fn path_sep() -> String =
  #| () => require('path').sep

/// 返回平台路径分隔符（Windows 为 "\\"，Unix 为 "/"）
pub fn platform_path_sep() -> String {
  path_sep()
}

/// 返回用户主目录路径（跨平台）
pub fn platform_home_dir() -> String {
  os_homedir()
}

/// 创建基于 Node.js 的文件系统实现
pub fn FileSystem::node_js() -> FileSystem {
  {
    read_file: fs_read_file_sync,
    write_file: fs_write_file_sync,
    exists: fs_exists_sync,
    readdir: fs_readdir_sync,
    stat_mtime: fs_stat_mtime_sync,
    unlink: fs_unlink_sync,
    rmdir: fs_rmdir_sync,
    mkdir: fs_mkdir_sync,
    timestamp_ms: get_timestamp_ms,
  }
}

/// 返回默认缓存目录路径：OS 标准路径
/// Windows: %USERPROFILE%\.depsight\cache
/// Linux/macOS: ~/.depsight/cache
pub fn default_cache_dir() -> String {
  path_join(path_join(os_homedir(), ".depsight"), "cache")
}

/// 跨平台路径拼接
pub fn join_path(a : String, b : String) -> String {
  path_join(a, b)
}
