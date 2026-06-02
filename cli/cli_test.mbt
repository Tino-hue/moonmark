test "audit without flags returns 0" {
  let code = @cli.run_cli_with_args(["audit"])
  assert_true(code == 0)
}

test "audit fail-on-score 101 returns 1" {
  let code = @cli.run_cli_with_args(["audit", "--fail-on-score", "101"])
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

test "parse_args dry-run flag" {
  let args = ["audit", "--dry-run", "--json"]
  match @cli.parse_args(args) {
    Ok(opts) => {
      assert_true(opts.command == "audit")
      assert_true(opts.dry_run == true)
      assert_true(opts.format == "json")
    }
    Err(msg) => fail("Should parse dry-run: " + msg)
  }
}

test "parse_args all flags including dry-run" {
  let args = [
    "report", "--html", "--dry-run", "--offline", "--workspace",
    "--fail-on-score", "75", "--fail-on-critical", "-o", "out.html",
  ]
  match @cli.parse_args(args) {
    Ok(opts) => {
      assert_true(opts.command == "report")
      assert_true(opts.format == "html")
      assert_true(opts.dry_run == true)
      assert_true(opts.offline == true)
      assert_true(opts.workspace == true)
      assert_true(opts.fail_on_score == Some(75))
      assert_true(opts.fail_on_critical == true)
      assert_true(opts.output == Some("out.html"))
    }
    Err(msg) => fail("Should parse all flags with dry-run: " + msg)
  }
}

test "dry-run audit returns 0" {
  let code = @cli.run_cli_with_args(["audit", "--dry-run"])
  assert_true(code == 0)
}

test "dry-run tree returns 0" {
  let code = @cli.run_cli_with_args(["tree", "--dry-run"])
  assert_true(code == 0)
}

test "parse_args verbose flag" {
  let args = ["audit", "--verbose"]
  match @cli.parse_args(args) {
    Ok(opts) => assert_true(opts.verbose == true)
    Err(msg) => fail("Should parse verbose: " + msg)
  }
}

test "verbose audit returns 0" {
  let code = @cli.run_cli_with_args(["audit", "--verbose"])
  assert_true(code == 0)
}

// ---------- P2: SARIF, baseline, severity_map ----------

test "parse_args sarif flag" {
  let args = ["audit", "--sarif"]
  match @cli.parse_args(args) {
    Ok(opts) => assert_true(opts.format == "sarif")
    Err(msg) => fail("Should parse sarif: " + msg)
  }
}

test "audit sarif format returns 0" {
  let code = @cli.run_cli_with_args(["audit", "--sarif"])
  assert_true(code == 0)
}

test "report sarif format returns 0" {
  let code = @cli.run_cli_with_args(["report", "--sarif"])
  assert_true(code == 0)
}

test "parse_args baseline auto" {
  let args = ["audit", "--baseline", "auto"]
  match @cli.parse_args(args) {
    Ok(opts) => assert_true(opts.baseline == Some("auto"))
    Err(msg) => fail("Should parse baseline auto: " + msg)
  }
}
