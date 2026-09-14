/// CLI 命令实现：tree / audit / report / workspace / outdated / why / check / stats。

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

// ========== UNUSED-001 未使用依赖检测 ==========

///|
/// 扫描目录树中 moon.pkg / moon.pkg.json 里 import 的包名。
/// 返回 None 表示项目没有源码（未发现任何 moon.pkg / moon.pkg.json），
/// 此时跳过 UNUSED-001，避免把纯 fixture 项目误报为「未使用依赖」。
fn collect_used_imports(fs : @cache.FileSystem, dir : String) -> Array[String]? {
  let imports : Array[String] = []
  let found = scan_imports_rec(fs, dir, imports)
  if found {
    Some(imports)
  } else {
    None
  }
}

///|
/// 递归扫描目录，收集 moon.pkg / moon.pkg.json 中的 import 包名，
/// 返回是否发现了任何 package 配置文件。
fn scan_imports_rec(
  fs : @cache.FileSystem,
  dir : String,
  imports : Array[String],
) -> Bool {
  let mut found = false
  // moon.pkg（TOML）优先，其次 moon.pkg.json
  match (fs.read_file)((fs.path_join)(dir, "moon.pkg")) {
    Some(content) => {
      found = true
      extract_pkg_imports(content, imports)
    }
    None => ()
  }
  match (fs.read_file)((fs.path_join)(dir, "moon.pkg.json")) {
    Some(content) => {
      found = true
      extract_pkg_imports(content, imports)
    }
    None => ()
  }
  match (fs.readdir)(dir) {
    Some(entries) =>
      for entry in entries {
        if should_skip_scan_dir(entry) {
          continue
        }
        let child = (fs.path_join)(dir, entry)
        match (fs.readdir)(child) {
          Some(_) => if scan_imports_rec(fs, child, imports) { found = true }
          None => ()
        }
      }
    None => ()
  }
  found
}

///|
/// 从 moon.pkg / moon.pkg.json 内容中提取 import 的包名。
/// 启发式：取所有引号字符串中含 '/' 的（MoonBit 包名形如 owner/name[/sub]）。
fn extract_pkg_imports(content : String, out : Array[String]) -> Unit {
  let n = content.length()
  let mut i = 0
  while i < n {
    if content[i] == '"' {
      i = i + 1
      let start = i
      while i < n && content[i] != '"' {
        i = i + 1
      }
      let s = content[start:i].to_owned()
      if s.contains("/") {
        out.push(s)
      }
      i = i + 1
    } else {
      i = i + 1
    }
  }
}

///|
/// 跳过版本控制 / 构建产物 / 依赖缓存 / 隐藏目录。
fn should_skip_scan_dir(entry : String) -> Bool {
  entry.has_prefix(".") ||
  entry == "_build" ||
  entry == "target" ||
  entry == "node_modules"
}

///|
/// 把 UNUSED-001 诊断合并进分析报告（在 baseline 保存前调用，使基线包含该诊断）。
fn append_unused_diagnostics(
  report : @analyze.AnalysisReport,
  root_id : String,
  dir : String,
) -> @analyze.AnalysisReport {
  let root_mod = read_module_in_directory(dir)
  let declared = match root_mod {
    Some(m) => m.deps
    None => return report
  }
  if declared.length() == 0 {
    return report
  }
  let fs = @cache.FileSystem::node_js()
  match collect_used_imports(fs, dir) {
    None => report
    Some(imports) => {
      let unused = @analyze.unused_dep_diagnostics(root_id, declared, imports)
      if unused.length() == 0 {
        return report
      }
      let diags : Array[@report.Diagnostic] = []
      for d in report.get_diagnostics() {
        diags.push(d)
      }
      for d in unused {
        diags.push(d)
      }
      @analyze.AnalysisReport::new(
        diagnostics=diags,
        health_scores=report.get_health_scores(),
        overall_score=report.get_overall_score(),
        node_count=report.get_node_count(),
        size_offenders_top5=report.get_size_offenders(),
      )
    }
  }
}

///|
fn run_audit(opts : CliOptions) -> Int {
  let (graph, root_id, metas) = build_full_graph(opts)
  let mut report = @analyze.run_analysis(graph, metas)
  // UNUSED-001：在保存基线之前合并，使基线包含未使用依赖诊断
  report = append_unused_diagnostics(report, root_id, ".")

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
              print_error("invalid baseline JSON: " + msg)
              return exit_io_error
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
          print_error("cannot read baseline file: " + baseline_path)
          return exit_io_error
        }
      }
      let baseline_report = match @analyze.parse_audit_json(baseline_text) {
        Ok(r) => r
        Err(msg) => {
          print_error("invalid baseline JSON: " + msg)
          return exit_io_error
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

  let format = if opts.format == "" { "audit" } else { opts.format }
  let output_text = match
    @analyze.render_with_format(format, display_report, graph, root_id) {
    Ok(text) => text
    Err(msg) => {
      print_error(msg)
      return exit_args_error
    }
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
  let mut report = @analyze.run_analysis(graph, metas)
  report = append_unused_diagnostics(report, root_id, ".")

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

  let format = if opts.format == "" { "terminal" } else { opts.format }
  let output_text = match
    @analyze.render_with_format(format, display_report, graph, root_id) {
    Ok(text) => text
    Err(msg) => {
      print_error(msg)
      return exit_args_error
    }
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
fn scan_workspace(fs : @cache.FileSystem, root_dir : String) -> Array[String] {
  let results = []
  let dirs_to_visit = [root_dir]
  let skip_dirs = [
    ".git", ".github", "node_modules", "_build", "target", ".codebuddy",
  ]
  while dirs_to_visit.length() > 0 {
    let dir = dirs_to_visit.remove(dirs_to_visit.length() - 1)
    // 检查当前目录是否有 moon.mod
    let moon_mod_path = (fs.path_join)(dir, "moon.mod")
    if (fs.exists)(moon_mod_path) {
      results.push(dir)
    }
    // 递归子目录
    match (fs.readdir)(dir) {
      Some(entries) =>
        for entry in entries {
          let full = (fs.path_join)(dir, entry)
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
        let mut report = @analyze.run_analysis(graph, metas)
        report = append_unused_diagnostics(report, root_id, dir)
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
        let mut report = @analyze.run_analysis(graph, metas)
        report = append_unused_diagnostics(report, root_id, dir)
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

  let (g, rid) = all_graphs[0]
  let format = if opts.format == "" { "terminal" } else { opts.format }
  let output_text = match
    @analyze.render_with_format(format, display_report, g, rid) {
    Ok(text) => text
    Err(msg) => {
      print_error(msg)
      return exit_args_error
    }
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

// ========== 命令：outdated, why, check, stats ==========

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
/// 显示依赖溯源
fn run_why(opts : CliOptions) -> Int {
  let target = opts.target_pkg
  if target == "root" {
    print_error("Please specify a package name")
    println("")
    println("Usage: depsight why <package-name>")
    println("Example: depsight why moonbitlang/core")
    return exit_args_error
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
  let (graph, root_id, metas) = build_full_graph(opts)
  let mut report = @analyze.run_analysis(graph, metas)
  report = append_unused_diagnostics(report, root_id, ".")

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
