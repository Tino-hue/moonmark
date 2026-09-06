/// CLI 参数解析与命令分发
///
/// 支持命令：tree、audit、report
/// 全局选项：--help, --version, --cache-dir, --offline

// ========== 公共入口 ==========

///|
/// 运行 CLI（无参数入口，供 main 调用）
/// 返回进程退出码（0 成功，1 失败）
pub fn run_cli() -> Int {
  // 无参数时显示帮助信息
  print_help()
  0
}

///|
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
        println(version_full())
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

///|
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
  workspace : Bool
  cache_dir : String?
  offline : Bool
  dry_run : Bool
  verbose : Bool
  quiet : Bool
  scoring_weights : @analyze.ScoreWeights
  ignore : Array[String]
  severity_map : Map[String, String]
  help : Bool
  version : Bool
}

///|
pub fn CliOptions::new(
  command? : String = "",
  target_pkg? : String = "root",
  depth? : Int = 10,
  output? : String? = None,
  format? : String = "terminal",
  fail_on_score? : Int? = None,
  fail_on_critical? : Bool = false,
  severity? : String? = None,
  baseline? : String? = None,
  workspace? : Bool = false,
  cache_dir? : String? = None,
  offline? : Bool = false,
  dry_run? : Bool = false,
  verbose? : Bool = false,
  quiet? : Bool = false,
  scoring_weights? : @analyze.ScoreWeights = @analyze.default_weights(),
  ignore? : Array[String] = [],
  severity_map? : Map[String, String] = Map([]),
  help? : Bool = false,
  version? : Bool = false,
) -> CliOptions {
  {
    command,
    target_pkg,
    depth,
    output,
    format,
    fail_on_score,
    fail_on_critical,
    severity,
    baseline,
    workspace,
    cache_dir,
    offline,
    dry_run,
    verbose,
    quiet,
    scoring_weights,
    ignore,
    severity_map,
    help,
    version,
  }
}

// ========== 参数解析 ==========

///|
priv struct CliConfig {
  severity : String?
  fail_on_score : Int?
  fail_on_critical : Bool
  format : String
  output : String?
  ignore : Array[String]
  severity_map : Map[String, String]
  baseline : String?
  scoring_weights : @analyze.ScoreWeights
}

///|
fn load_config() -> CliConfig {
  let fs = @cache.FileSystem::node_js()
  let defaults = {
    severity: None,
    fail_on_score: None,
    fail_on_critical: false,
    format: "terminal",
    output: None,
    ignore: [],
    severity_map: Map([]),
    baseline: None,
    scoring_weights: @analyze.default_weights(),
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
      let ignore = match map.get("ignore") {
        Some(s) => split_comma_list(s)
        None => []
      }
      let baseline = map.get("baseline")
      // 解析评分权重
      let sw_freshness = parse_int_with_default(
        map.get("scoring.freshness"),
        25,
      )
      let sw_compliance = parse_int_with_default(
        map.get("scoring.compliance"),
        20,
      )
      let sw_deprecated = parse_int_with_default(
        map.get("scoring.deprecated_density"),
        25,
      )
      let sw_size = parse_int_with_default(map.get("scoring.size"), 20)
      let sw_activity = parse_int_with_default(map.get("scoring.activity"), 10)
      let scoring_weights = @analyze.ScoreWeights::new(
        freshness=sw_freshness,
        compliance=sw_compliance,
        deprecated_density=sw_deprecated,
        size_reasonableness=sw_size,
        activity=sw_activity,
      )
      // 解析 severity 映射：severity.LICENSE-001 = "warning"
      let severity_map : Map[String, String] = Map([])
      for pair in map {
        let (key, value) = pair
        if key.has_prefix("severity.") && key.length() > 9 {
          let code = key[9:key.length()].to_owned()
          severity_map[code] = value
        }
      }
      {
        severity,
        fail_on_score,
        fail_on_critical,
        format,
        output,
        ignore,
        severity_map,
        baseline,
        scoring_weights,
      }
    }
    None => defaults
  }
}

///|
fn split_comma_list(s : String) -> Array[String] {
  let result = []
  let mut start = 0
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == ',' {
      let item = s[start:i].trim().to_owned()
      if !item.is_empty() {
        result.push(item)
      }
      start = i + 1
    }
  }
  if start < s.length() {
    let item = s[start:s.length()].trim().to_owned()
    if !item.is_empty() {
      result.push(item)
    }
  }
  result
}

///|
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
  let mut dry_run = false
  let mut verbose = false
  let mut quiet = false
  let mut help = false
  let mut version = false

  let mut baseline = config.baseline
  let mut workspace = false
  let ignore = config.ignore
  let severity_map = config.severity_map
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      help = true
    } else if arg == "--version" || arg == "-v" {
      version = true
    } else if arg == "--depth" {
      i = i + 1
      if i >= args.length() {
        return Err("--depth requires a value")
      }
      match parse_int(args[i]) {
        Some(d) => depth = d
        None => return Err("Invalid depth: " + args[i])
      }
    } else if arg == "-o" || arg == "--output" {
      i = i + 1
      if i >= args.length() {
        return Err("--output requires a value")
      }
      output = Some(args[i])
    } else if arg == "--json" {
      format = "json"
    } else if arg == "--html" {
      format = "html"
    } else if arg == "--sarif" {
      format = "sarif"
    } else if arg == "--markdown" {
      format = "markdown"
    } else if arg == "--fail-on-score" {
      i = i + 1
      if i >= args.length() {
        return Err("--fail-on-score requires a value")
      }
      match parse_int(args[i]) {
        Some(s) => fail_on_score = Some(s)
        None => return Err("Invalid score: " + args[i])
      }
    } else if arg == "--fail-on-critical" {
      fail_on_critical = true
    } else if arg == "--severity" {
      i = i + 1
      if i >= args.length() {
        return Err("--severity requires a value")
      }
      severity = Some(args[i])
    } else if arg == "--baseline" {
      i = i + 1
      if i >= args.length() {
        return Err("--baseline requires a value")
      }
      baseline = Some(args[i])
    } else if arg == "--workspace" {
      workspace = true
    } else if arg == "--cache-dir" {
      i = i + 1
      if i >= args.length() {
        return Err("--cache-dir requires a value")
      }
      cache_dir = Some(args[i])
    } else if arg == "--offline" {
      offline = true
    } else if arg == "--dry-run" {
      dry_run = true
    } else if arg == "--verbose" {
      verbose = true
    } else if arg == "--quiet" {
      quiet = true
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
    return Err(
      "No command specified. Use 'depsight --help' to see available commands.",
    )
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
    workspace,
    cache_dir,
    offline,
    dry_run,
    verbose,
    quiet,
    scoring_weights: config.scoring_weights,
    ignore,
    severity_map,
    help,
    version,
  })
}

///|
fn parse_int(s : String) -> Int? {
  let mut result = 0
  let mut i = 0
  while i < s.length() {
    let code = s[i].to_int()
    if code < '0'.to_int() || code > '9'.to_int() {
      return None
    }
    result = result * 10 + (code - '0'.to_int())
    i = i + 1
  }
  Some(result)
}

///|
fn parse_int_with_default(opt : String?, default : Int) -> Int {
  match opt {
    Some(s) =>
      match parse_int(s) {
        Some(v) => v
        None => default
      }
    None => default
  }
}

// ========== 命令执行 ==========

///|
fn filter_by_severity(
  diagnostics : Array[@report.Diagnostic],
  severity : String?,
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

///|
fn filter_ignored(
  diagnostics : Array[@report.Diagnostic],
  ignore : Array[String],
) -> Array[@report.Diagnostic] {
  if ignore.is_empty() {
    return diagnostics
  }
  let result = []
  for d in diagnostics {
    let mut skipped = false
    for pattern in ignore {
      if pattern == d.code {
        skipped = true
        break
      }
      if d.path.length() > 0 {
        let full = d.code + "@" + d.path[0]
        if pattern == full {
          skipped = true
          break
        }
      }
    }
    if skipped == false {
      result.push(d)
    }
  }
  result
}

///|
/// 根据用户自定义 severity 映射调整诊断级别
fn apply_severity_map(
  diagnostics : Array[@report.Diagnostic],
  severity_map : Map[String, String],
) -> Array[@report.Diagnostic] {
  if severity_map.is_empty() {
    return diagnostics
  }
  let result = []
  for d in diagnostics {
    match severity_map.get(d.code) {
      Some(new_level) =>
        result.push(
          @report.Diagnostic::new(
            new_level,
            d.code,
            d.message,
            d.path,
            d.suggestions,
          ),
        )
      None => result.push(d)
    }
  }
  result
}

///|
/// 自动保存审计基线到 .depsight-baseline.json
fn auto_save_baseline(report : @analyze.AnalysisReport, dry_run : Bool) -> Unit {
  if dry_run {
    return
  }
  let path = ".depsight-baseline.json"
  let json = @analyze.render_audit_json(report)
  let fs = @cache.FileSystem::node_js()
  (fs.write_file)(path, json)
}

///|
fn execute_command(opts : CliOptions) -> Int {
  match opts.command {
    "tree" => run_tree(opts)
    "audit" =>
      if opts.workspace {
        run_workspace_audit(opts)
      } else {
        run_audit(opts)
      }
    "report" =>
      if opts.workspace {
        run_workspace_report(opts)
      } else {
        run_report(opts)
      }
    "stats" => run_stats(opts)
    "outdated" => run_outdated(opts)
    "why" => run_why(opts)
    "check" => run_check(opts)
    _ => {
      println(@analyze.red("Error: Unknown command '" + opts.command + "'"))
      println("")
      println(
        @analyze.yellow(
          "Available commands: tree, audit, report, outdated, why, check",
        ),
      )
      println("Use 'depsight --help' for more information.")
      1
    }
  }
}

///|
fn resolve_cache_manager(opts : CliOptions) -> @cache.CacheManager? {
  if opts.dry_run {
    return None
  }
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

// ---------- 图构建（本地 + 远程递归） ----------

///|
fn read_module_in_directory(dir : String) -> @parse.Module? {
  let fs = @cache.FileSystem::node_js()
  let sep = @cache.platform_path_sep()
  match (fs.read_file)(dir + sep + "moon.mod") {
    Some(content) =>
      match @parse.parse_mod_toml(content) {
        Ok(m) => return Some(m)
        Err(_) => ()
      }
    None => ()
  }
  match (fs.read_file)(dir + sep + "moon.mod.json") {
    Some(content) =>
      match @parse.parse_mod_json(content) {
        Ok(m) => return Some(m)
        Err(_) => ()
      }
    None => ()
  }
  None
}

///|
fn build_full_graph_for_dir(
  dir : String,
  opts : CliOptions,
) -> (@graph.DependencyGraph, String, Map[String, @analyze.NodeMeta]) {
  let root_mod = match read_module_in_directory(dir) {
    Some(m) => m
    None => {
      let g = build_mock_graph(opts.target_pkg)
      let rid = opts.target_pkg + "@1.0.0"
      return (g, rid, Map([]))
    }
  }

  let cache = resolve_cache_manager(opts)
  let registry = @fetch.Registry::new()
  let _ = registry.with_defaults()
  match cache {
    Some(cm) => {
      let _ = registry.with_cache(cm)
    }
    None => ()
  }

  let builder = @graph.GraphBuilder::new_with_max_depth(opts.depth)
  let modules : Map[String, @parse.Module] = Map([])
  let fs = @cache.FileSystem::node_js()
  // F06：离线模式下，本地 `.mooncakes/<name>@<version>/moon.mod` 作为本地 mock 注册表源，
  // 命中则直接返回 Module，完全不走网络，支持示例项目离线演示。
  let local_mooncakes_dir = ".mooncakes"

  fn fetch_cb(
    name : String,
    version : String,
  ) -> Result[@parse.Module, String] {
    if name == root_mod.name {
      let id = name + "@" + root_mod.version
      modules[id] = root_mod
      if opts.verbose {
        println(@analyze.dim("[local] " + id))
      }
      return Ok(root_mod)
    }
    if opts.verbose {
      println("[fetch] " + name + "@" + version + " ...")
    }
    // 1. 离线模式下先尝试本地 .mooncakes 目录（F06：本地 mock 注册表）
    //    先找 moon.mod.json（JSON 含完整 deps），再回退到 moon.mod（TOML）
    if opts.offline {
      let pkg_dir = (fs.path_join)(local_mooncakes_dir, name)
      let json_path = (fs.path_join)(pkg_dir, "moon.mod.json")
      let toml_path = (fs.path_join)(pkg_dir, "moon.mod")
      let local_content = match (fs.read_file)(json_path) {
        Some(c) => Some(("json", c))
        None =>
          match (fs.read_file)(toml_path) {
            Some(c) => Some(("toml", c))
            None => None
          }
      }
      match local_content {
        Some(("json", content)) =>
          match @parse.parse_mod_json(content) {
            Ok(m) => {
              let id = name + "@" + m.version
              modules[id] = m
              if opts.verbose {
                println(
                  @analyze.green(
                    "  -> [offline] " + id + " from .mooncakes (JSON)",
                  ),
                )
              }
              return Ok(m)
            }
            Err(e) =>
              if opts.verbose {
                println(
                  @analyze.yellow(
                    "  -> [offline] JSON parse fail for " + name + ": " + e,
                  ),
                )
              }
          }
        Some(("toml", content)) =>
          match @parse.parse_mod_toml(content) {
            Ok(m) => {
              let id = name + "@" + m.version
              modules[id] = m
              if opts.verbose {
                println(
                  @analyze.green(
                    "  -> [offline] " + id + " from .mooncakes (TOML)",
                  ),
                )
              }
              return Ok(m)
            }
            Err(e) =>
              if opts.verbose {
                println(
                  @analyze.yellow(
                    "  -> [offline] TOML parse fail for " + name + ": " + e,
                  ),
                )
              }
          }
        _ => ()
      }
      if opts.verbose {
        match (fs.read_file)(json_path) {
          Some(_) => ()
          None =>
            match (fs.read_file)(toml_path) {
              Some(_) => ()
              None =>
                println(
                  @analyze.dim(
                    "  -> [offline] no " + name + " in .mooncakes, skip",
                  ),
                )
            }
        }
      }
    }
    match registry.fetch(@fetch.http_get, name, version, opts.offline) {
      Ok(content) => {
        if opts.verbose {
          println(@analyze.green("  -> ok"))
        }
        match @parse.parse_mod_json(content) {
          Ok(m) => {
            let id = name + "@" + m.version
            modules[id] = m
            Ok(m)
          }
          Err(_) =>
            match @parse.parse_mod_toml(content) {
              Ok(m) => {
                let id = name + "@" + m.version
                modules[id] = m
                Ok(m)
              }
              Err(e) => {
                if opts.verbose {
                  println(@analyze.red("  -> parse error: " + e))
                }
                Err("Failed to parse " + name + "@" + version + ": " + e)
              }
            }
        }
      }
      Err(e) => {
        if opts.verbose {
          println(@analyze.yellow("  -> " + e))
        }
        if e.contains("Unknown package") {
          let m = @parse.Module::new(name, version, Map([]))
          let id = name + "@" + version
          modules[id] = m
          Ok(m)
        } else {
          Err(e)
        }
      }
    }
  }

  match builder.build(root_mod.name, root_mod.version, fetch_cb) {
    Ok(graph) => {
      // 获取每个远程 module 的 GitHub 最后提交时间（用于真实活跃度评分）
      let commit_days : Map[String, Int] = Map([])
      for pair in modules {
        let (id, mod) = pair
        match mod.repository {
          Some(repo) => {
            if opts.verbose {
              println("[activity] " + id + " ...")
            }
            match @fetch.fetch_last_commit_days(@fetch.http_get, repo) {
              Ok(days) => {
                if opts.verbose {
                  println(
                    @analyze.green("  -> " + days.to_string() + " days ago"),
                  )
                }
                commit_days[id] = days
              }
              Err(e) => if opts.verbose { println(@analyze.dim("  -> " + e)) }
            }
          }
          None => ()
        }
      }
      // build_node_metas：modules 内的 root 包也应该能拿到真实 size/API——
      //   它不在 .mooncakes/ 里，它的源文件就在 `dir`（项目目录）。
      let metas = build_node_metas(modules, commit_days, dir, root_mod.name)
      (graph, root_mod.name + "@" + root_mod.version, metas)
    }
    Err(e) => {
      println(@analyze.yellow("Warning: full graph build failed: " + e))
      println(@analyze.yellow("Falling back to local-only dependency graph."))
      let g = @graph.DependencyGraph::new()
      g.add_node(root_mod.name, root_mod.version, 0)
      for dep_name, dep_constraint in root_mod.deps {
        g.add_node(dep_name, dep_constraint, 1)
        g.add_edge(root_mod.name, root_mod.version, dep_name, dep_constraint)
      }
      let metas = build_node_metas_from_single(root_mod, dir)
      (g, root_mod.name + "@" + root_mod.version, metas)
    }
  }
}

///|
fn build_full_graph(
  opts : CliOptions,
) -> (@graph.DependencyGraph, String, Map[String, @analyze.NodeMeta]) {
  build_full_graph_for_dir(".", opts)
}

///|
fn build_node_metas(
  modules : Map[String, @parse.Module],
  commit_days : Map[String, Int],
  root_dir : String,
  root_name : String,
) -> Map[String, @analyze.NodeMeta] {
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let fs = @cache.FileSystem::node_js()
  let cache_root = ".mooncakes"
  for pair in modules {
    let (id, mod) = pair
    let days = match commit_days.get(id) {
      Some(d) => Some(d)
      None => None
    }
    let (name, _) = split_node_id(id)
    // root 包的源文件目录是项目目录（root_dir），不是 .mooncakes 缓存子目录。
    // 其它包先尝试 .mooncakes cache；命中 → 真实扫描，否则降级。
    let pkg_dir = if name == root_name {
      root_dir
    } else {
      @analyze.locate_package_dir(cache_root, name, fs)
    }
    let has_pkg_dir = match (fs.readdir)(pkg_dir) {
      Some(_) => true
      None => false
    }
    let meta = if has_pkg_dir {
      // 真实扫描：LICENSE 文件 + 实际体积 + 废弃 API + public API 数（F01）
      // F06: mod.latest_version 来自 moon.mod.json 的 _latest_version 扩展字段
      // （仅离线 mock 注册表使用，用于模拟过时依赖）
      @analyze.build_realistic_node_meta(
        pkg_dir,
        mod.license,
        fs,
        mod.latest_version,
        days,
      )
    } else {
      // 降级：仅用 moon.mod 声明
      @analyze.NodeMeta::new(
        license=mod.license,
        deprecated_apis=[],
        latest_version=None,
        self_size=0,
        last_commit_days_ago=days,
      )
    }
    metas[id] = meta
  }
  metas
}

///|
fn build_node_metas_from_single(
  root_mod : @parse.Module,
  root_dir : String,
) -> Map[String, @analyze.NodeMeta] {
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let root_id = root_mod.name + "@" + root_mod.version
  let fs = @cache.FileSystem::node_js()
  // F02 真实体积（项目目录下 .mbt 源文件字节数总和）
  // F01 真实 public API 总数 & 真实废弃 API & LICENSE
  let has_pkg_dir = match (fs.readdir)(root_dir) {
    Some(_) => true
    None => false
  }
  if has_pkg_dir {
    metas[root_id] = @analyze.build_realistic_node_meta(
      root_dir,
      root_mod.license,
      fs,
      None,
      None,
    )
  } else {
    metas[root_id] = @analyze.NodeMeta::new(
      license=root_mod.license,
      deprecated_apis=[],
      latest_version=None,
      self_size=0,
    )
  }
  metas
}

///|
fn write_output_or_print(opts : CliOptions, text : String) -> Unit {
  match opts.output {
    Some(path) =>
      if opts.dry_run {
        println(@analyze.yellow("[dry-run] Would write output to: " + path))
      } else {
        let fs = @cache.FileSystem::node_js()
        (fs.write_file)(path, text)
        println(@analyze.green("Output written to: " + path))
      }
    None =>
      // 对于 HTML/SARIF/JSON 格式，提示用户指定 -o 选项
      if opts.format == "html" {
        println(text)
        println("")
        println(
          @analyze.yellow(
            "Tip: Use -o report.html to save the HTML report to a file.",
          ),
        )
      } else if opts.format == "sarif" {
        println(text)
        println("")
        println(
          @analyze.yellow(
            "Tip: Use -o results.sarif to save the SARIF report to a file.",
          ),
        )
      } else if opts.format == "json" {
        println(text)
        println("")
        println(
          @analyze.yellow(
            "Tip: Use -o report.json to save the JSON report to a file.",
          ),
        )
      } else {
        println(text)
      }
  }
}

///|
fn run_tree(opts : CliOptions) -> Int {
  let (graph, root_id, metas) = build_full_graph(opts)
  let report = @analyze.run_analysis(graph, metas)

  // 为 tree 节点构建诊断标记
  let markers : Map[String, String] = Map([])
  for d in report.get_diagnostics() {
    if d.path.length() > 0 {
      let node_id = d.path[0]
      let tag = if d.is_critical() {
        "[! " + d.code + "]"
      } else if d.is_warning() {
        "[⚠ " + d.code + "]"
      } else {
        "[ℹ " + d.code + "]"
      }
      markers[node_id] = tag
    }
  }

  let tree = graph.render_tree_with_markers(root_id, opts.depth, markers)
  write_output_or_print(opts, tree)
  0
}

///|
fn run_audit(opts : CliOptions) -> Int {
  let (graph, root_id, metas) = build_full_graph(opts)
  let report = @analyze.run_analysis(graph, metas)

  // 自动保存基线（完整报告，不受过滤影响）
  auto_save_baseline(report, opts.dry_run)

  // baseline diff 模式
  match opts.baseline {
    Some("auto") => {
      let fs = @cache.FileSystem::node_js()
      let baseline_text = match (fs.read_file)(".depsight-baseline.json") {
        Some(t) => t
        None => {
          println(
            @analyze.yellow(
              "No previous baseline found at .depsight-baseline.json. Running full audit.",
            ),
          )
          ""
        }
      }
      match baseline_text {
        "" => ()
        _ => {
          let baseline_report = match @analyze.parse_audit_json(baseline_text) {
            Ok(r) => r
            Err(msg) => {
              println(@analyze.red("Error: invalid baseline JSON: " + msg))
              return 1
            }
          }
          let diff = @analyze.diff_reports(report, baseline_report)
          let diff_text = @analyze.render_diff_terminal(diff)
          write_output_or_print(opts, diff_text)
          // diff 模式下也支持退出码
          let mut exit_code = 0
          if opts.fail_on_critical &&
            diff.added.iter().any(fn(d) { d.is_critical() }) {
            println(@analyze.red("New critical issues found since baseline!"))
            exit_code = 1
          }
          if opts.fail_on_score is Some(threshold) {
            if report.get_overall_score() < threshold {
              println(
                @analyze.red(
                  "Health score " +
                  report.get_overall_score().to_string() +
                  " is below threshold " +
                  threshold.to_string(),
                ),
              )
              exit_code = 1
            }
          }
          return exit_code
        }
      }
    }
    Some(baseline_path) => {
      let fs = @cache.FileSystem::node_js()
      let baseline_text = match (fs.read_file)(baseline_path) {
        Some(t) => t
        None => {
          println(
            @analyze.red("Error: cannot read baseline file: " + baseline_path),
          )
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
      write_output_or_print(opts, diff_text)
      let mut exit_code = 0
      if opts.fail_on_critical &&
        diff.added.iter().any(fn(d) { d.is_critical() }) {
        println(@analyze.red("New critical issues found since baseline!"))
        exit_code = 1
      }
      if opts.fail_on_score is Some(threshold) {
        if report.get_overall_score() < threshold {
          println(
            @analyze.red(
              "Health score " +
              report.get_overall_score().to_string() +
              " is below threshold " +
              threshold.to_string(),
            ),
          )
          exit_code = 1
        }
      }
      return exit_code
    }
    None => ()
  }

  // 先应用用户自定义 severity 映射，再过滤
  let mapped_diags = apply_severity_map(
    report.get_diagnostics(),
    opts.severity_map,
  )
  // severity 和 ignore 过滤只影响输出，不影响退出码判断
  let display_diags = filter_ignored(
    filter_by_severity(mapped_diags, opts.severity),
    opts.ignore,
  )
  let display_report = @analyze.AnalysisReport::new(
    diagnostics=display_diags,
    health_scores=report.get_health_scores(),
    overall_score=report.get_overall_score(),
    node_count=report.get_node_count(),
    size_offenders_top5=report.get_size_offenders(),
  )

  let output_text = if opts.format == "json" {
    @analyze.render_audit_json(display_report)
  } else if opts.format == "html" {
    @analyze.render_html_report(display_report, graph, root_id)
  } else if opts.format == "sarif" {
    @analyze.render_sarif_report(display_report, graph, root_id)
  } else if opts.format == "markdown" {
    @analyze.render_markdown_report(display_report, graph, root_id)
  } else {
    @analyze.render_audit_report(display_report)
  }

  write_output_or_print(opts, output_text)

  // CI 集成：fail-on-score 和 fail-on-critical（基于原始完整报告，不受 ignore 影响）
  let mut exit_code = 0
  if opts.fail_on_critical {
    let has_critical = mapped_diags.iter().any(fn(d) { d.is_critical() })
    if has_critical {
      println(@analyze.red("Critical issues found!"))
      exit_code = 1
    }
  }
  match opts.fail_on_score {
    Some(threshold) =>
      if report.get_overall_score() < threshold {
        println(
          @analyze.red(
            "Health score " +
            report.get_overall_score().to_string() +
            " is below threshold " +
            threshold.to_string(),
          ),
        )
        exit_code = 1
      }
    None => ()
  }
  exit_code
}

///|
fn run_report(opts : CliOptions) -> Int {
  let (graph, root_id, metas) = build_full_graph(opts)
  let report = @analyze.run_analysis(graph, metas)

  // 先应用用户自定义 severity 映射，再过滤
  let mapped_diags = apply_severity_map(
    report.get_diagnostics(),
    opts.severity_map,
  )
  // severity 和 ignore 过滤只影响输出
  let display_diags = filter_ignored(
    filter_by_severity(mapped_diags, opts.severity),
    opts.ignore,
  )
  let display_report = @analyze.AnalysisReport::new(
    diagnostics=display_diags,
    health_scores=report.get_health_scores(),
    overall_score=report.get_overall_score(),
    node_count=report.get_node_count(),
    size_offenders_top5=report.get_size_offenders(),
  )

  let output_text = if opts.format == "html" {
    @analyze.render_html_report(display_report, graph, root_id)
  } else if opts.format == "json" {
    @analyze.render_audit_json(display_report)
  } else if opts.format == "sarif" {
    @analyze.render_sarif_report(display_report, graph, root_id)
  } else if opts.format == "markdown" {
    @analyze.render_markdown_report(display_report, graph, root_id)
  } else {
    @analyze.render_terminal_report(display_report, graph, root_id)
  }

  write_output_or_print(opts, output_text)

  // CI 集成：fail-on-score 和 fail-on-critical（基于原始完整报告，不受 ignore 影响）
  let mut exit_code = 0
  if opts.fail_on_critical {
    let has_critical = mapped_diags.iter().any(fn(d) { d.is_critical() })
    if has_critical {
      println(@analyze.red("Critical issues found!"))
      exit_code = 1
    }
  }
  match opts.fail_on_score {
    Some(threshold) =>
      if report.get_overall_score() < threshold {
        println(
          @analyze.red(
            "Health score " +
            report.get_overall_score().to_string() +
            " is below threshold " +
            threshold.to_string(),
          ),
        )
        exit_code = 1
      }
    None => ()
  }
  exit_code
}

// ========== Workspace 扫描 ==========

///|
fn str_array_contains(arr : Array[String], s : String) -> Bool {
  for item in arr {
    if item == s {
      return true
    }
  }
  false
}

///|
fn scan_workspace(fs : @cache.FileSystem, root_dir : String) -> Array[String] {
  let results = []
  let dirs_to_visit = [root_dir]
  let skip_dirs = [
    ".git", ".github", "node_modules", "_build", "target", ".codebuddy",
  ]
  while dirs_to_visit.length() > 0 {
    let dir = dirs_to_visit.remove(dirs_to_visit.length() - 1)
    // 检查当前目录是否有 moon.mod
    let moon_mod_path = dir + @cache.platform_path_sep() + "moon.mod"
    if (fs.exists)(moon_mod_path) {
      results.push(dir)
    }
    // 递归子目录
    match (fs.readdir)(dir) {
      Some(entries) =>
        for entry in entries {
          let full = dir + @cache.platform_path_sep() + entry
          // 简单判断：跳过已知目录名和点文件
          let should_skip = entry.has_prefix(".") ||
            str_array_contains(skip_dirs, entry)
          if should_skip {
            continue
          }
          // 尝试读子目录的 readdir，成功就是目录
          match (fs.readdir)(full) {
            Some(_) => dirs_to_visit.push(full)
            None => ()
          }
        }
      None => ()
    }
  }
  results
}

///|
fn run_workspace_audit(opts : CliOptions) -> Int {
  let fs = @cache.FileSystem::node_js()
  let dirs = scan_workspace(fs, ".")

  if dirs.is_empty() {
    println(@analyze.yellow("No moon.mod found in workspace."))
    return run_audit(opts)
  }

  let all_reports : Array[@analyze.AnalysisReport] = []
  let all_graphs : Array[(@graph.DependencyGraph, String)] = []

  for dir in dirs {
    match read_module_in_directory(dir) {
      Some(_) => {
        let (graph, root_id, metas) = build_full_graph_for_dir(dir, opts)
        let report = @analyze.run_analysis(graph, metas)
        all_reports.push(report)
        all_graphs.push((graph, root_id))
      }
      None => ()
    }
  }

  if all_reports.is_empty() {
    println(@analyze.yellow("No valid modules found in workspace."))
    return 0
  }

  let aggregated = aggregate_reports(all_reports)

  // 先应用用户自定义 severity 映射，再过滤
  let mapped_diags = apply_severity_map(
    aggregated.get_diagnostics(),
    opts.severity_map,
  )
  // severity 和 ignore 过滤只影响输出
  let display_diags = filter_ignored(
    filter_by_severity(mapped_diags, opts.severity),
    opts.ignore,
  )
  let display_report = @analyze.AnalysisReport::new(
    diagnostics=display_diags,
    health_scores=aggregated.get_health_scores(),
    overall_score=aggregated.get_overall_score(),
    node_count=aggregated.get_node_count(),
  )

  let output_text = if opts.format == "json" {
    @analyze.render_audit_json(display_report)
  } else if opts.format == "html" {
    // workspace HTML 只渲染第一个图作为代表
    let (g, rid) = all_graphs[0]
    @analyze.render_html_report(display_report, g, rid)
  } else if opts.format == "sarif" {
    let (g, rid) = all_graphs[0]
    @analyze.render_sarif_report(display_report, g, rid)
  } else {
    render_workspace_terminal(display_report, dirs.length())
  }

  write_output_or_print(opts, output_text)

  // CI 退出码（基于原始完整报告，不受 ignore 影响）
  let mut exit_code = 0
  if opts.fail_on_critical {
    let has_critical = mapped_diags.iter().any(fn(d) { d.is_critical() })
    if has_critical {
      println(@analyze.red("Critical issues found!"))
      exit_code = 1
    }
  }
  match opts.fail_on_score {
    Some(threshold) =>
      if aggregated.get_overall_score() < threshold {
        println(
          @analyze.red(
            "Health score " +
            aggregated.get_overall_score().to_string() +
            " is below threshold " +
            threshold.to_string(),
          ),
        )
        exit_code = 1
      }
    None => ()
  }
  exit_code
}

///|
fn run_workspace_report(opts : CliOptions) -> Int {
  let fs = @cache.FileSystem::node_js()
  let dirs = scan_workspace(fs, ".")

  if dirs.is_empty() {
    println(@analyze.yellow("No moon.mod found in workspace."))
    return run_report(opts)
  }

  let all_reports : Array[@analyze.AnalysisReport] = []
  let all_graphs : Array[(@graph.DependencyGraph, String)] = []

  for dir in dirs {
    match read_module_in_directory(dir) {
      Some(_) => {
        let (graph, root_id, metas) = build_full_graph_for_dir(dir, opts)
        let report = @analyze.run_analysis(graph, metas)
        all_reports.push(report)
        all_graphs.push((graph, root_id))
      }
      None => ()
    }
  }

  if all_reports.is_empty() {
    println(@analyze.yellow("No valid modules found in workspace."))
    return 0
  }

  let aggregated = aggregate_reports(all_reports)

  // 先应用用户自定义 severity 映射，再过滤
  let mapped_diags = apply_severity_map(
    aggregated.get_diagnostics(),
    opts.severity_map,
  )
  // severity 和 ignore 过滤只影响输出
  let display_diags = filter_ignored(
    filter_by_severity(mapped_diags, opts.severity),
    opts.ignore,
  )
  let display_report = @analyze.AnalysisReport::new(
    diagnostics=display_diags,
    health_scores=aggregated.get_health_scores(),
    overall_score=aggregated.get_overall_score(),
    node_count=aggregated.get_node_count(),
  )

  let output_text = if opts.format == "html" {
    let (g, rid) = all_graphs[0]
    @analyze.render_html_report(display_report, g, rid)
  } else if opts.format == "json" {
    @analyze.render_audit_json(display_report)
  } else if opts.format == "sarif" {
    let (g, rid) = all_graphs[0]
    @analyze.render_sarif_report(display_report, g, rid)
  } else {
    // workspace report 用 terminal report 渲染（含 health score 表格）
    let (g, rid) = all_graphs[0]
    @analyze.render_terminal_report(display_report, g, rid)
  }

  write_output_or_print(opts, output_text)

  // CI 退出码（基于原始完整报告，不受 ignore 影响）
  let mut exit_code = 0
  if opts.fail_on_critical {
    let has_critical = mapped_diags.iter().any(fn(d) { d.is_critical() })
    if has_critical {
      println(@analyze.red("Critical issues found!"))
      exit_code = 1
    }
  }
  match opts.fail_on_score {
    Some(threshold) =>
      if aggregated.get_overall_score() < threshold {
        println(
          @analyze.red(
            "Health score " +
            aggregated.get_overall_score().to_string() +
            " is below threshold " +
            threshold.to_string(),
          ),
        )
        exit_code = 1
      }
    None => ()
  }
  exit_code
}

///|
fn aggregate_reports(
  reports : Array[@analyze.AnalysisReport],
) -> @analyze.AnalysisReport {
  let all_diags : Array[@report.Diagnostic] = []
  let all_scores : Array[@analyze.HealthScore] = []
  // F02：聚合多 project 的 Size offenders（跨 project 合并后按 transitive 降序取前 5）
  let all_offenders : Array[@analyze.SizeInfo] = []
  let mut total_score = 0
  let mut total_nodes = 0
  for r in reports {
    for d in r.get_diagnostics() {
      all_diags.push(d)
    }
    for s in r.get_health_scores() {
      all_scores.push(s)
    }
    for o in r.get_size_offenders() {
      all_offenders.push(o)
    }
    total_score = total_score + r.get_overall_score()
    total_nodes = total_nodes + r.get_node_count()
  }
  let avg_score = if reports.length() > 0 {
    total_score / reports.length()
  } else {
    100
  }
  // 简单 O(n²) 冒泡按 transitive 降序取 top5（n<=5N，N 是 workspace 子项目数，够用）
  let n = all_offenders.length()
  let mut i = 0
  while i < n {
    let mut j = 0
    while j < n - i - 1 {
      if all_offenders[j].transitive_size < all_offenders[j + 1].transitive_size {
        let tmp = all_offenders[j]
        all_offenders[j] = all_offenders[j + 1]
        all_offenders[j + 1] = tmp
      }
      j = j + 1
    }
    i = i + 1
  }
  let top5 : Array[@analyze.SizeInfo] = []
  let limit = if 5 < n { 5 } else { n }
  let mut k = 0
  while k < limit {
    top5.push(all_offenders[k])
    k = k + 1
  }
  @analyze.AnalysisReport::new(
    diagnostics=all_diags,
    health_scores=all_scores,
    overall_score=avg_score,
    node_count=total_nodes,
    size_offenders_top5=top5,
  )
}

///|
fn render_workspace_terminal(
  report : @analyze.AnalysisReport,
  workspace_count : Int,
) -> String {
  let lines : Array[String] = []
  lines.push(
    @analyze.bold("╔══ MoonBit Depsight Workspace Audit ══╗"),
  )
  lines.push("")
  lines.push("  Scanned " + workspace_count.to_string() + " package(s)")
  lines.push(
    "  Nodes: " +
    report.get_node_count().to_string() +
    "   |   Overall: " +
    @analyze.color_score(report.get_overall_score()),
  )
  lines.push("")

  let criticals = []
  let warnings = []
  let infos = []
  for d in report.get_diagnostics() {
    if d.is_critical() {
      criticals.push(d)
    } else if d.is_warning() {
      warnings.push(d)
    } else {
      infos.push(d)
    }
  }

  if criticals.length() > 0 {
    lines.push(
      @analyze.red(
        @analyze.bold(
          "  ── Critical (" + criticals.length().to_string() + ") ──",
        ),
      ),
    )
    for d in criticals {
      lines.push(
        "  " +
        @analyze.color_level(d.level) +
        " " +
        @analyze.bold(d.code) +
        " — " +
        d.message,
      )
    }
    lines.push("")
  }
  if warnings.length() > 0 {
    lines.push(
      @analyze.yellow(
        @analyze.bold(
          "  ── Warning (" + warnings.length().to_string() + ") ──",
        ),
      ),
    )
    for d in warnings {
      lines.push(
        "  " +
        @analyze.color_level(d.level) +
        " " +
        @analyze.bold(d.code) +
        " — " +
        d.message,
      )
    }
    lines.push("")
  }
  if infos.length() > 0 {
    lines.push(
      @analyze.green(
        @analyze.bold(
          "  ── Info (" + infos.length().to_string() + ") ──",
        ),
      ),
    )
    for d in infos {
      lines.push(
        "  " +
        @analyze.color_level(d.level) +
        " " +
        @analyze.bold(d.code) +
        " — " +
        d.message,
      )
    }
    lines.push("")
  }

  if report.get_diagnostics().is_empty() {
    lines.push(@analyze.green("  ✅ No issues found across all packages."))
    lines.push("")
  }

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

// ========== Mock 数据构建器 ==========

///|
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

// ========== 新增命令：outdated, why, check ==========

///|
/// 在字符串中查找字符，返回索引（-1 表示未找到）
fn str_find_at(s : String, ch : UInt16) -> Int {
  let mut i = 0
  while i < s.length() {
    if s[i] == ch {
      return i
    }
    i = i + 1
  }
  -1
}

///|
/// 统计数组中满足条件的元素数量
fn[T] count_if(arr : Array[T], pred : (T) -> Bool) -> Int {
  let mut count = 0
  for item in arr {
    if pred(item) {
      count = count + 1
    }
  }
  count
}

///|
/// 显示可更新的依赖包
fn run_outdated(opts : CliOptions) -> Int {
  let (_graph, root_id, metas) = build_full_graph(opts)

  println(@analyze.bold("MoonBit Depsight \u2014 Outdated Dependencies"))
  println("")

  let mut has_outdated = false
  let rows : Array[(String, String, String, String)] = []

  for pair in metas {
    let (node_id, meta) = pair
    if node_id == root_id {
      continue
    }
    match meta.latest_version {
      Some(latest) => {
        let parts = split_node_id(node_id)
        let current = parts.1
        if current != latest {
          has_outdated = true
          let breaking = is_major_update(current, latest)
          let label = if breaking {
            @analyze.red("Yes")
          } else {
            @analyze.green("No")
          }
          rows.push((parts.0, current, latest, label))
        }
      }
      None => ()
    }
  }

  if rows.is_empty() {
    println(@analyze.green("  All dependencies are up to date!"))
  } else {
    println(
      "  " +
      pad_right("Package", 30) +
      pad_right("Current", 12) +
      pad_right("Latest", 12) +
      "Breaking",
    )
    println(
      "  " +
      repeat_str("-", 30) +
      repeat_str("-", 12) +
      repeat_str("-", 12) +
      repeat_str("-", 8),
    )
    for row in rows {
      let (pkg, current, latest, breaking) = row
      println(
        "  " +
        pad_right(pkg, 30) +
        pad_right(current, 12) +
        pad_right(latest, 12) +
        breaking,
      )
    }
    println("")
    println("  " + rows.length().to_string() + " outdated package(s) found.")
  }

  if has_outdated {
    1
  } else {
    0
  }
}

///|
fn split_node_id(node_id : String) -> (String, String) {
  let idx = str_find_at(node_id, '@')
  if idx >= 0 {
    let name = node_id[0:idx].to_owned()
    let version = node_id[idx + 1:node_id.length()].to_owned()
    (name, version)
  } else {
    (node_id, "unknown")
  }
}

///|
pub fn is_major_update(current : String, latest : String) -> Bool {
  match (@analyze.parse_version(current), @analyze.parse_version(latest)) {
    (Ok(v1), Ok(v2)) => v1.major != v2.major
    _ => false
  }
}

///|
fn pad_right(s : String, width : Int) -> String {
  let mut result = s
  while result.length() < width {
    result = result + " "
  }
  result
}

///|
fn repeat_str(s : String, n : Int) -> String {
  let mut result = ""
  let mut i = 0
  while i < n {
    result = result + s
    i = i + 1
  }
  result
}

///|
/// 显示依赖溯源
fn run_why(opts : CliOptions) -> Int {
  let target = opts.target_pkg
  if target == "root" {
    println(@analyze.red("Error: Please specify a package name"))
    println("")
    println("Usage: depsight why <package-name>")
    println("Example: depsight why moonbitlang/core")
    return 1
  }

  let (graph, root_id, _) = build_full_graph(opts)

  println(@analyze.bold("MoonBit Depsight \u2014 Dependency Trace"))
  println("")

  let dependents : Array[String] = []
  for pair in graph.nodes {
    let (node_id, node) = pair
    for child_id in node.children {
      let child_name = split_node_id(child_id).0
      if child_name == target {
        dependents.push(node_id)
      }
    }
  }

  if dependents.is_empty() {
    println(
      "  " + @analyze.yellow("No dependencies found for '" + target + "'"),
    )
  } else {
    println("  " + @analyze.bold(target) + " is required by:")
    println("")
    for dep in dependents {
      let (dep_name, dep_version) = split_node_id(dep)
      let is_direct = dep == root_id
      let label = if is_direct {
        @analyze.green("direct dependency")
      } else {
        @analyze.dim("indirect dependency")
      }
      println(
        "    \u2514\u2500\u2500 " + dep_name + " " + dep_version + " " + label,
      )
    }
  }
  0
}

///|
/// 快速健康检查
fn run_check(opts : CliOptions) -> Int {
  let (_graph, _root_id, metas) = build_full_graph(opts)
  let report = @analyze.run_analysis(_graph, metas)

  let score = report.get_overall_score()
  let diagnostics = report.get_diagnostics()
  let critical_count = count_if(diagnostics, fn(d) { d.is_critical() })
  let warning_count = count_if(diagnostics, fn(d) { d.is_warning() })

  let status = if critical_count > 0 {
    @analyze.red("FAIL")
  } else if score < 80 {
    @analyze.yellow("WARN")
  } else {
    @analyze.green("PASS")
  }

  println(
    status +
    "  " +
    score.to_string() +
    "/100  " +
    critical_count.to_string() +
    " critical, " +
    warning_count.to_string() +
    " warnings",
  )

  if critical_count > 0 {
    1
  } else if score < 80 {
    1
  } else {
    0
  }
}

///|
/// 全景生态统计（F05）：21 项指标 → 终端 ASCII 表或 JSON
fn run_stats(opts : CliOptions) -> Int {
  let (graph, root_id, metas) = build_full_graph(opts)
  let report = @analyze.run_analysis(graph, metas)
  let stats = @analyze.calculate_ecosystem_stats(graph, report, metas, root_id)

  let output_text = if opts.format == "json" {
    @analyze.render_ecosystem_stats_json(stats)
  } else {
    @analyze.render_ecosystem_stats_terminal(stats)
  }
  write_output_or_print(opts, output_text)
  0
}
