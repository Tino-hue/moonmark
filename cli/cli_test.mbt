test "parse_args recognizes tree command" {
  let args = ["tree", "myPkg"]
  match parse_args(args) {
    Ok(opts) => {
      assert_true(opts.command == "tree")
      assert_true(opts.target_pkg == "myPkg")
      assert_true(opts.depth == 10)
    }
    Err(_) => abort("test failed")
  }
}

test "parse_args recognizes audit command with --json" {
  let args = ["audit", "--json"]
  match parse_args(args) {
    Ok(opts) => {
      assert_true(opts.command == "audit")
      assert_true(opts.format == "json")
    }
    Err(_) => abort("test failed")
  }
}

test "parse_args recognizes report command with --html and -o" {
  let args = ["report", "--html", "-o", "out.html"]
  match parse_args(args) {
    Ok(opts) => {
      assert_true(opts.command == "report")
      assert_true(opts.format == "html")
      match opts.output {
        Some(path) => assert_true(path == "out.html")
        None => abort("test failed")
      }
    }
    Err(_) => abort("test failed")
  }
}

test "parse_args parses --depth value" {
  let args = ["tree", "--depth", "3"]
  match parse_args(args) {
    Ok(opts) => assert_true(opts.depth == 3)
    Err(_) => abort("test failed")
  }
}

test "parse_args rejects unknown option" {
  let result = parse_args(["tree", "--unknown"])
  match result {
    Ok(_) => abort("test failed")
    Err(_) => ()
  }
}

test "parse_args rejects missing command" {
  let result : Result[CliOptions, String] = parse_args([])
  match result {
    Ok(_) => abort("test failed")
    Err(_) => ()
  }
}

test "help_text contains key sections" {
  let text = help_text()
  assert_true(text.contains("MoonBit Depsight"))
  assert_true(text.contains("tree"))
  assert_true(text.contains("audit"))
  assert_true(text.contains("report"))
  assert_true(text.contains("--help"))
}

test "tree_help_text contains depth option" {
  let text = tree_help_text()
  assert_true(text.contains("--depth"))
}

test "audit_help_text contains json option" {
  let text = audit_help_text()
  assert_true(text.contains("--json"))
}

test "report_help_text contains html option" {
  let text = report_help_text()
  assert_true(text.contains("--html"))
}
