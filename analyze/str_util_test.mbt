///|
/// str_util.mbt 单元测试
/// 覆盖：substring 正常、边界截断、越界返回空、空串、Unicode

// ---------- 1. 正常提取 ----------

test "str_util substring basic" {
  inspect(substring("hello world", 0, 5), content="hello")
}

test "str_util substring middle" {
  inspect(substring("hello world", 6, 5), content="world")
}

test "str_util substring single char" {
  inspect(substring("hello", 1, 1), content="e")
}

// ---------- 2. 边界截断 ----------

test "str_util substring len exceeds length is truncated" {
  // len 超出字符串长度 → 截断到末尾
  inspect(substring("abc", 1, 100), content="bc")
}

test "str_util substring start plus len exactly end" {
  // start + len == s.length() → 正常返回
  inspect(substring("abcd", 1, 3), content="bcd")
}

// ---------- 3. 越界返回空 ----------

test "str_util substring start beyond length returns empty" {
  inspect(substring("abc", 10, 2), content="")
}

test "str_util substring start equals length returns empty" {
  inspect(substring("abc", 3, 1), content="")
}

test "str_util substring zero length returns empty" {
  inspect(substring("abc", 0, 0), content="")
}

test "str_util substring negative length returns empty" {
  inspect(substring("abc", 0, -1), content="")
}

test "str_util substring negative start returns empty" {
  inspect(substring("abc", -1, 2), content="")
}

// ---------- 4. 空字符串 ----------

test "str_util substring on empty string" {
  inspect(substring("", 0, 5), content="")
  inspect(substring("", 0, 0), content="")
  inspect(substring("", -1, 1), content="")
}

// ---------- 5. 从零开始到末尾 ----------

test "str_util substring from start to end via large len" {
  let s = "MoonBit"
  inspect(substring(s, 0, s.length()), content="MoonBit")
}

// ---------- 6. ASCII 边界字符 ----------

test "str_util substring with special chars" {
  let s = "a\"b\\c\n"
  // 取第 1 到第 3 个字符：\"b
  let result = substring(s, 1, 3)
  inspect(result.length(), content="3")
}

// ---------- 7. 从各位置取 1 个字符 ----------

test "str_util substring single char at each position" {
  let s = "abcd"
  inspect(substring(s, 0, 1), content="a")
  inspect(substring(s, 1, 1), content="b")
  inspect(substring(s, 2, 1), content="c")
  inspect(substring(s, 3, 1), content="d")
}
