fn unwrap_version(r : Result[Version, String]) -> Version {
  match r {
    Ok(v) => v
    Err(msg) => panic("parse_version failed: " + msg)
  }
}

test "parse simple version" {
  let v = unwrap_version(parse_version("1.2.3"))
  assert_eq(v.major, 1)
  assert_eq(v.minor, 2)
  assert_eq(v.patch, 3)
  assert_eq(v.prerelease, None)
}

test "parse version with prerelease" {
  let v = unwrap_version(parse_version("2.0.0-alpha"))
  assert_eq(v.major, 2)
  assert_eq(v.minor, 0)
  assert_eq(v.patch, 0)
  assert_eq(v.prerelease, Some("alpha"))
}

test "parse invalid version" {
  let r = parse_version("not.a.version")
  assert_true(r is Err(_))
}

test "parse empty version" {
  let r = parse_version("")
  assert_true(r is Err(_))
}

test "compare equal versions" {
  let v1 = unwrap_version(parse_version("1.2.3"))
  let v2 = unwrap_version(parse_version("1.2.3"))
  assert_eq(compare(v1, v2), 0)
}

test "compare different major" {
  let v1 = unwrap_version(parse_version("1.0.0"))
  let v2 = unwrap_version(parse_version("2.0.0"))
  assert_eq(compare(v1, v2), -1)
  assert_eq(compare(v2, v1), 1)
}

test "compare different minor" {
  let v1 = unwrap_version(parse_version("1.2.0"))
  let v2 = unwrap_version(parse_version("1.3.0"))
  assert_eq(compare(v1, v2), -1)
}

test "compare different patch" {
  let v1 = unwrap_version(parse_version("1.2.3"))
  let v2 = unwrap_version(parse_version("1.2.4"))
  assert_eq(compare(v1, v2), -1)
}

test "compare prerelease vs stable" {
  let pre = unwrap_version(parse_version("1.0.0-alpha"))
  let stable = unwrap_version(parse_version("1.0.0"))
  assert_eq(compare(pre, stable), -1)
  assert_eq(compare(stable, pre), 1)
}

test "compare prerelease strings" {
  let v1 = unwrap_version(parse_version("1.0.0-alpha"))
  let v2 = unwrap_version(parse_version("1.0.0-beta"))
  assert_eq(compare(v1, v2), -1)
}

test "is outdated" {
  let current = unwrap_version(parse_version("0.1.0"))
  let latest = unwrap_version(parse_version("0.3.0"))
  assert_true(is_outdated(current, latest))
  assert_false(is_outdated(latest, current))
}

test "satisfies exact match" {
  let v = unwrap_version(parse_version("1.2.3"))
  assert_true(satisfies(v, "1.2.3"))
  assert_false(satisfies(v, "1.2.4"))
}

test "satisfies caret" {
  let v = unwrap_version(parse_version("1.2.3"))
  assert_true(satisfies(v, "^1.2.0"))
  assert_true(satisfies(v, "^1.0.0"))
  assert_false(satisfies(v, "^2.0.0"))
  assert_false(satisfies(v, "^1.3.0"))

  // ^0.y.z 只允许 patch 升级
  let v0 = unwrap_version(parse_version("0.2.3"))
  assert_true(satisfies(v0, "^0.2.0"))
  assert_false(satisfies(v0, "^0.3.0"))
}

test "satisfies tilde" {
  let v = unwrap_version(parse_version("1.2.5"))
  assert_true(satisfies(v, "~1.2.0"))
  assert_true(satisfies(v, "~1.2.3"))
  assert_false(satisfies(v, "~1.3.0"))
  assert_false(satisfies(v, "~1.1.0"))
}

test "satisfies tilde arrow" {
  let v = unwrap_version(parse_version("0.2.1"))
  assert_true(satisfies(v, "~> 0.2.0"))
  assert_false(satisfies(v, "~> 0.3.0"))
}

test "satisfies greater than or equal" {
  let v = unwrap_version(parse_version("2.0.0"))
  assert_true(satisfies(v, ">=1.0.0"))
  assert_true(satisfies(v, ">=2.0.0"))
  assert_false(satisfies(v, ">=3.0.0"))
}

test "satisfies greater than" {
  let v = unwrap_version(parse_version("2.0.0"))
  assert_true(satisfies(v, ">1.0.0"))
  assert_false(satisfies(v, ">2.0.0"))
}

test "satisfies less than or equal" {
  let v = unwrap_version(parse_version("1.5.0"))
  assert_true(satisfies(v, "<=2.0.0"))
  assert_true(satisfies(v, "<=1.5.0"))
  assert_false(satisfies(v, "<=1.0.0"))
}

test "satisfies less than" {
  let v = unwrap_version(parse_version("1.0.0"))
  assert_true(satisfies(v, "<2.0.0"))
  assert_false(satisfies(v, "<1.0.0"))
}

test "satisfies equal" {
  let v = unwrap_version(parse_version("3.0.0"))
  assert_true(satisfies(v, "=3.0.0"))
  assert_false(satisfies(v, "=3.0.1"))
}
