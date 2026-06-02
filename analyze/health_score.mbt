/// 节点评分输入
pub struct NodeScoreInput {
  node_id : String
  current_version : String
  latest_version : String?
  license_spdx : String?
  deprecated_count : Int
  total_api_count : Int
  transitive_size : Int?
  last_commit_days_ago : Int?
}

/// 构造 NodeScoreInput
pub fn NodeScoreInput::new(
  node_id : String,
  current_version : String,
  latest_version~ : String? = None,
  license_spdx~ : String? = None,
  deprecated_count~ : Int = 0,
  total_api_count~ : Int = 0,
  transitive_size~ : Int? = None,
  last_commit_days_ago~ : Int? = None
) -> NodeScoreInput {
  { node_id, current_version, latest_version, license_spdx, deprecated_count, total_api_count, transitive_size, last_commit_days_ago }
}

/// 健康评分结果
pub struct HealthScore {
  node_id : String
  total : Int
  freshness : Int
  compliance : Int
  deprecated_density : Int
  size_reasonableness : Int
  activity : Int
} derive(Debug)

/// 构造 HealthScore（用于 blackbox test 直接构造）
pub fn HealthScore::new(
  node_id : String,
  total : Int,
  freshness~ : Int = 0,
  compliance~ : Int = 0,
  deprecated_density~ : Int = 0,
  size_reasonableness~ : Int = 0,
  activity~ : Int = 0
) -> HealthScore {
  { node_id, total, freshness, compliance, deprecated_density, size_reasonableness, activity }
}

/// 健康评分权重（总和应为 100）
pub struct ScoreWeights {
  freshness : Int
  compliance : Int
  deprecated_density : Int
  size_reasonableness : Int
  activity : Int
} derive(Debug)

/// 默认权重
pub fn default_weights() -> ScoreWeights {
  { freshness: 25, compliance: 20, deprecated_density: 25, size_reasonableness: 20, activity: 10 }
}

/// 从权重值构造（如果总和不是 100 则使用默认值）
pub fn ScoreWeights::new(
  freshness? : Int = 25,
  compliance? : Int = 20,
  deprecated_density? : Int = 25,
  size_reasonableness? : Int = 20,
  activity? : Int = 10,
) -> ScoreWeights {
  let total = freshness + compliance + deprecated_density + size_reasonableness + activity
  if total == 100 {
    { freshness, compliance, deprecated_density, size_reasonableness, activity }
  } else {
    default_weights()
  }
}

/// 计算单个节点的健康评分（0-100）
/// 默认权重：版本新鲜度 25%、协议合规 20%、废弃密度 25%、体积合理性 20%、活跃度 10%
pub fn calculate_health_score(input : NodeScoreInput) -> HealthScore {
  calculate_health_score_with_weights(input, default_weights())
}

/// 使用自定义权重计算健康评分
pub fn calculate_health_score_with_weights(input : NodeScoreInput, w : ScoreWeights) -> HealthScore {
  let freshness = score_freshness(input.current_version, input.latest_version)
  let compliance = score_compliance(input.license_spdx)
  let deprecated_density = score_deprecated_density(input.deprecated_count, input.total_api_count)
  let size_reasonableness = score_size_reasonableness(input.transitive_size)
  let activity = score_activity(input.last_commit_days_ago)

  let total = freshness * w.freshness / 100 +
    compliance * w.compliance / 100 +
    deprecated_density * w.deprecated_density / 100 +
    size_reasonableness * w.size_reasonableness / 100 +
    activity * w.activity / 100

  { node_id: input.node_id, total, freshness, compliance, deprecated_density, size_reasonableness, activity }
}

/// 计算整体健康分（多个节点的平均分）
pub fn calculate_overall_score(scores : Array[HealthScore]) -> Int {
  if scores.length() == 0 { return 100 }
  let mut sum = 0
  for s in scores {
    sum = sum + s.total
  }
  sum / scores.length()
}

// ---------- 维度打分函数 ----------

fn score_freshness(current : String, latest : String?) -> Int {
  match latest {
    None => 100
    Some(latest_str) => {
      let v1 = match parse_version(current) {
        Ok(v) => v
        Err(_) => return 50
      }
      let v2 = match parse_version(latest_str) {
        Ok(v) => v
        Err(_) => return 50
      }
      let cmp = compare(v1, v2)
      if cmp >= 0 {
        return 100
      }
      // v1 < v2
      if v1.major != v2.major {
        return 60
      }
      if v1.minor != v2.minor {
        return 80
      }
      if v1.patch != v2.patch {
        return 95
      }
      // prerelease 差异
      85
    }
  }
}

fn score_compliance(spdx_id : String?) -> Int {
  match spdx_id {
    None => 80
    Some(id) => if is_high_risk_license(id) { 0 } else { 100 }
  }
}

fn score_deprecated_density(deprecated_count : Int, total_api_count : Int) -> Int {
  if total_api_count == 0 { return 100 }
  if deprecated_count == 0 { return 100 }
  let pct = deprecated_count * 100 / total_api_count
  if pct <= 10 { return 90 }
  if pct <= 30 { return 70 }
  if pct <= 50 { return 50 }
  20
}

fn score_size_reasonableness(size : Int?) -> Int {
  match size {
    None => 80
    Some(bytes) => {
      if bytes < 10 * 1024 { return 100 }
      if bytes < 100 * 1024 { return 90 }
      if bytes < 1024 * 1024 { return 70 }
      if bytes < 5 * 1024 * 1024 { return 50 }
      20
    }
  }
}

fn score_activity(days_ago : Int?) -> Int {
  match days_ago {
    None => 80 // 未知仓库，给中等分数
    Some(d) => {
      if d <= 30 { 100 }
      else if d <= 90 { 80 }
      else if d <= 180 { 60 }
      else if d <= 365 { 40 }
      else { 20 }
    }
  }
}
