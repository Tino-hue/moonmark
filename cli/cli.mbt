/// CLI 参数解析与命令分发
///
/// 支持命令：tree、audit、report
/// 全局选项：--help, --version, --cache-dir, --offline

// ========== 公共入口 ==========

/// 运行 CLI（无参数入口，供 main 调用）
pub fn run_cli() -> Unit {
  // MoonBit main 不支持 args，此处使用演示数据
  run_cli_with_args(["tree", "root"])
}

/// 运行 CLI，接收命令行参数数组
pub fn run_cli_with_args(args : Array[String]) -> Unit {
  if args.length() == 0 {
    print_help()
    return
  }

  match parse_args(args) {
    Ok(opts) => {
      if opts.version {
        println("MoonBit Depsight v0.1.0")
        return
      }
      if opts.help {
        match opts.command {
          "tree" => print_tree_help()
          "audit" => print_audit_help()
          "report" => print_report_help()
          _ => print_help()
        }
        return
      }
      execute_command(opts)
    }
    Err(msg) => {
      println(@analyze.red("Error: " + msg))
      println("")
      print_help()
    }
  }
}

// ========== 数据结构 ==========

pub(struct) CliOptions {
  pub command : String
  pub target_pkg : String
  pub depth : Int
  pub output : String?
  pub format : String
  pub fail_on_score : Int?
  pub fail_on_critical : Bool
  pub cache_dir : String?
  pub offline : Bool
  pub help : Bool
  pub version : Bool
}

// ========== 参数解析 ==========

pub fn parse_args(args : Array[String]) -> Result[CliOptions, String] {
  let mut command = ""
  let mut target_pkg = "root"
  let mut depth = 10
  let mut output : String? = None
  let mut format = "terminal"
  let mut fail_on_score : Int? = None
  let mut fail_on_critical = false
  let mut cache_dir : String? = None
  let mut offline = false
  let mut help = false
  let mut version = false

  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      help = true
    } else if arg == "--version" || arg == "-v" {
      version = true
    } else if arg == "--depth" {
      i = i + 1
      if i >= args.length() { return Err("--depth requires a value") }
      match parse_int(args[i]) {
        Some(d) => depth = d
        None => return Err("Invalid depth: " + args[i])
      }
    } else if arg == "-o" || arg == "--output" {
      i = i + 1
      if i >= args.length() { return Err("--output requires a value") }
      output = Some(args[i])
    } else if arg == "--json" {
      format = "json"
    } else if arg == "--html" {
      format = "html"
    } else if arg == "--fail-on-score" {
      i = i + 1
      if i >= args.length() { return Err("--fail-on-score requires a value") }
      match parse_int(args[i]) {
        Some(s) => fail_on_score = Some(s)
        None => return Err("Invalid score: " + args[i])
      }
    } else if arg == "--fail-on-critical" {
      fail_on_critical = true
    } else if arg == "--cache-dir" {
      i = i + 1
      if i >= args.length() { return Err("--cache-dir requires a value") }
      cache_dir = Some(args[i])
    } else if arg == "--offline" {
      offline = true
    } else if arg.length() > 0 && arg[0] == '-' {
      return Err("Unknown option: " + arg)
    } else if command == "" {
      command = arg
    } else if target_pkg == "root" {
      target_pkg = arg
    } else {
      return Err("Unexpected argument: " + arg)
    }
    i = i + 1
  }

  if command == "" && help == false && version == false {
    return Err("No command specified. Use --help for usage.")
  }

  Ok({
    command,
    target_pkg,
    depth,
    output,
    format,
    fail_on_score,
    fail_on_critical,
    cache_dir,
    offline,
    help,
    version,
  })
}

fn parse_int(s : String) -> Int? {
  let mut result = 0
  let mut i = 0
  while i < s.length() {
    let ch = s[i]
    if ch < '0' || ch > '9' { return None }
    result = result * 10 + (ch.to_int() - '0'.to_int())
    i = i + 1
  }
  Some(result)
}

// ========== 命令执行 ==========

fn execute_command(opts : CliOptions) -> Unit {
  match opts.command {
    "tree" => run_tree(opts)
    "audit" => run_audit(opts)
    "report" => run_report(opts)
    _ => {
      println(@analyze.red("Unknown command: " + opts.command))
      println("")
      print_help()
    }
  }
}

fn run_tree(opts : CliOptions) -> Unit {
  let graph = build_mock_graph(opts.target_pkg)
  let root_id = opts.target_pkg + "@1.0.0"
  let tree = graph.render_tree(root_id, opts.depth)
  println(tree)
}

fn run_audit(opts : CliOptions) -> Unit {
  let graph = build_mock_graph(opts.target_pkg)
  let root_id = opts.target_pkg + "@1.0.0"
  let metas : Map[String, @analyze.NodeMeta] = {}
  let report = @analyze.run_analysis(graph, metas)

  let output_text = if opts.format == "json" {
    @analyze.render_audit_json(report)
  } else {
    @analyze.render_audit_report(report)
  }

  match opts.output {
    Some(path) => {
      println("Audit report would be written to: " + path)
      println(output_text)
    }
    None => println(output_text)
  }

  // CI 集成：fail-on-score 和 fail-on-critical
  if opts.fail_on_critical {
    let has_critical = report.diagnostics.iter().any(fn(d) { d.is_critical() })
    if has_critical {
      println(@analyze.red("Critical issues found!"))
    }
  }
  match opts.fail_on_score {
    Some(threshold) => {
      if report.overall_score < threshold {
        println(@analyze.red("Health score " + report.overall_score.to_string() + " is below threshold " + threshold.to_string()))
      }
    }
    None => ()
  }
}

fn run_report(opts : CliOptions) -> Unit {
  let graph = build_mock_graph(opts.target_pkg)
  let root_id = opts.target_pkg + "@1.0.0"
  let metas : Map[String, @analyze.NodeMeta] = {}
  let report = @analyze.run_analysis(graph, metas)

  let output_text = if opts.format == "html" {
    @analyze.render_html_report(report, graph, root_id)
  } else if opts.format == "json" {
    @analyze.render_audit_json(report)
  } else {
    @analyze.render_terminal_report(report, graph, root_id)
  }

  match opts.output {
    Some(path) => {
      println("Report would be written to: " + path)
      println(output_text)
    }
    None => println(output_text)
  }
}

// ========== Mock 数据构建器 ==========

fn build_mock_graph(pkg : String) -> @graph.DependencyGraph {
  let graph = @graph.DependencyGraph::new()
  graph.add_node(pkg, "1.0.0", 0)
  graph.add_node("a", "1.0.0", 1)
  graph.add_node("b", "1.0.0", 1)
  graph.add_node("c", "1.0.0", 2)

  graph.add_edge(pkg, "1.0.0", "a", "1.0.0")
  graph.add_edge(pkg, "1.0.0", "b", "1.0.0")
  graph.add_edge("a", "1.0.0", "c", "1.0.0")

  graph
}

// ========== Help 文案 ==========

fn print_help() -> Unit {
  println(help_text())
}

pub fn help_text() -> String {
  let lines : Array[String] = []
  lines.push(@analyze.bold("MoonBit Depsight v0.1.0"))
  lines.push("Dependency health diagnostic tool for MoonBit ecosystem")
  lines.push("")
  lines.push(@analyze.bold("Usage:"))
  lines.push("  depsight <command> [options]")
  lines.push("")
  lines.push(@analyze.bold("Commands:"))
  lines.push("  tree [package]    Show dependency tree")
  lines.push("  audit             Run dependency audit")
  lines.push("  report            Generate full report")
  lines.push("")
  lines.push(@analyze.bold("Global Options:"))
  lines.push("  -h, --help        Show help")
  lines.push("  -v, --version     Show version")
  lines.push("  --offline         Use local cache only")
  lines.push("  --cache-dir <dir> Set cache directory")
  lines.push("")
  lines.push("Use 'depsight <command> --help' for command-specific options.")
  join_cli_lines(lines)
}

fn print_tree_help() -> Unit {
  println(tree_help_text())
}

pub fn tree_help_text() -> String {
  let lines : Array[String] = []
  lines.push(@analyze.bold("depsight tree — Show dependency tree"))
  lines.push("")
  lines.push(@analyze.bold("Usage:"))
  lines.push("  depsight tree [package]")
  lines.push("")
  lines.push(@analyze.bold("Options:"))
  lines.push("  --depth <n>       Max tree depth (default: 10)")
  join_cli_lines(lines)
}

fn print_audit_help() -> Unit {
  println(audit_help_text())
}

pub fn audit_help_text() -> String {
  let lines : Array[String] = []
  lines.push(@analyze.bold("depsight audit — Run dependency audit"))
  lines.push("")
  lines.push(@analyze.bold("Usage:"))
  lines.push("  depsight audit [options]")
  lines.push("")
  lines.push(@analyze.bold("Options:"))
  lines.push("  --json            Output JSON format")
  lines.push("  --fail-on-score <n>  Exit with error if overall score < n")
  lines.push("  --fail-on-critical   Exit with error if critical issues found")
  lines.push("  -o, --output <file>  Write output to file")
  join_cli_lines(lines)
}

fn print_report_help() -> Unit {
  println(report_help_text())
}

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
  lines.push("  -o, --output <file>  Write output to file")
  join_cli_lines(lines)
}

fn join_cli_lines(lines : Array[String]) -> String {
  let mut result = ""
  let mut i = 0
  while i < lines.length() {
    if i > 0 { result = result + "\n" }
    result = result + lines[i]
    i = i + 1
  }
  result
}
