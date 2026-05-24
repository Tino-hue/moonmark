test "perfect health score" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    latest_version=Some("1.0.0"),
    license_spdx=Some("MIT"),
    deprecated_count=0,
    total_api_count=10,
    transitive_size=Some(1024),
  )
  let score = calculate_health_score(input)
  assert_eq(score.total, 100)
  assert_eq(score.freshness, 100)
  assert_eq(score.compliance, 100)
  assert_eq(score.deprecated_density, 100)
  assert_eq(score.size_reasonableness, 100)
  assert_eq(score.activity, 100)
}

test "outdated major version" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    latest_version=Some("2.0.0"),
  )
  let score = calculate_health_score(input)
  assert_eq(score.freshness, 60)
}

test "outdated minor version" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    latest_version=Some("1.5.0"),
  )
  let score = calculate_health_score(input)
  assert_eq(score.freshness, 80)
}

test "outdated patch version" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    latest_version=Some("1.0.5"),
  )
  let score = calculate_health_score(input)
  assert_eq(score.freshness, 95)
}

test "high risk license" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    license_spdx=Some("GPL-3.0"),
  )
  let score = calculate_health_score(input)
  assert_eq(score.compliance, 0)
}

test "unknown license" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    license_spdx=None,
  )
  let score = calculate_health_score(input)
  assert_eq(score.compliance, 80)
}

test "high deprecated density" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    deprecated_count=6,
    total_api_count=10,
  )
  let score = calculate_health_score(input)
  assert_eq(score.deprecated_density, 20)
}

test "moderate deprecated density" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    deprecated_count=2,
    total_api_count=10,
  )
  let score = calculate_health_score(input)
  assert_eq(score.deprecated_density, 70)
}

test "zero deprecated" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    deprecated_count=0,
    total_api_count=10,
  )
  let score = calculate_health_score(input)
  assert_eq(score.deprecated_density, 100)
}

test "large size" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    transitive_size=Some(10 * 1024 * 1024),
  )
  let score = calculate_health_score(input)
  assert_eq(score.size_reasonableness, 20)
}

test "small size" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    transitive_size=Some(1024),
  )
  let score = calculate_health_score(input)
  assert_eq(score.size_reasonableness, 100)
}

test "overall score average" {
  let scores = [
    calculate_health_score(NodeScoreInput::new("a@1.0.0", "1.0.0", latest_version=Some("1.0.0"), license_spdx=Some("MIT"))),
    calculate_health_score(NodeScoreInput::new("b@1.0.0", "2.0.0", latest_version=Some("2.0.0"), license_spdx=Some("MIT"))),
  ]
  assert_eq(calculate_overall_score(scores), 96)
}

test "overall score empty" {
  assert_eq(calculate_overall_score([]), 100)
}
