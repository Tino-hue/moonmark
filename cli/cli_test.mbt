test "parse_args recognizes tree command" {
  let args = ["tree", "myPkg"]
  match parse_args(args) {
    Ok(opts) => {
      assert_eq!(opts.command, "tree")
      assert_eq!(opts.target_pkg, "myPkg")
      assert_eq!(opts.depth, 10)
    }
    Err(_) => panic("should parse tree command")
  }
}

test "parse_args recognizes audit command with --json" {
  let args = ["audit", "--json"]
  match parse_args(args) {
    Ok(opts) => {
      assert_eq!(opts.command, "audit")
      assert_eq!(opts.format, "json")
    }
    Err(_) => panic("should parse audit command")
  }
}

test "parse_args recognizes report command with --html and -o" {
  let args = ["report", "--html", "-o", "out.html"]
  match parse_args(args) {
    Ok(opts) => {
      assert_eq!(opts.command, "report")
      assert_eq!(opts.format, "html")
      match opts.output {
        Some(path) => assert_eq!(path, "out.html")
        None => panic("output should be Some")
      }
    }
    Err(_) => panic("should parse report command")
  }
}

test "parse_args parses --depth value" {
  let args = ["tree", "--depth", "3"]
  match parse_args(args) {
    Ok(opts) => assert_eq!(opts.depth, 3)
    Err(_) => panic("should parse depth")
  }
}

test "parse_args rejects unknown option" {
  let result = parse_args(["tree", "--unknown"])
  match result {
    Ok(_) => panic("should reject unknown option")
    Err(_) => ()
  }
}

test "parse_args rejects missing command" {
  let result = parse_args([])
  match result {
    Ok(_) => panic("should reject missing command")
    Err(_) => ()
  }
}

test "help_text contains key sections" {
  let text = help_text()
  assert_eq!(text.contains("MoonBit Depsight"), true)
  assert_eq!(text.contains("tree"), true)
  assert_eq!(text.contains("audit"), true)
  assert_eq!(text.contains("report"), true)
  assert_eq!(text.contains("--help"), true)
}

test "tree_help_text contains depth option" {
  let text = tree_help_text()
  assert_eq!(text.contains("--depth"), true)
}

test "audit_help_text contains json option" {
  let text = audit_help_text()
  assert_eq!(text.contains("--json"), true)
}

test "report_help_text contains html option" {
  let text = report_help_text()
  assert_eq!(text.contains("--html"), true)
}
