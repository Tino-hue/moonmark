///|
/// GPL-3.0 示例库：包含多个公开 API，用于演示高风险许可证场景
pub fn gpl_compute(input : Int) -> Int {
  input * 2 + 1
}

pub fn gpl_hello(name : String) -> String {
  "Hello, " + name + " (GPL-3.0)"
}

pub struct GplConfig {
  verbose : Bool
  timeout_ms : Int
}

pub fn GplConfig::default() -> GplConfig {
  { verbose: false, timeout_ms: 30000 }
}

pub fn gpl_run(config : GplConfig) -> Bool {
  if config.verbose {
    println("Running GPL routine with timeout=" + config.timeout_ms.to_string())
  }
  true
}
