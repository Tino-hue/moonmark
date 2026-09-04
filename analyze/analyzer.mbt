///|
/// 节点分析所需的元数据
pub struct NodeMeta {
  license : String?
  deprecated_apis : Array[DeprecatedApi]
  latest_version : String?
  self_size : Int
  last_commit_days_ago : Int?
  total_api_count : Int
}

///|
/// 构造 NodeMeta
pub fn NodeMeta::new(
  license? : String? = None,
  deprecated_apis? : Array[DeprecatedApi] = [],
  latest_version? : String? = None,
  self_size? : Int = 0,
  last_commit_days_ago? : Int? = None,
  total_api_count? : Int = 0,
) -> NodeMeta {
  {
    license,
    deprecated_apis,
    latest_version,
    self_size,
    last_commit_days_ago,
    total_api_count,
  }
}

///|
/// 完整分析报告
pub struct AnalysisReport {
  diagnostics : Array[@report.Diagnostic]
  health_scores : Array[HealthScore]
  overall_score : Int
  node_count : Int
  /// Top N 体积罪犯（按传递大小降序，最多 5 条），
  /// 供终端/HTML/Markdown 报告展示传递体积归因。若 self_size 数据源
  /// 全为空（例如降级元数据），则本数组也为空以避免无意义的排行榜。
  size_offenders_top5 : Array[SizeInfo]
} derive(Debug)

///|
/// 构造 AnalysisReport（用于 blackbox test 直接构造）
pub fn AnalysisReport::new(
  diagnostics? : Array[@report.Diagnostic] = [],
  health_scores? : Array[HealthScore] = [],
  overall_score? : Int = 100,
  node_count? : Int = 0,
  size_offenders_top5? : Array[SizeInfo] = [],
) -> AnalysisReport {
  {
    diagnostics,
    health_scores,
    overall_score,
    node_count,
    size_offenders_top5,
  }
}

///|
pub fn AnalysisReport::get_diagnostics(
  self : AnalysisReport,
) -> Array[@report.Diagnostic] {
  self.diagnostics
}

///|
pub fn AnalysisReport::get_health_scores(
  self : AnalysisReport,
) -> Array[HealthScore] {
  self.health_scores
}

///|
pub fn AnalysisReport::get_overall_score(self : AnalysisReport) -> Int {
  self.overall_score
}

///|
pub fn AnalysisReport::get_node_count(self : AnalysisReport) -> Int {
  self.node_count
}

///|
pub fn AnalysisReport::get_size_offenders(
  self : AnalysisReport,
) -> Array[SizeInfo] {
  self.size_offenders_top5
}

///|
/// 对依赖图运行完整分析
///
/// `node_metas` 的 key 为节点 ID（`name@version`），value 为该节点的附加元数据。
pub fn run_analysis(
  graph : @graph.DependencyGraph,
  node_metas : Map[String, NodeMeta],
) -> AnalysisReport {
  let diagnostics : Array[@report.Diagnostic] = []

  // 0. 收集各节点自身体积 → 计算传递体积（F02 真实体积评分）
  //    没有元数据 / 元数据内 self_size 为 0 的节点也参与传递聚合（贡献 0），
  //    避免把依赖链上的其他节点「误瘦身」。评分侧统一用 None/Some 语义。
  let self_sizes : Map[String, Int] = Map([])
  let all_ids = graph.get_all_node_ids()
  for id in all_ids {
    match node_metas.get(id) {
      Some(meta) => self_sizes[id] = meta.self_size
      None => self_sizes[id] = 0
    }
  }
  let transitive_sizes = calculate_transitive_sizes(graph, self_sizes)
  // 是否有「真实 > 0」的 self_size 数据：如果全是 0，说明没有可用体积元数据，
  // 就不展示 Top 5 体积罪犯榜单，避免空榜误导。
  let mut has_any_real_size = false
  for pair in self_sizes {
    let (_, s) = pair
    if s > 0 {
      has_any_real_size = true
      break
    }
  }

  // 1. 循环依赖检测
  let cycle_diags = graph.check_cycles()
  for d in cycle_diags {
    diagnostics.push(d)
  }

  // 2. 逐节点分析
  let scores : Array[HealthScore] = []
  for id in all_ids {
    let meta = match node_metas.get(id) {
      Some(m) => m
      None => NodeMeta::new()
    }
    let (_, version) = split_node_id(id)
    // 传递体积：只有对应 self_size 真实 > 0 时我们把 Some(transitive) 传入评分，
    // 否则用 None，沿用 score_size_reasonableness 的 "未知 → 80 分" 规则。
    let transitive_for_score = match transitive_sizes.get(id) {
      Some(t) => if meta.self_size > 0 { Some(t) } else { None }
      None => None
    }
    let input = NodeScoreInput::new(
      id,
      version,
      latest_version=meta.latest_version,
      license_spdx=meta.license,
      deprecated_count=meta.deprecated_apis.length(),
      total_api_count=meta.total_api_count,
      transitive_size=transitive_for_score,
      last_commit_days_ago=meta.last_commit_days_ago,
    )
    let score = calculate_health_score(input)
    scores.push(score)

    // License 诊断
    match meta.license {
      Some(spdx) =>
        if is_high_risk_license(spdx) {
          diagnostics.push(
            @report.Diagnostic::warning(
              "LICENSE-001",
              "High-risk license: " + license_name(spdx),
              [id],
            ).with_suggestion("Replace with MIT, Apache-2.0, or BSD-3-Clause"),
          )
        }
      None =>
        diagnostics.push(
          @report.Diagnostic::info("LICENSE-002", "No license info: " + id, [id]).with_suggestion(
            "Add a license field to moon.mod (e.g., \"Apache-2.0\")",
          ),
        )
    }

    // 废弃 API 诊断
    if meta.deprecated_apis.length() > 0 {
      let mut diag = @report.Diagnostic::warning(
        "DEPRECATED-001",
        id +
        " has " +
        meta.deprecated_apis.length().to_string() +
        " deprecated API(s)",
        [id],
      )
      match meta.latest_version {
        Some(v) => diag = diag.with_suggestion("Upgrade to " + v)
        None =>
          diag = diag.with_suggestion(
            "Check the package changelog for migration guide",
          )
      }
      diagnostics.push(diag)
    }
  }

  let overall = calculate_overall_score(scores)
  let top_offenders = if has_any_real_size {
    find_size_offenders(graph, self_sizes, 5)
  } else {
    []
  }
  {
    diagnostics,
    health_scores: scores,
    overall_score: overall,
    node_count: all_ids.length(),
    size_offenders_top5: top_offenders,
  }
}
