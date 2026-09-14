/// 未使用依赖检测（UNUSED-001）
///
/// 对比 moon.mod 声明的依赖与源码中实际 import 的包名，
/// 找出「声明了但从未被引用」的依赖，帮助清理冗余声明。

///|
/// 生成 UNUSED-001 诊断。
/// `declared` 为 moon.mod 声明的依赖（包名 -> 版本约束），
/// `used` 为源码 moon.pkg / moon.pkg.json 中 import 的包名列表。
/// 匹配规则：某依赖未被任何 used import 直接引用、也未作为其前缀引用时，
/// 判定为未使用。
pub fn unused_dep_diagnostics(
  root_id : String,
  declared : Map[String, String],
  used : Array[String],
) -> Array[@report.Diagnostic] {
  let diags : Array[@report.Diagnostic] = []
  for pair in declared {
    let (dep_name, _) = pair
    if !is_dep_used(dep_name, used) {
      diags.push(
        @report.Diagnostic::warning(
          "UNUSED-001",
          "Dependency '" + dep_name + "' is declared but never imported",
          [root_id, dep_name],
        ).with_suggestion(
          "Remove '" + dep_name + "' from moon.mod if it is no longer needed",
        ),
      )
    }
  }
  diags
}

///|
/// 判断依赖是否被 used 列表中的某个 import 使用：
/// import == dep 或 import 以 dep + "/" 为前缀（子包引用也算使用）。
fn is_dep_used(dep : String, used : Array[String]) -> Bool {
  for imp in used {
    if imp == dep {
      return true
    }
    if imp.has_prefix(dep + "/") {
      return true
    }
  }
  false
}
