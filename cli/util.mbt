/// CLI 通用小工具：字符串 / 数组 / 节点 ID 处理。

///|
/// 在字符串中查找字符，返回索引（-1 表示未找到）
fn str_find_at(s : String, ch : UInt16) -> Int {
  let mut i = 0
  while i < s.length() {
    if s[i] == ch {
      return i
    }
    i = i + 1
  }
  -1
}

///|
/// 统计数组中满足条件的元素数量
fn[T] count_if(arr : Array[T], pred : (T) -> Bool) -> Int {
  let mut count = 0
  for item in arr {
    if pred(item) {
      count = count + 1
    }
  }
  count
}

///|
fn str_array_contains(arr : Array[String], s : String) -> Bool {
  for item in arr {
    if item == s {
      return true
    }
  }
  false
}

///|
fn split_node_id(node_id : String) -> (String, String) {
  let idx = str_find_at(node_id, '@')
  if idx >= 0 {
    let name = node_id[0:idx].to_owned()
    let version = node_id[idx + 1:node_id.length()].to_owned()
    (name, version)
  } else {
    (node_id, "unknown")
  }
}

///|
pub fn is_major_update(current : String, latest : String) -> Bool {
  match (@analyze.parse_version(current), @analyze.parse_version(latest)) {
    (Ok(v1), Ok(v2)) => v1.major != v2.major
    _ => false
  }
}

///|
fn pad_right(s : String, width : Int) -> String {
  let mut result = s
  while result.length() < width {
    result = result + " "
  }
  result
}

///|
fn repeat_str(s : String, n : Int) -> String {
  let mut result = ""
  let mut i = 0
  while i < n {
    result = result + s
    i = i + 1
  }
  result
}
