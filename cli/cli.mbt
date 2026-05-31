/// CLI 参数解析与命令分发
///
/// 支持命令：tree、audit、report
/// 全局选项：--help, --version, --cache-dir, --offline

// ========== 公共入口 ==========

/// 运行 CLI（无参数入口，供 main 调用）
/// 返回进程退出码（0 成功，1 失败）
pub fn run_cli() -> Int {
  // MoonBit main 不支持 args，此处使用演示数据
  run_cli_with_args(["tree", "root"])
}

/// 运行 CLI，接收命令行参数数组
/// 返回进程退出码（0 成功，1 失败）
pub fn run_cli_with_args(args : Array[String]) -> Int {
  if args.length() == 0 {
    print_help()
    return 0
  }

  match parse_args(args) {
    Ok(opts) => {
      if opts.version {
        println("MoonBit Depsight v0.3.0")
        return 0
      }
      if opts.help {
        match opts.command {
          "tree" => print_tree_help()
          "audit" => print_audit_help()
          "report" => print_report_help()
          _ => print_help()
        }
        return 0
      }
      execute_command(opts)
    }
    Err(msg) => {
      println(@analyze.red("Error: " + msg))
      println("")
      print_help()
      return 1
    }
  }
}

// ========== 数据结构 ==========

pub struct CliOptions {
  command : String
  target_pkg : String
  depth : Int
  output : String?
  format : String
  fail_on_score : Int?
  fail_on_critical : Bool
  severity : String?
  baseline : String?
  cache_dir : String?
  offline : Bool
  help : Bool
  version : Bool
}

pub fn CliOptions::new(
  command~ : String = "",
  target_pkg~ : String = "root",
  depth~ : Int = 10,
  output~ : String? = None,
  format~ : String = "terminal",
  fail_on_score~ : Int? = None,
  fail_on_critical~ : Bool = false,
  severity~ : String? = None,
  baseline~ : String? = None,
  cache_dir~ : String? = None,
  offline~ : Bool = false,
  help~ : Bool = false,
  version~ : Bool = false,
) -> CliOptions {
  { command, target_pkg, depth, output, format, fail_on_score, fail_on_critical, severity, baseline, cache_dir, offline, help, version }
}

// ========== 参数解析 ==========

priv struct CliConfig {
  severity : String?
  fail_on_score : Int?
  fail_on_critical : Bool
  format : String
  output : String?
}

fn load_config() -> CliConfig {
  let fs = @cache.FileSystem::node_js()
  let defaults = {
    severity: None,
    fail_on_score: None,
    fail_on_critical: false,
    format: "terminal",
    output: None,
  }
  match (fs.read_file)(".depsight.toml") {
    Some(content) => {
      let map = @parse.parse_config_toml(content)
      let severity = map.get("severity")
      let fail_on_score = match map.get("fail_on_score") {
        Some(s) => parse_int(s)
        None => None
      }
      let fail_on_critical = match map.get("fail_on_critical") {
        Some("true") => true
        _ => false
      }
      let format = match map.get("format") {
        Some(f) => f
        None => "terminal"
      }
      let output = map.get("output")
      { severity, fail_on_score, fail_on_critical, format, output }
    }
    None => defaults
  }
}

pub fn parse_args(args : Array[String]) -> Result[CliOptions, String] {
  let config = load_config()
  let mut command = ""
  let mut target_pkg = "root"
  let mut depth = 10
  let mut output = config.output
  let mut format = config.format
  let mut fail_on_score = config.fail_on_score
  let mut fail_on_critical = config.fail_on_critical
  let mut severity = config.severity
  let mut cache_dir : String? = None
  let mut offline = false
  let mut help = false
  let mut version = false

  let mut baseline : String? = None
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
    } else if arg == "--severity" {
      i = i + 1
      if i >= args.length() { return Err("--severity requires a value") }
      severity = Some(args[i])
    } else if arg == "--baseline" {
      i = i + 1
      if i >= args.length() { return Err("--baseline requires a value") }
      baseline = Some(args[i])
    } else if arg == "--cache-dir" {
      i = i + 1
      if i >= args.length() { return Err("--cache-dir requires a value") }
      cache_dir = Some(args[i])
    } else if arg == "--offline" {
      offline = true
    } else if arg.length() > 0 && arg[0].to_int() == '-'.to_int() {
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
    severity,
    baseline,
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
    let code = s[i].to_int()
    if code < '0'.to_int() || code > '9'.to_int() { return None }
    result = result * 10 + (code - '0'.to_int())
    i = i + 1
  }
  Some(result)
}

// ========== 命令执行 ==========

fn filter_by_severity(
  diagnostics : Array[@report.Diagnostic],
  severity : String?
) -> Array[@report.Diagnostic] {
  match severity {
    None => diagnostics
    Some(level) => {
      let min_rank = @report.severity_rank(level)
      let result = []
      for d in diagnostics {
        if @report.severity_rank(d.level) >= min_rank {
          result.push(d)
        }
      }
      result
    }
  }
}

fn execute_command(opts : CliOptions) -> Int {
  match opts.command {
    "tree" => run_tree(opts)
    "audit" => run_audit(opts)
    "report" => run_report(opts)
    _ => {
      println(@analyze.red("Unknown command: " + opts.command))
      println("")
      print_help()
      1
    }
  }
}

fn resolve_cache_manager(opts : CliOptions) -> @cache.CacheManager? {
  if opts.offline == false && opts.cache_dir is None {
    return None
  }
  let dir = match opts.cache_dir {
    Some(d) => d
    None => @cache.default_cache_dir()
  }
  let fs = @cache.FileSystem::node_js()
  Some(@cache.CacheManager::new(dir, fs))
}

fn run_tree(opts : CliOptions) -> Int {
  let _cache = resolve_cache_manager(opts)
  let (graph, root_id) = match build_graph_from_local_mod() {
    Some(pair) => pair
    None => {
      let g = build_mock_graph(opts.target_pkg)
      let rid = opts.target_pkg + "@1.0.0"
      (g, rid)
    }
  }
  let tree = graph.render_tree(root_id, opts.depth)
  println(tree)
  0
}

fn run_audit(opts : CliOptions) -> Int {
  let _cache = resolve_cache_manager(opts)
  let (graph, root_id) = match build_graph_from_local_mod() {
    Some(pair) => pair
    None => {
      let g = build_mock_graph(opts.target_pkg)
      let rid = opts.target_pkg + "@1.0.0"
      (g, rid)
    }
  }
  let metas : Map[String, @analyze.NodeMeta] = {}
  let report = @analyze.run_analysis(graph, metas)

  // baseline diff 模式
  match opts.baseline {
    Some(baseline_path) => {
      let fs = @cache.FileSystem::node_js()
      let baseline_text = match (fs.read_file)(baseline_path) {
        Some(t) => t
        None => {
          println(@analyze.red("Error: cannot read baseline file: " + baseline_path))
          return 1
        }
      }
      let baseline_report = match @analyze.parse_audit_json(baseline_text) {
        Ok(r) => r
        Err(msg) => {
          println(@analyze.red("Error: invalid baseline JSON: " + msg))
          return 1
        }
      }
      let diff = @analyze.diff_reports(report, baseline_report)
      let diff_text = @analyze.render_diff_terminal(diff)
      match opts.output {
        Some(path) => {
          let fs2 = @cache.FileSystem::node_js()
          (fs2.write_file)(path, diff_text)
        }
        None => println(diff_text)
      }
      // diff 模式下也支持退出码
      let mut exit_code = 0
      if opts.fail_on_critical && diff.added.iter().any(fn(d) { d.is_critical() }) {
        println(@analyze.red("New critical issues found since baseline!"))
        exit_code = 1
      }
      if opts.fail_on_score is Some(threshold) {
        if report.get_overall_score() < threshold {
          println(@analyze.red("Health score " + report.get_overall_score().to_string() + " is below threshold " + threshold.to_string()))
          exit_code = 1
        }
      }
      return exit_code
    }
    None => ()
  }

  // severity 过滤只影响输出，不影响退出码判断
  let display_diags = filter_by_severity(report.get_diagnostics(), opts.severity)
  let display_report = @analyze.AnalysisReport::new(
    diagnostics=display_diags,
    health_scores=report.get_health_scores(),
    overall_score=report.get_overall_score(),
    node_count=report.get_node_count(),
  )

  let output_text = if opts.format == "json" {
    @analyze.render_audit_json(display_report)
  } else if opts.format == "html" {
    @analyze.render_html_report(display_report, graph, root_id)
  } else {
    @analyze.render_audit_report(display_report)
  }

  match opts.output {
    Some(path) => {
      let fs = @cache.FileSystem::node_js()
      (fs.write_file)(path, output_text)
    }
    None => println(output_text)
  }

  // CI 集成：fail-on-score 和 fail-on-critical（基于原始完整报告）
  let mut exit_code = 0
  if opts.fail_on_critical {
    let has_critical = report.get_diagnostics().iter().any(fn(d) { d.is_critical() })
    if has_critical {
      println(@analyze.red("Critical issues found!"))
      exit_code = 1
    }
  }
  match opts.fail_on_score {
    Some(threshold) => {
      if report.get_overall_score() < threshold {
        println(@analyze.red("Health score " + report.get_overall_score().to_string() + " is below threshold " + threshold.to_string()))
        exit_code = 1
      }
    }
    None => ()
  }
  exit_code
}

fn run_report(opts : CliOptions) -> Int {
  let _cache = resolve_cache_manager(opts)
  let (graph, root_id) = match build_graph_from_local_mod() {
    Some(pair) => pair
    None => {
      let g = build_mock_graph(opts.target_pkg)
      let rid = opts.target_pkg + "@1.0.0"
      (g, rid)
    }
  }
  let metas : Map[String, @analyze.NodeMeta] = {}
  let report = @analyze.run_analysis(graph, metas)

  // severity 过滤只影响输出
  let display_diags = filter_by_severity(report.get_diagnostics(), opts.severity)
  let display_report = @analyze.AnalysisReport::new(
    diagnostics=display_diags,
    health_scores=report.get_health_scores(),
    overall_score=report.get_overall_score(),
    node_count=report.get_node_count(),
  )

  let output_text = if opts.format == "html" {
    @analyze.render_html_report(display_report, graph, root_id)
  } else if opts.format == "json" {
    @analyze.render_audit_json(display_report)
  } else {
    @analyze.render_terminal_report(display_report, graph, root_id)
  }

  match opts.output {
    Some(path) => {
      let fs = @cache.FileSystem::node_js()
      (fs.write_file)(path, output_text)
    }
    None => println(output_text)
  }

  // CI 集成：fail-on-score 和 fail-on-critical（基于原始完整报告）
  let mut exit_code = 0
  if opts.fail_on_critical {
    let has_critical = report.get_diagnostics().iter().any(fn(d) { d.is_critical() })
    if has_critical {
      println(@analyze.red("Critical issues found!"))
      exit_code = 1
    }
  }
  match opts.fail_on_score {
    Some(threshold) => {
      if report.get_overall_score() < threshold {
        println(@analyze.red("Health score " + report.get_overall_score().to_string() + " is below threshold " + threshold.to_string()))
        exit_code = 1
      }
    }
    None => ()
  }
  exit_code
}

// ========== 本地 moon.mod.json 读取 ==========

fn build_graph_from_local_mod() -> (@graph.DependencyGraph, String)? {
  let fs = @cache.FileSystem::node_js()

  // 1. 尝试 ./moon.mod (TOML)
  match (fs.read_file)("./moon.mod") {
    Some(content) => {
      match @parse.parse_mod_toml(content) {
        Ok(mod_) => {
          let graph = @graph.DependencyGraph::new()
          graph.add_node(mod_.name, mod_.version, 0)
          for dep_name, dep_constraint in mod_.deps {
            graph.add_node(dep_name, dep_constraint, 1)
            graph.add_edge(mod_.name, mod_.version, dep_name, dep_constraint)
          }
          let root_id = mod_.name + "@" + mod_.version
          return Some((graph, root_id))
        }
        Err(_) => ()
      }
    }
    None => ()
  }

  // 2. 回退 ./moon.mod.json (JSON)
  match (fs.read_file)("./moon.mod.json") {
    Some(content) => {
      match @parse.parse_mod_json(content) {
        Ok(mod_) => {
          let graph = @graph.DependencyGraph::new()
          graph.add_node(mod_.name, mod_.version, 0)
          for dep_name, dep_constraint in mod_.deps {
            graph.add_node(dep_name, dep_constraint, 1)
            graph.add_edge(mod_.name, mod_.version, dep_name, dep_constraint)
          }
          let root_id = mod_.name + "@" + mod_.version
          return Some((graph, root_id))
        }
        Err(_) => ()
      }
    }
    None => ()
  }

  None
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
  lines.push(@analyze.bold("MoonBit Depsight v0.3.0"))
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
  lines.push("  --severity <level>   Filter diagnostics: critical, warning, info")
  lines.push("  --baseline <file>    Compare against a previous JSON report")
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
  lines.push("  --severity <level>   Filter diagnostics: critical, warning, info")
  lines.push("  --fail-on-score <n>  Exit with error if overall score < n")
  lines.push("  --fail-on-critical   Exit with error if critical issues found")
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
