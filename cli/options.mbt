/// CLI 参数解析与配置文件加载。

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
pub fn split_comma_list(s : String) -> Array[String] {
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
  // 是否通过 --json/--html/--sarif/--markdown 显式指定了格式。
  // 未显式指定时，才允许根据 -o 输出文件扩展名自动推断。
  let mut format_explicit = false
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
      format_explicit = true
    } else if arg == "--html" {
      format = "html"
      format_explicit = true
    } else if arg == "--sarif" {
      format = "sarif"
      format_explicit = true
    } else if arg == "--markdown" {
      format = "markdown"
      format_explicit = true
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

  // 格式自动推断：未通过 --json/--html/--sarif/--markdown 显式指定格式时，
  // 根据 -o 输出文件扩展名推断（如 report.html → html）。
  if format_explicit == false {
    match output {
      Some(path) =>
        match @analyze.infer_format_from_extension(path) {
          Some(f) => format = f
          None => ()
        }
      None => ()
    }
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
pub fn parse_int(s : String) -> Int? {
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
