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
} derive(Debug)

///|
/// 构造 AnalysisReport（用于 blackbox test 直接构造）
pub fn AnalysisReport::new(
  diagnostics? : Array[@report.Diagnostic] = [],
  health_scores? : Array[HealthScore] = [],
  overall_score? : Int = 100,
  node_count? : Int = 0,
) -> AnalysisReport {
  { diagnostics, health_scores, overall_score, node_count, }
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
/// 对依赖图运行完整分析
///
/// `node_metas` 的 key 为节点 ID（`name@version`），value 为该节点的附加元数据。
pub fn run_analysis(
  graph : @graph.DependencyGraph,
  node_metas : Map[String, NodeMeta],
) -> AnalysisReport {
  let diagnostics : Array[@report.Diagnostic] = []

  // 1. 循环依赖检测
  let cycle_diags = graph.check_cycles()
  for d in cycle_diags {
    diagnostics.push(d)
  }

  // 2. 逐节点分析
  let scores : Array[HealthScore] = []
  let all_ids = graph.get_all_node_ids()
  for id in all_ids {
    let meta = match node_metas.get(id) {
      Some(m) => m
      None => NodeMeta::new()
    }
    let (_, version) = split_node_id(id)
    let input = NodeScoreInput::new(
      id,
      version,
      latest_version=meta.latest_version,
      license_spdx=meta.license,
      deprecated_count=meta.deprecated_apis.length(),
      total_api_count=meta.total_api_count,
      transitive_size=Some(meta.self_size),
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
  {
    diagnostics,
    health_scores: scores,
    overall_score: overall,
    node_count: all_ids.length(),
  }
}
