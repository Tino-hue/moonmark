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
  inspect(score.total, content="100")
  inspect(score.freshness, content="100")
  inspect(score.compliance, content="100")
  inspect(score.deprecated_density, content="100")
  inspect(score.size_reasonableness, content="100")
  inspect(score.activity, content="100")
}

test "outdated major version" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    latest_version=Some("2.0.0"),
  )
  let score = calculate_health_score(input)
  inspect(score.freshness, content="60")
}

test "outdated minor version" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    latest_version=Some("1.5.0"),
  )
  let score = calculate_health_score(input)
  inspect(score.freshness, content="80")
}

test "outdated patch version" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    latest_version=Some("1.0.5"),
  )
  let score = calculate_health_score(input)
  inspect(score.freshness, content="95")
}

test "high risk license" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    license_spdx=Some("GPL-3.0"),
  )
  let score = calculate_health_score(input)
  inspect(score.compliance, content="0")
}

test "unknown license" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    license_spdx=None,
  )
  let score = calculate_health_score(input)
  inspect(score.compliance, content="80")
}

test "high deprecated density" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    deprecated_count=6,
    total_api_count=10,
  )
  let score = calculate_health_score(input)
  inspect(score.deprecated_density, content="20")
}

test "moderate deprecated density" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    deprecated_count=2,
    total_api_count=10,
  )
  let score = calculate_health_score(input)
  inspect(score.deprecated_density, content="70")
}

test "zero deprecated" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    deprecated_count=0,
    total_api_count=10,
  )
  let score = calculate_health_score(input)
  inspect(score.deprecated_density, content="100")
}

test "large size" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    transitive_size=Some(10 * 1024 * 1024),
  )
  let score = calculate_health_score(input)
  inspect(score.size_reasonableness, content="20")
}

test "small size" {
  let input = NodeScoreInput::new(
    "pkg@1.0.0",
    "1.0.0",
    transitive_size=Some(1024),
  )
  let score = calculate_health_score(input)
  inspect(score.size_reasonableness, content="100")
}

test "overall score average" {
  let scores = [
    calculate_health_score(NodeScoreInput::new("a@1.0.0", "1.0.0", latest_version=Some("1.0.0"), license_spdx=Some("MIT"))),
    calculate_health_score(NodeScoreInput::new("b@1.0.0", "2.0.0", latest_version=Some("2.0.0"), license_spdx=Some("MIT"))),
  ]
  inspect(calculate_overall_score(scores), content="96")
}

test "overall score empty" {
  inspect(calculate_overall_score([]), content="100")
}
