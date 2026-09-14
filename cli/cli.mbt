/// CLI 公共入口、选项结构与命令分发。
///
/// 支持命令：tree、audit、report、stats、outdated、why、check
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
      print_error(msg)
      println("")
      print_help()
      return exit_args_error
    }
  }
}

///|
/// 统一错误输出（红色 "Error: ..." 前缀），避免各处重复拼接。
fn print_error(msg : String) -> Unit {
  println(@analyze.red("Error: " + msg))
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

// ========== 诊断过滤与映射 ==========

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

// ========== 命令执行 ==========

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
      print_error("Unknown command '" + opts.command + "'")
      println("")
      println(
        @analyze.yellow(
          "Available commands: tree, audit, report, outdated, why, check",
        ),
      )
      println("Use 'depsight --help' for more information.")
      exit_args_error
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
