///|
/// Alpha 组件：与 cycle-beta 互相依赖，用于演示循环依赖检测场景。
pub fn alpha_hello(name : String) -> String {
  "Alpha: " + name
}

pub fn alpha_compute(n : Int) -> Int {
  n * n
}

pub struct AlphaState {
  counter : Int
}

pub fn AlphaState::new() -> AlphaState {
  { counter: 0 }
}
