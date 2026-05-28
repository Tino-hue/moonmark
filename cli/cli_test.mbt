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

test "audit json format returns 0" {
  let code = @cli.run_cli_with_args(["audit", "--json"])
  assert_true(code == 0)
}

test "report html format returns 0" {
  let code = @cli.run_cli_with_args(["report", "--html"])
  assert_true(code == 0)
}

test "tree with depth returns 0" {
  let code = @cli.run_cli_with_args(["tree", "root", "--depth", "2"])
  assert_true(code == 0)
}

test "help returns 0" {
  let code = @cli.run_cli_with_args(["--help"])
  assert_true(code == 0)
}

test "version returns 0" {
  let code = @cli.run_cli_with_args(["--version"])
  assert_true(code == 0)
}

// ========== parse_args 详细测试 ==========

test "parse_args audit with all flags" {
  let args = [
    "audit", "--json", "--fail-on-score", "80", "--fail-on-critical", "--offline",
    "--cache-dir", "/tmp/cache", "-o", "report.json",
  ]
  match @cli.parse_args(args) {
    Ok(opts) => {
      assert_true(opts.command == "audit")
      assert_true(opts.format == "json")
      assert_true(opts.fail_on_score == Some(80))
      assert_true(opts.fail_on_critical == true)
      assert_true(opts.offline == true)
      assert_true(opts.cache_dir == Some("/tmp/cache"))
      assert_true(opts.output == Some("report.json"))
    }
    Err(msg) => fail("Should parse all flags: " + msg)
  }
}

test "parse_args report html output" {
  let args = ["report", "--html", "-o", "report.html"]
  match @cli.parse_args(args) {
    Ok(opts) => {
      assert_true(opts.command == "report")
      assert_true(opts.format == "html")
      assert_true(opts.output == Some("report.html"))
    }
    Err(msg) => fail("Should parse report html: " + msg)
  }
}

test "parse_args tree depth" {
  let args = ["tree", "root", "--depth", "3"]
  match @cli.parse_args(args) {
    Ok(opts) => {
      assert_true(opts.command == "tree")
      assert_true(opts.target_pkg == "root")
      assert_true(opts.depth == 3)
    }
    Err(msg) => fail("Should parse tree depth: " + msg)
  }
}

test "parse_args flag order independence" {
  let args1 = ["audit", "--json", "--fail-on-score", "80"]
  let args2 = ["audit", "--fail-on-score", "80", "--json"]
  match (@cli.parse_args(args1), @cli.parse_args(args2)) {
    (Ok(o1), Ok(o2)) => {
      assert_true(o1.command == o2.command)
      assert_true(o1.format == o2.format)
      assert_true(o1.fail_on_score == o2.fail_on_score)
    }
    _ => fail("Flag order should not matter")
  }
}

test "parse_args unknown flag errors" {
  let args = ["audit", "--unknown-flag"]
  match @cli.parse_args(args) {
    Ok(_) => fail("Should error on unknown flag")
    Err(_) => ()
  }
}

test "parse_args no command errors" {
  let args = ["--json"]
  match @cli.parse_args(args) {
    Ok(_) => fail("Should error when no command")
    Err(_) => ()
  }
}

test "parse_args missing depth value errors" {
  let args = ["tree", "--depth"]
  match @cli.parse_args(args) {
    Ok(_) => fail("Should error on missing depth value")
    Err(_) => ()
  }
}

test "parse_args help without command" {
  let args = ["--help"]
  match @cli.parse_args(args) {
    Ok(opts) => assert_true(opts.help == true)
    Err(msg) => fail("Should parse help: " + msg)
  }
}
