pub fn analyze(source : String) -> String {
  "analyzed: " + source
}

pub fn count_functions(source : String) -> Int {
  let parts = source.split("fn ")
  parts.count()
}
