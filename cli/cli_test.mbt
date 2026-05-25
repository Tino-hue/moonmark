test "parse_args recognizes tree command" {
  let args = ["tree", "myPkg"]
  match parse_args(args) {
    Ok(opts) => {
      inspect!(opts.command, content="tree")
      inspect!(opts.target_pkg, content="myPkg")
      inspect!(opts.depth.to_string(), content="10")
    }
    Err(_) => abort()
  }
}

test "parse_args recognizes audit command with --json" {
  let args = ["audit", "--json"]
  match parse_args(args) {
    Ok(opts) => {
      inspect!(opts.command, content="audit")
      inspect!(opts.format, content="json")
    }
    Err(_) => abort()
  }
}

test "parse_args recognizes report command with --html and -o" {
  let args = ["report", "--html", "-o", "out.html"]
  match parse_args(args) {
    Ok(opts) => {
      inspect!(opts.command, content="report")
      inspect!(opts.format, content="html")
      match opts.output {
        Some(path) => inspect!(path, content="out.html")
        None => abort()
      }
    }
    Err(_) => abort()
  }
}

test "parse_args parses --depth value" {
  let args = ["tree", "--depth", "3"]
  match parse_args(args) {
    Ok(opts) => inspect!(opts.depth.to_string(), content="3")
    Err(_) => abort()
  }
}

test "parse_args rejects unknown option" {
  let result = parse_args(["tree", "--unknown"])
  match result {
    Ok(_) => abort()
    Err(_) => ()
  }
}

test "parse_args rejects missing command" {
  let result : Result[CliOptions, String] = parse_args([])
  match result {
    Ok(_) => abort()
    Err(_) => ()
  }
}

test "help_text contains key sections" {
  let text = help_text()
  assert_eq(text.contains("MoonBit Depsight"), true)
  assert_eq(text.contains("tree"), true)
  assert_eq(text.contains("audit"), true)
  assert_eq(text.contains("report"), true)
  assert_eq(text.contains("--help"), true)
}

test "tree_help_text contains depth option" {
  let text = tree_help_text()
  assert_eq(text.contains("--depth"), true)
}

test "audit_help_text contains json option" {
  let text = audit_help_text()
  assert_eq(text.contains("--json"), true)
}

test "report_help_text contains html option" {
  let text = report_help_text()
  assert_eq(text.contains("--html"), true)
}
