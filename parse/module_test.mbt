test "parse simple moon.mod.json" {
  let content =
    #|{
    #|  "name": "test/simple",
    #|  "version": "0.1.0"
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(pkg) => {
      inspect!(pkg.name, content="test/simple")
      inspect!(pkg.version, content="0.1.0")
      assert_true(pkg.deps.is_empty())
      assert_true(pkg.keywords.is_empty())
    }
    Err(msg) => fail("Should parse simple mod: " + msg)
  }
}

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
      inspect!(pkg.name, content="LittleFish/depsight")
      inspect!(pkg.version, content="0.1.0")
      inspect!(pkg.readme, content="Some(\"README.md\")")
      inspect!(pkg.license, content="Some(\"Apache-2.0\")")
      inspect!(pkg.description, content="Some(\"A tool\")")
      inspect!(pkg.source, content="Some(\"src\")")
      inspect!(pkg.keywords.length(), content="2")
      inspect!(pkg.deps.length(), content="2")
      match pkg.deps.get("user/helper") {
        Some("0.2.0") => ()
        _ => fail("Expected Some(\"0.2.0\")")
      }
    }
    Err(msg) => fail("Should parse full mod: " + msg)
  }
}

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
