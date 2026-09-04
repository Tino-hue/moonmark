///|
/// 全景依赖生态统计（F05 `depsight stats`）
///
/// 收集依赖图 / 健康报告 / 节点元数据里的 18 项指标，
/// 适合终端 ASCII 表格展示 / JSON 全景导出。
pub struct EcosystemStats {
  // ---------- Graph 维度（6） ----------
  /// 传递闭包里所有节点数（name@version 粒度）
  total_nodes : Int
  /// 去重包名数量（同名不同版本合并）：比 total_nodes 更能体现"生态广度"
  total_unique_packages : Int
  /// 图上有向边总数（A → B 的依赖关系）
  total_edges : Int
  /// 最长依赖链深度（root depth=0）
  max_depth : Int
  /// 所有节点的平均依赖深度（保留 1 位小数）
  avg_depth : Double
  /// 是否存在循环依赖（诊断码 CYCLE-001 命中）
  cycle_detected : Bool

  // ---------- Dependency 维度（4） ----------
  /// root 节点 ID（如果没有节点 = ""）
  root_id : String
  /// 叶子节点数（children=[] 的包，终端用户关心"到底传了多少新包"）
  leaf_package_count : Int
  /// 被最多包直接依赖的包名（最多 1 个；并列时返回最先遇到的）
  most_depended_package : String
  /// most_depended_package 的直接被依赖次数（入度）
  most_depended_count : Int

  // ---------- Health 维度（7） ----------
  /// 整体健康分（0-100，来自 AnalysisReport::overall_score）
  overall_health_score : Int
  /// 平均健康分（各节点 total 的均值，0-100）
  average_node_score : Int
  /// 高风险节点数（health score < 70 的节点）
  nodes_at_risk_below_70 : Int
  /// 警戒节点数（70 ≤ score < 85）
  nodes_warning_70_85 : Int
  /// 诊断总数：critical 级别
  diagnostics_critical : Int
  /// 诊断总数：warning 级别
  diagnostics_warning : Int
  /// 诊断总数：info 级别
  diagnostics_info : Int

  // ---------- 诊断/合规 维度（3） ----------
  /// 至少暴露 1 条 deprecated API 的节点数（DEPRECATED-001 的源头）
  deprecated_source_packages : Int
  /// 所有节点传递体积字节总和（重复计：每个节点的 transitive 累加）
  total_transitive_size_bytes : Int
  /// 协议分布：key = SPDX（可能 "Unknown"），value = 节点计数
  license_distribution : Map[String, Int]
  /// 协议种类数（快速一眼看出协议多样性：越大越杂）
  license_species : Int
} derive(Debug)

///|
/// 构造 EcosystemStats（用于测试直接构造；生产环境请使用下面的 calculate_*）
pub fn EcosystemStats::new(
  total_nodes? : Int = 0,
  total_unique_packages? : Int = 0,
  total_edges? : Int = 0,
  max_depth? : Int = 0,
  avg_depth? : Double = 0.0,
  cycle_detected? : Bool = false,
  root_id? : String = "",
  leaf_package_count? : Int = 0,
  most_depended_package? : String = "",
  most_depended_count? : Int = 0,
  overall_health_score? : Int = 0,
  average_node_score? : Int = 0,
  nodes_at_risk_below_70? : Int = 0,
  nodes_warning_70_85? : Int = 0,
  diagnostics_critical? : Int = 0,
  diagnostics_warning? : Int = 0,
  diagnostics_info? : Int = 0,
  deprecated_source_packages? : Int = 0,
  total_transitive_size_bytes? : Int = 0,
  license_distribution? : Map[String, Int] = Map([]),
  license_species? : Int = 0,
) -> EcosystemStats {
  {
    total_nodes,
    total_unique_packages,
    total_edges,
    max_depth,
    avg_depth,
    cycle_detected,
    root_id,
    leaf_package_count,
    most_depended_package,
    most_depended_count,
    overall_health_score,
    average_node_score,
    nodes_at_risk_below_70,
    nodes_warning_70_85,
    diagnostics_critical,
    diagnostics_warning,
    diagnostics_info,
    deprecated_source_packages,
    total_transitive_size_bytes,
    license_distribution,
    license_species,
  }
}

///|
/// 基于依赖图 + AnalysisReport + 各节点元数据计算全景 21 项统计指标（F05 核心算法）
pub fn calculate_ecosystem_stats(
  graph : @graph.DependencyGraph,
  report : AnalysisReport,
  node_metas : Map[String, NodeMeta],
  root_id : String,
) -> EcosystemStats {
  let ids = graph.get_all_node_ids()
  let total_nodes = ids.length()

  // --- Graph 维度：unique_packages / total_edges / max_depth / avg_depth / cycle / leaves ---
  let unique_names : Map[String, Bool] = Map([])
  let mut total_edges = 0
  let mut max_depth = 0
  let mut total_depth = 0
  let mut leaf_count = 0
  let in_degree : Map[String, Int] = Map([]) // name 粒度（旧生态统计的风格：被依赖按包不按版本）
  for id in ids {
    match graph.get_node_by_id(id) {
      Some(node) => {
        unique_names[node.name] = true
        if node.depth > max_depth {
          max_depth = node.depth
        }
        total_depth = total_depth + node.depth
        // children 就是 A→B 的边：每个 node.children.length() 是这个节点出发的边数
        total_edges = total_edges + node.children.length()
        if node.children.length() == 0 {
          leaf_count = leaf_count + 1
        }
        // 被依赖入度（按 name 聚合，不同版本的同包累加）
        for _parent in node.parents {
          in_degree[node.name] = match in_degree.get(node.name) {
            Some(c) => c + 1
            None => 1
          }
        }
      }
      None => ()
    }
  }
  let total_unique_packages = unique_names.length()
  let avg_depth = if total_nodes > 0 {
    // 保留 1 位小数（乘以 10 四舍五入再除 10.0）
    let scaled = (total_depth * 10 + total_nodes / 2) / total_nodes
    scaled.to_double() / 10.0
  } else {
    0.0
  }

  // most-depended package（name 粒度）
  let mut most_depended_package = ""
  let mut most_depended_count = 0
  for pair in in_degree {
    let (name, count) = pair
    if count > most_depended_count {
      most_depended_package = name
      most_depended_count = count
    }
  }

  // cycle detected
  let cycle_detected = report.diagnostics
    .iter()
    .any(fn(d) { d.code == "CYCLE-001" })

  // --- Health 维度：overall / avg_score / risk_count / warning_count ---
  let overall_health_score = report.overall_score
  let scores = report.health_scores
  let mut sum_score = 0
  let mut below_70 = 0
  let mut warn_70_85 = 0
  for s in scores {
    sum_score = sum_score + s.total
    if s.total < 70 {
      below_70 = below_70 + 1
    } else if s.total < 85 {
      warn_70_85 = warn_70_85 + 1
    }
  }
  let average_node_score = if scores.length() > 0 {
    sum_score / scores.length()
  } else {
    0
  }

  // --- 诊断三段计数 ---
  let mut critical = 0
  let mut warning = 0
  let mut info = 0
  for d in report.diagnostics {
    if d.is_critical() {
      critical = critical + 1
    } else if d.is_warning() {
      warning = warning + 1
    } else {
      info = info + 1
    }
  }

  // --- 合规 + 体积 + deprecated ---
  let mut deprecated_sources = 0
  let mut total_transitive = 0
  let self_sizes_map : Map[String, Int] = Map([])
  for id2 in ids {
    let meta = match node_metas.get(id2) {
      Some(m) => m
      None => NodeMeta::new()
    }
    self_sizes_map[id2] = meta.self_size
    if meta.deprecated_apis.length() > 0 {
      deprecated_sources = deprecated_sources + 1
    }
  }
  let trans_map = calculate_transitive_sizes(graph, self_sizes_map)
  for pair in trans_map {
    let (_, sz) = pair
    total_transitive = total_transitive + sz
  }

  // license 分布：meta.license 有则用 SPDX，没有记作 "Unknown"
  let license_dist : Map[String, Int] = Map([])
  for id3 in ids {
    let spdx = match node_metas.get(id3) {
      Some(m) =>
        match m.license {
          Some(s) => s
          None => "Unknown"
        }
      None => "Unknown"
    }
    license_dist[spdx] = match license_dist.get(spdx) {
      Some(c) => c + 1
      None => 1
    }
  }
  let license_species = license_dist.length()

  EcosystemStats::new(
    total_nodes~,
    total_unique_packages~,
    total_edges~,
    max_depth~,
    avg_depth~,
    cycle_detected~,
    root_id~,
    leaf_package_count=leaf_count,
    most_depended_package~,
    most_depended_count~,
    overall_health_score~,
    average_node_score~,
    nodes_at_risk_below_70=below_70,
    nodes_warning_70_85=warn_70_85,
    diagnostics_critical=critical,
    diagnostics_warning=warning,
    diagnostics_info=info,
    deprecated_source_packages=deprecated_sources,
    total_transitive_size_bytes=total_transitive,
    license_distribution=license_dist,
    license_species~,
  )
}

// ========== 终端渲染 ==========

///|
/// 把 EcosystemStats 渲染成 ASCII 两张表的终端友好字符串。
pub fn render_ecosystem_stats_terminal(stats : EcosystemStats) -> String {
  let buf = StringBuilder()
  buf.write_string(
    bold("╔══ MoonBit Depsight — Ecosystem Stats ══╗"),
  )
  buf.write_string("\n\n")

  // ---- Table 1: Overview（分组 4 段） ----
  let col_key = 34
  let col_val = 26
  buf.write_string(bold("─── Overview ───"))
  buf.write_string("\n")
  buf.write_string("┌")
  buf.write_string(repeat_char("─", col_key))
  buf.write_string("┬")
  buf.write_string(repeat_char("─", col_val))
  buf.write_string("┐\n")
  buf.write_string("│")
  buf.write_string(bold(pad_center("Metric", col_key)))
  buf.write_string("│")
  buf.write_string(bold(pad_center("Value", col_val)))
  buf.write_string("│\n")

  // Helper：输出"分组行"（同 buf 上）
  let print_section = fn(title : String) {
    buf.write_string("├")
    buf.write_string(repeat_char("─", col_key))
    buf.write_string("┼")
    buf.write_string(repeat_char("─", col_val))
    buf.write_string("┤\n")
    buf.write_string("│")
    buf.write_string(bold(pad_left(" " + title, col_key)))
    buf.write_string("│")
    buf.write_string(pad_left("", col_val))
    buf.write_string("│\n")
  }
  // Helper：输出一行 k/v（原色 v）
  let print_row = fn(k : String, v : String) {
    buf.write_string("│")
    buf.write_string(pad_left(k, col_key))
    buf.write_string("│")
    buf.write_string(pad_left(v, col_val))
    buf.write_string("│\n")
  }
  // Helper：输出一行 dim（次要指标）
  let print_dim = fn(k : String, v : String) {
    buf.write_string("│")
    buf.write_string(pad_left(dim(k), col_key))
    buf.write_string("│")
    buf.write_string(pad_left(dim(v), col_val))
    buf.write_string("│\n")
  }

  // Graph
  print_section("Graph")
  print_row("Total nodes (name@version)", stats.total_nodes.to_string())
  print_dim(
    "Unique packages (dedup name)",
    stats.total_unique_packages.to_string(),
  )
  print_dim("Edges (direct deps)", stats.total_edges.to_string())
  print_dim("Max dependency depth", stats.max_depth.to_string())
  print_dim("Avg dependency depth", format_double_1(stats.avg_depth))
  print_dim(
    "Cycle detected?",
    if stats.cycle_detected {
      "YES (see CYCLE-001)"
    } else {
      "no"
    },
  )

  // Dependency
  print_section("Dependency")
  print_row("Root project", truncate(stats.root_id, col_val - 2))
  print_dim("Leaf packages (no children)", stats.leaf_package_count.to_string())
  print_dim(
    "Most depended package",
    truncate(stats.most_depended_package, col_val - 2),
  )
  print_dim(
    "  ↳ in-degree (direct refs)",
    stats.most_depended_count.to_string(),
  )

  // Health
  print_section("Health")
  print_row(
    "Overall health score",
    stats.overall_health_score.to_string() + " / 100",
  )
  print_dim(
    "Average node score",
    stats.average_node_score.to_string() + " / 100",
  )
  print_dim(
    "Nodes at risk (< 70)",
    red(stats.nodes_at_risk_below_70.to_string()),
  )
  print_dim(
    "Nodes warning (70..84)",
    yellow(stats.nodes_warning_70_85.to_string()),
  )
  print_dim("Diagnostics critical", red(stats.diagnostics_critical.to_string()))
  print_dim(
    "Diagnostics warning",
    yellow(stats.diagnostics_warning.to_string()),
  )
  print_dim("Diagnostics info", green(stats.diagnostics_info.to_string()))

  // Compliance + Size
  print_section("Compliance + Size")
  print_row(
    "Deprecated source packages",
    stats.deprecated_source_packages.to_string(),
  )
  print_dim(
    "Total transitive size",
    format_size(stats.total_transitive_size_bytes),
  )
  print_dim("License species", stats.license_species.to_string())

  buf.write_string("└")
  buf.write_string(repeat_char("─", col_key))
  buf.write_string("┴")
  buf.write_string(repeat_char("─", col_val))
  buf.write_string("┘\n")

  // ---- Table 2: License distribution ----
  if stats.license_distribution.length() > 0 {
    buf.write_string("\n")
    buf.write_string(bold("─── License Distribution ───"))
    buf.write_string("\n")
    let lk = 36
    let lv = 12
    let lp = 22
    buf.write_string("┌")
    buf.write_string(repeat_char("─", lk))
    buf.write_string("┬")
    buf.write_string(repeat_char("─", lv))
    buf.write_string("┬")
    buf.write_string(repeat_char("─", lp))
    buf.write_string("┐\n")
    buf.write_string("│")
    buf.write_string(bold(pad_center("License SPDX", lk)))
    buf.write_string("│")
    buf.write_string(bold(pad_center("Count", lv)))
    buf.write_string("│")
    buf.write_string(bold(pad_center("Share", lp)))
    buf.write_string("│\n")
    buf.write_string("├")
    buf.write_string(repeat_char("─", lk))
    buf.write_string("┼")
    buf.write_string(repeat_char("─", lv))
    buf.write_string("┼")
    buf.write_string(repeat_char("─", lp))
    buf.write_string("┤\n")

    let items : Array[(String, Int)] = []
    for pair in stats.license_distribution {
      let (k, v) = pair
      items.push((k, v))
    }
    // sort by count desc (bubble)
    let n = items.length()
    let mut i = 0
    while i < n {
      let mut j = 0
      while j < n - i - 1 {
        if items[j].1 < items[j + 1].1 {
          let tmp = items[j]
          items[j] = items[j + 1]
          items[j + 1] = tmp
        }
        j = j + 1
      }
      i = i + 1
    }
    for item in items {
      let (spdx, count) = item
      let share = if stats.total_nodes > 0 {
        (count * 100 + stats.total_nodes / 2) / stats.total_nodes
      } else {
        0
      }
      let share_str = share.to_string() +
        "% (" +
        count.to_string() +
        "/" +
        stats.total_nodes.to_string() +
        ")"
      buf.write_string("│")
      buf.write_string(pad_left(truncate(spdx, lk - 2), lk))
      buf.write_string("│")
      buf.write_string(pad_left(count.to_string(), lv))
      buf.write_string("│")
      buf.write_string(pad_left(truncate(share_str, lp - 2), lp))
      buf.write_string("│\n")
    }
    buf.write_string("└")
    buf.write_string(repeat_char("─", lk))
    buf.write_string("┴")
    buf.write_string(repeat_char("─", lv))
    buf.write_string("┴")
    buf.write_string(repeat_char("─", lp))
    buf.write_string("┘\n")
  }

  buf.to_string()
}

///|
/// 把 EcosystemStats 渲染成 JSON 字符串（--json 模式）
pub fn render_ecosystem_stats_json(stats : EcosystemStats) -> String {
  let buf = StringBuilder()
  buf.write_string("{")
  buf.write_string("\"total_nodes\":")
  buf.write_string(stats.total_nodes.to_string())
  buf.write_string(",\"total_unique_packages\":")
  buf.write_string(stats.total_unique_packages.to_string())
  buf.write_string(",\"total_edges\":")
  buf.write_string(stats.total_edges.to_string())
  buf.write_string(",\"max_depth\":")
  buf.write_string(stats.max_depth.to_string())
  buf.write_string(",\"avg_depth\":")
  buf.write_string(format_double_1(stats.avg_depth))
  buf.write_string(",\"cycle_detected\":")
  let cycle_str = if stats.cycle_detected { "true" } else { "false" }
  buf.write_string(cycle_str)
  buf.write_string(",\"root_id\":")
  buf.write_string(json_escape(stats.root_id))

  buf.write_string(",\"leaf_package_count\":")
  buf.write_string(stats.leaf_package_count.to_string())
  buf.write_string(",\"most_depended_package\":")
  buf.write_string(json_escape(stats.most_depended_package))
  buf.write_string(",\"most_depended_count\":")
  buf.write_string(stats.most_depended_count.to_string())

  buf.write_string(",\"overall_health_score\":")
  buf.write_string(stats.overall_health_score.to_string())
  buf.write_string(",\"average_node_score\":")
  buf.write_string(stats.average_node_score.to_string())
  buf.write_string(",\"nodes_at_risk_below_70\":")
  buf.write_string(stats.nodes_at_risk_below_70.to_string())
  buf.write_string(",\"nodes_warning_70_85\":")
  buf.write_string(stats.nodes_warning_70_85.to_string())
  buf.write_string(",\"diagnostics_critical\":")
  buf.write_string(stats.diagnostics_critical.to_string())
  buf.write_string(",\"diagnostics_warning\":")
  buf.write_string(stats.diagnostics_warning.to_string())
  buf.write_string(",\"diagnostics_info\":")
  buf.write_string(stats.diagnostics_info.to_string())

  buf.write_string(",\"deprecated_source_packages\":")
  buf.write_string(stats.deprecated_source_packages.to_string())
  buf.write_string(",\"total_transitive_size_bytes\":")
  buf.write_string(stats.total_transitive_size_bytes.to_string())
  buf.write_string(",\"license_species\":")
  buf.write_string(stats.license_species.to_string())

  buf.write_string(",\"license_distribution\":{")
  let mut first = true
  for pair in stats.license_distribution {
    let (spdx, count) = pair
    if first {
      first = false
    } else {
      buf.write_string(",")
    }
    buf.write_string(json_escape(spdx))
    buf.write_string(":")
    buf.write_string(count.to_string())
  }
  buf.write_string("}")

  buf.write_string("}")
  buf.to_string()
}

// ========== 内部辅助 ==========

///|
/// Double 格式化为保留 1 位小数的字符串（0.0 ~ ...）
fn format_double_1(v : Double) -> String {
  let scaled = (v * 10.0).round().to_int()
  let int_part = scaled / 10
  let frac_part = if scaled < 0 { -scaled % 10 } else { scaled % 10 }
  int_part.to_string() + "." + frac_part.to_string()
}

///|
/// 简单 JSON string escape：围绕 " 和 \ + 控制字符做最小转义
fn json_escape(s : String) -> String {
  let buf = StringBuilder()
  buf.write_string("\"")
  let n = s.length()
  let mut i = 0
  while i < n {
    let code = s[i].to_int()
    if code == '"'.to_int() {
      buf.write_string("\\\"")
    } else if code == '\\'.to_int() {
      buf.write_string("\\\\")
    } else if code == '\n'.to_int() {
      buf.write_string("\\n")
    } else if code == '\r'.to_int() {
      buf.write_string("\\r")
    } else if code == '\t'.to_int() {
      buf.write_string("\\t")
    } else if code < 0x20 {
      buf.write_string("\\u00")
      buf.write_string(format_hex2(code))
    } else {
      buf.write_string(substring(s, i, 1))
    }
    i = i + 1
  }
  buf.write_string("\"")
  buf.to_string()
}

///|
/// 0-255 的 Int → 两位小写十六进制（用于 \u00XX）
fn format_hex2(code : Int) -> String {
  let hex = "0123456789abcdef"
  let hi = code / 16 % 16
  let lo = code % 16
  substring(hex, hi, 1) + substring(hex, lo, 1)
}
