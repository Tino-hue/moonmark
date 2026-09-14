///|
/// UNUSED-001 未使用依赖检测单测
/// 覆盖：声明但未引用 → Warning；直接引用 / 子包引用 → 无诊断；空声明 → 无诊断。

///|
test "unused detects declared but never imported dep" {
  let declared : Map[String, String] = {
    "risky/gpl-lib": "1.0.0",
    "risky/used-lib": "1.0.0",
  }
  let used = ["risky/used-lib"]
  let diags = unused_dep_diagnostics("root@1.0.0", declared, used)
  assert_true(diags.length() == 1)
  assert_true(diags[0].code == "UNUSED-001")
  assert_true(diags[0].is_warning())
  assert_true(diags[0].path == ["root@1.0.0", "risky/gpl-lib"])
}

///|
test "unused exact import marks dep as used" {
  let declared : Map[String, String] = { "moonbitlang/core": "0.1.0" }
  let used = ["moonbitlang/core"]
  let diags = unused_dep_diagnostics("root@1.0.0", declared, used)
  assert_true(diags.is_empty())
}

///|
test "unused sub-package import marks parent dep as used" {
  let declared : Map[String, String] = { "moonbitlang/x": "0.2.0" }
  let used = ["moonbitlang/x/time"]
  let diags = unused_dep_diagnostics("root@1.0.0", declared, used)
  assert_true(diags.is_empty())
}

///|
test "unused empty declared returns no diagnostics" {
  let declared : Map[String, String] = Map([])
  let used = ["anything/pkg"]
  let diags = unused_dep_diagnostics("root@1.0.0", declared, used)
  assert_true(diags.is_empty())
}
