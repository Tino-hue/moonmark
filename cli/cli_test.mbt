test "audit without flags returns 0" {
  let code = @cli.run_cli_with_args(["audit"])
  assert_true(code == 0)
}

test "audit fail-on-score 100 returns 1" {
  let code = @cli.run_cli_with_args(["audit", "--fail-on-score", "100"])
  assert_true(code == 1)
}

test "audit fail-on-score 0 returns 0" {
  let code = @cli.run_cli_with_args(["audit", "--fail-on-score", "0"])
  assert_true(code == 0)
}

test "audit fail-on-critical returns 0 (no critical in mock)" {
  let code = @cli.run_cli_with_args(["audit", "--fail-on-critical"])
  assert_true(code == 0)
}

test "tree returns 0" {
  let code = @cli.run_cli_with_args(["tree", "root"])
  assert_true(code == 0)
}

test "report returns 0" {
  let code = @cli.run_cli_with_args(["report"])
  assert_true(code == 0)
}

test "invalid args returns 1" {
  let code = @cli.run_cli_with_args(["audit", "--unknown-flag"])
  assert_true(code == 1)
}
