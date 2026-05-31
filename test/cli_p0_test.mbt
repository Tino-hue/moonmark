test "parse_args severity option" {
  let result = @cli.parse_args(["audit", "--severity", "warning"])
  assert_true(result is Ok(_))
  let opts = match result {
    Ok(o) => o
    Err(_) => @cli.CliOptions::new()
  }
  assert_true(opts.command == "audit")
  assert_true(opts.severity == Some("warning"))
}

test "parse_config_toml basic" {
  let toml =
    #|format = "json"
    #|fail_on_critical = "true"
    #|fail_on_score = "80"
    #|severity = "warning"

  let map = @parse.parse_config_toml(toml)
  assert_true(map.get("format") == Some("json"))
  assert_true(map.get("fail_on_critical") == Some("true"))
  assert_true(map.get("fail_on_score") == Some("80"))
  assert_true(map.get("severity") == Some("warning"))
}

test "severity_rank ordering" {
  assert_true(@report.severity_rank("Critical") == 3)
  assert_true(@report.severity_rank("Warning") == 2)
  assert_true(@report.severity_rank("Info") == 1)
}

test "run_cli_with_args audit fail-on-score returns exit code 1" {
  let code = @cli.run_cli_with_args(["audit", "--fail-on-score", "100"])
  assert_true(code == 1)
}

test "run_cli_with_args audit without fail returns exit code 0" {
  let code = @cli.run_cli_with_args(["audit"])
  assert_true(code == 0)
}

test "run_cli_with_args report fail-on-critical returns exit code" {
  // mock graph 不产生 critical，所以应该是 0；但如果产生 critical 应该是 1
  let code = @cli.run_cli_with_args(["report", "--fail-on-critical"])
  assert_true(code == 0)
}
