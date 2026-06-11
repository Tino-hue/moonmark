///|
test "parse simple moon.mod.json" {
  let content =
    #|{
    #|  "name": "test/simple",
    #|  "version": "0.1.0"
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(pkg) => {
      inspect(pkg.name, content="test/simple")
      inspect(pkg.version, content="0.1.0")
      assert_true(pkg.deps.is_empty())
      assert_true(pkg.keywords.is_empty())
    }
    Err(msg) => fail("Should parse simple mod: " + msg)
  }
}

///|
test "parse full moon.mod.json" {
  let content =
    #|{
    #|  "name": "LittleFish/depsight",
    #|  "version": "0.1.0",
    #|  "readme": "README.md",
    #|  "license": "Apache-2.0",
    #|  "keywords": ["depsight", "dependency"],
    #|  "description": "A tool",
    #|  "source": "src",
    #|  "deps": {
    #|    "moonbitlang/core": "",
    #|    "user/helper": "0.2.0"
    #|  }
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(pkg) => {
      inspect(pkg.name, content="LittleFish/depsight")
      inspect(pkg.version, content="0.1.0")
      assert_true(pkg.readme == Some("README.md"))
      assert_true(pkg.license == Some("Apache-2.0"))
      assert_true(pkg.description == Some("A tool"))
      assert_true(pkg.source == Some("src"))
      inspect(pkg.keywords.length(), content="2")
      inspect(pkg.deps.length(), content="2")
      match pkg.deps.get("user/helper") {
        Some("0.2.0") => ()
        _ => fail("Expected Some(\"0.2.0\")")
      }
    }
    Err(msg) => fail("Should parse full mod: " + msg)
  }
}

///|
test "parse invalid name type" {
  let content =
    #|{
    #|  "name": 123,
    #|  "version": "0.1.0"
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(_) => fail("Should fail on invalid name type")
    Err(_) => ()
  }
}

///|
test "parse missing name" {
  let content =
    #|{
    #|  "version": "0.1.0"
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(_) => fail("Should fail on missing name")
    Err(_) => ()
  }
}

///|
test "parse missing version" {
  let content =
    #|{
    #|  "name": "test/pkg"
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(_) => fail("Should fail on missing version")
    Err(_) => ()
  }
}

///|
test "parse empty name" {
  let content =
    #|{
    #|  "name": "",
    #|  "version": "0.1.0"
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(pkg) => assert_true(pkg.name == "")
    Err(_) => ()
  }
}

///|
test "parse malformed json" {
  let content = "{ \"name\": \"test\", \"version\": "
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(_) => fail("Should fail on malformed json")
    Err(_) => ()
  }
}

///|
test "parse root is array" {
  let content = "[{\"name\": \"test\"}]"
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(_) => fail("Should fail when root is array")
    Err(_) => ()
  }
}

///|
test "parse deps with non-string values" {
  let content =
    #|{
    #|  "name": "test/pkg",
    #|  "version": "0.1.0",
    #|  "deps": {
    #|    "a": "1.0.0",
    #|    "b": 123
    #|  }
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(pkg) => {
      assert_true(pkg.deps.length() == 1)
      assert_true(pkg.deps.get("a") == Some("1.0.0"))
    }
    Err(msg) => fail("Should parse with skipped non-string deps: " + msg)
  }
}

///|
test "parse keywords with non-string items" {
  let content =
    #|{
    #|  "name": "test/pkg",
    #|  "version": "0.1.0",
    #|  "keywords": ["dep", 123, "tool"]
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(pkg) => inspect(pkg.keywords.length(), content="2")
    Err(msg) => fail("Should parse with skipped non-string keywords: " + msg)
  }
}

///|
test "parse empty deps" {
  let content =
    #|{
    #|  "name": "test/pkg",
    #|  "version": "0.1.0",
    #|  "deps": {}
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(pkg) => assert_true(pkg.deps.is_empty())
    Err(msg) => fail("Should parse empty deps: " + msg)
  }
}

///|
test "parse no optional fields" {
  let content =
    #|{
    #|  "name": "test/pkg",
    #|  "version": "0.1.0"
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(pkg) => {
      assert_true(pkg.readme is None)
      assert_true(pkg.license is None)
      assert_true(pkg.description is None)
      assert_true(pkg.source is None)
      assert_true(pkg.keywords.is_empty())
      assert_true(pkg.deps.is_empty())
    }
    Err(msg) => fail("Should parse minimal mod: " + msg)
  }
}

// ---------- parse_config_toml with sections (P2) ----------

///|
test "parse_config_toml simple keys" {
  let content =
    #|fail_on_score = 80
    #|format = "json"
  let map = @parse.parse_config_toml(content)
  assert_true(map.get("fail_on_score") == Some("80"))
  assert_true(map.get("format") == Some("json"))
}

///|
test "parse_config_toml with section" {
  let content =
    #|format = "terminal"
    #|[severity]
    #|LICENSE-001 = "warning"
    #|DEPRECATED-001 = "info"
  let map = @parse.parse_config_toml(content)
  assert_true(map.get("format") == Some("terminal"))
  assert_true(map.get("severity.LICENSE-001") == Some("warning"))
  assert_true(map.get("severity.DEPRECATED-001") == Some("info"))
}

///|
test "parse_config_toml empty" {
  let map = @parse.parse_config_toml("")
  assert_true(map.is_empty())
}
