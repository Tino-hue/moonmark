///|
test "parse moonbitlang/core single-line moon.mod" {
  let toml =
    #|name = "moonbitlang/core" version = "0.1.0" readme = "README.md" repository = "https://github.com/moonbitlang/core" license = "Apache-2.0" keywords = [ "core", "standard library" ] warnings = "+test_unqualified_package"

  let result = @parse.parse_mod_toml(toml)
  assert_true(result is Ok(_))
  let mod = match result {
    Ok(m) => m
    Err(_) => @parse.Module::new("", "", Map([]))
  }
  assert_true(mod.name == "moonbitlang/core")
  assert_true(mod.version == "0.1.0")
  assert_true(mod.readme == Some("README.md"))
  assert_true(mod.repository == Some("https://github.com/moonbitlang/core"))
  assert_true(mod.license == Some("Apache-2.0"))
  assert_true(mod.keywords.length() == 2)
  assert_true(mod.keywords[0] == "core")
  assert_true(mod.keywords[1] == "standard library")
  assert_true(mod.description == None)
}

///|
test "parse moonbitlang/x single-line moon.mod" {
  let toml =
    #|name = "moonbitlang/x" version = "0.4.44" readme = "README.md" repository = "https://github.com/moonbitlang/x" license = "Apache-2.0" keywords = [ "experimental", "moonbitlang", "json", "time", "crypto" ] description = "experimental packages for moonbitlang/core"

  let result = @parse.parse_mod_toml(toml)
  assert_true(result is Ok(_))
  let mod = match result {
    Ok(m) => m
    Err(_) => @parse.Module::new("", "", Map([]))
  }
  assert_true(mod.name == "moonbitlang/x")
  assert_true(mod.version == "0.4.44")
  assert_true(
    mod.description == Some("experimental packages for moonbitlang/core"),
  )
  assert_true(mod.keywords.length() == 5)
  assert_true(mod.keywords[0] == "experimental")
  assert_true(mod.keywords[1] == "moonbitlang")
  assert_true(mod.keywords[2] == "json")
  assert_true(mod.keywords[3] == "time")
  assert_true(mod.keywords[4] == "crypto")
}

///|
test "parse moonbitlang/async multi-line moon.mod" {
  let toml =
    #|name = "moonbitlang/async"
    #|version = "0.19.1"
    #|readme = "README.md"
    #|repository = "https://github.com/moonbitlang/async"
    #|license = "Apache-2.0"
    #|keywords = [ ]
    #|description = "Asynchronous programming library for MoonBit"
    #|preferred_target = "native"
    #|
    #|options(
    #|  source: "src",
    #|  exclude: [ "test_directory", "test_keys" ],
    #|)

  let result = @parse.parse_mod_toml(toml)
  assert_true(result is Ok(_))
  let mod = match result {
    Ok(m) => m
    Err(_) => @parse.Module::new("", "", Map([]))
  }
  assert_true(mod.name == "moonbitlang/async")
  assert_true(mod.version == "0.19.1")
  assert_true(
    mod.description == Some("Asynchronous programming library for MoonBit"),
  )
  assert_true(mod.keywords.is_empty())
  assert_true(mod.license == Some("Apache-2.0"))
}
