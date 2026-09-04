///|
/// 中间层库：自己没有废弃 API，但依赖了 deprecated-lib，
/// 因此会通过传递性把 deprecated API 暴露给上游（触发 DEPRECATED-002 传播诊断）。
pub fn mid_hello(name : String) -> String {
  "Mid: " + name
}

pub fn mid_compute(x : Int, y : Int) -> Int {
  x + y
}

pub struct MidOptions {
  verbose : Bool
}

pub fn MidOptions::default() -> MidOptions {
  { verbose: false }
}

pub fn mid_validate(opts : MidOptions) -> Bool {
  opts.verbose == true || opts.verbose == false
}
