///|
/// CLI 工具函数属性测试（QuickCheck）
///
/// 与 cli_test.mbt 的示例式单测互补：在随机输入空间上验证
/// parse_int 与 split_comma_list 的 round-trip 不变量。
/// parse_int 仅接受非负十进制数字串，故生成器限制为非负整数；
/// split_comma_list 按逗号切分并 trim 每段、跳过空段，故生成器使用
/// 不含逗号/空白的 token，确保 join → split 完全还原。

///|
/// 非负整数生成器（限制在 [0, 100000) 提升碰撞率，反例可读）。
priv struct GenNonNegInt {
  value : Int
} derive(Debug)

///|
impl @qc.Arbitrary for GenNonNegInt with fn arbitrary(_size, rs) {
  { value: (rs.next_uint() % 100000U).reinterpret_as_int(), }
}

///|
impl @qc.Shrink for GenNonNegInt

///|
/// 逗号分隔列表生成器：0..5 个不含逗号/空白的 token。
priv struct GenCommaList {
  items : Array[String]
} derive(Debug)

///|
impl @qc.Arbitrary for GenCommaList with fn arbitrary(_size, rs) {
  let n = (rs.next_uint() % 5U).reinterpret_as_int()
  let items : Array[String] = []
  let mut i = 0
  while i < n {
    let token = "tok" + "\{((rs.next_uint() % 100U).reinterpret_as_int())}"
    items.push(token)
    i = i + 1
  }
  { items, }
}

///|
impl @qc.Shrink for GenCommaList

///|
fn GenCommaList::render(self : GenCommaList) -> String {
  let mut s = ""
  let mut i = 0
  while i < self.items.length() {
    if i > 0 {
      s = s + ","
    }
    s = s + self.items[i]
    i = i + 1
  }
  s
}

///|
fn eq_strings(a : Array[String], b : Array[String]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  let mut i = 0
  while i < a.length() {
    if a[i] != b[i] {
      return false
    }
    i = i + 1
  }
  true
}

///|
test "qc: parse_int round-trips rendered non-negative int" {
  @qc.check(
    (g : GenNonNegInt) => {
      match parse_int("\{g.value}") {
        Some(v) => v == g.value
        None => false
      }
    },
    counterexample_context=g => "\{g.value}",
  )
}

///|
test "qc: split_comma_list round-trips comma-joined tokens" {
  @qc.check(
    (g : GenCommaList) => eq_strings(split_comma_list(g.render()), g.items),
    counterexample_context=g => g.render(),
  )
}
