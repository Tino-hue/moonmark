/// CLI 帮助文案。

///|
fn print_help() -> Unit {
  println(help_text())
}

///|
pub fn help_text() -> String {
  let lines : Array[String] = []
  lines.push(@analyze.bold(version_full()))
  lines.push("Dependency health diagnostic tool for MoonBit ecosystem")
  lines.push("")
  lines.push(@analyze.bold("Usage:"))
  lines.push("  depsight <command> [options]")
  lines.push("")
  lines.push(@analyze.bold("Commands:"))
  lines.push("  tree [package]    Show dependency tree")
  lines.push("  audit             Run dependency audit")
  lines.push("  report            Generate full report")
  lines.push("  stats             Show dependency panorama (18+ metrics)")
  lines.push("  outdated          Check for outdated dependencies")
  lines.push("  why <package>     Trace who depends on a package")
  lines.push("  check             Quick health check (CI-friendly)")
  lines.push("")
  lines.push(@analyze.bold("Global Options:"))
  lines.push("  -h, --help        Show help")
  lines.push("  -v, --version     Show version")
  lines.push("  --quiet           Suppress non-essential output")
  lines.push("  --offline         Use local cache only")
  lines.push("  --cache-dir <dir> Set cache directory")
  lines.push("  --dry-run         Simulate without writing files or cache")
  lines.push("  --verbose         Show detailed fetch progress")
  lines.push("")
  lines.push(@analyze.bold("Examples:"))
  lines.push(
    "  depsight tree              # Show dependency tree for root package",
  )
  lines.push("  depsight audit             # Run full dependency audit")
  lines.push("  depsight audit --json      # Output audit results as JSON")
  lines.push("  depsight stats             # Show panorama stats (21 metrics)")
  lines.push("  depsight stats --json      # Stats as machine-readable JSON")
  lines.push("  depsight report --html     # Generate HTML report")
  lines.push("  depsight outdated          # Check for outdated packages")
  lines.push("  depsight why moonbitlang/core  # Who depends on core?")
  lines.push("  depsight check             # Quick health check")
  lines.push("")
  lines.push("Use 'depsight <command> --help' for command-specific options.")
  join_cli_lines(lines)
}

///|
fn print_tree_help() -> Unit {
  println(tree_help_text())
}

///|
pub fn tree_help_text() -> String {
  let lines : Array[String] = []
  lines.push(@analyze.bold("depsight tree — Show dependency tree"))
  lines.push("")
  lines.push(@analyze.bold("Usage:"))
  lines.push("  depsight tree [package]")
  lines.push("")
  lines.push(@analyze.bold("Options:"))
  lines.push("  --depth <n>       Max tree depth (default: 10)")
  lines.push("  --dry-run         Simulate without writing files or cache")
  lines.push("  --verbose         Show detailed fetch progress")
  join_cli_lines(lines)
}

///|
fn print_audit_help() -> Unit {
  println(audit_help_text())
}

///|
pub fn audit_help_text() -> String {
  let lines : Array[String] = []
  lines.push(@analyze.bold("depsight audit — Run dependency audit"))
  lines.push("")
  lines.push(@analyze.bold("Usage:"))
  lines.push("  depsight audit [options]")
  lines.push("")
  lines.push(@analyze.bold("Options:"))
  lines.push("  --json            Output JSON format")
  lines.push(
    "  --sarif           Output SARIF v2.1.0 format (GitHub Code Scanning)",
  )
  lines.push("  --markdown        Output Markdown format")
  lines.push(
    "  --severity <level>   Filter diagnostics: critical, warning, info",
  )
  lines.push("  --baseline <file>    Compare against a previous JSON report")
  lines.push("  --baseline auto      Compare against .depsight-baseline.json")
  lines.push("  --workspace          Scan all packages in workspace")
  lines.push("  --fail-on-score <n>  Exit with error if overall score < n")
  lines.push("  --fail-on-critical   Exit with error if critical issues found")
  lines.push("  --dry-run            Simulate without writing files or cache")
  lines.push("  --verbose            Show detailed fetch progress")
  lines.push("  -o, --output <file>  Write output to file")
  join_cli_lines(lines)
}

///|
fn print_report_help() -> Unit {
  println(report_help_text())
}

///|
pub fn report_help_text() -> String {
  let lines : Array[String] = []
  lines.push(@analyze.bold("depsight report — Generate full report"))
  lines.push("")
  lines.push(@analyze.bold("Usage:"))
  lines.push("  depsight report [options]")
  lines.push("")
  lines.push(@analyze.bold("Options:"))
  lines.push("  --html            Output HTML format")
  lines.push("  --json            Output JSON format")
  lines.push(
    "  --sarif           Output SARIF v2.1.0 format (GitHub Code Scanning)",
  )
  lines.push("  --markdown        Output Markdown format")
  lines.push(
    "  --severity <level>   Filter diagnostics: critical, warning, info",
  )
  lines.push("  --workspace          Scan all packages in workspace")
  lines.push("  --fail-on-score <n>  Exit with error if overall score < n")
  lines.push("  --fail-on-critical   Exit with error if critical issues found")
  lines.push("  --dry-run            Simulate without writing files or cache")
  lines.push("  --verbose            Show detailed fetch progress")
  lines.push("  -o, --output <file>  Write output to file")
  join_cli_lines(lines)
}

///|
fn join_cli_lines(lines : Array[String]) -> String {
  let mut result = ""
  let mut i = 0
  while i < lines.length() {
    if i > 0 {
      result = result + "\n"
    }
    result = result + lines[i]
    i = i + 1
  }
  result
}
