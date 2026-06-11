/// 字符串工具函数

///|
/// 提取子串 [start, start+len)
pub fn substring(s : String, start : Int, len : Int) -> String {
  if start < 0 || len <= 0 || start >= s.length() {
    return ""
  }
  let end = if start + len > s.length() { s.length() } else { start + len }
  let mut result = ""
  let mut i = start
  while i < end {
    let c = s[i].to_int().unsafe_to_char()
    result = result + c.to_string()
    i = i + 1
  }
  result
}
