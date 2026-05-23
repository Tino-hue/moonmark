test "parse simple moon.mod.json" {
  let content =
    #|{
    #|  "name": "test/simple",
    #|  "version": "0.1.0"
    #|}
  let result = @parse.parse_mod_json(content)
  match result {
    Ok(module) => {
      assert_eq!(module.name, "test/simple")
      assert_eq!(module.version, "0.1.0")
      assert_true!(module.deps.is_empty())
      assert_true!(module.keywords.is_empty())
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
    Ok(module) => {
      assert_eq!(module.name, "LittleFish/depsight")
      assert_eq!(module.version, "0.1.0")
      assert_eq!(module.readme, Some("README.md"))
      assert_eq!(module.license, Some("Apache-2.0"))
      assert_eq!(module.description, Some("A tool"))
      assert_eq!(module.source, Some("src"))
      assert_eq!(module.keywords.length(), 2)
      assert_eq!(module.deps.size(), 2)
      assert_eq!(module.deps.get("user/helper"), Some("0.2.0"))
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
