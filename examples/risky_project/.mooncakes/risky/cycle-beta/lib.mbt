///|
/// Beta 组件：与 cycle-alpha 互相依赖，用于演示循环依赖检测场景。
pub fn beta_hello(name : String) -> String {
  "Beta: " + name
}

pub fn beta_compute(n : Int) -> Int {
  n + 42
}

pub struct BetaConfig {
  enabled : Bool
}

pub fn BetaConfig::default() -> BetaConfig {
  { enabled: true }
}
