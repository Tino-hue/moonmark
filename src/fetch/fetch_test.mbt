test "build_github_raw_url converts github url" {
  let url = @fetch.build_github_raw_url(
    "https://github.com/moonbitlang/x",
    "main",
    "moon.mod.json"
  )
  assert_eq(
    url,
    "https://raw.githubusercontent.com/moonbitlang/x/main/moon.mod.json"
  )
}

test "fetch_package_meta with mock success" {
  fn mock_get(url : String) -> Result[String, String] {
    Ok("{\"name\":\"test\",\"version\":\"1.0.0\"}")
  }

  let result = @fetch.fetch_package_meta(mock_get, "test", "1.0.0", "https://github.com/user/test")
  match result {
    Ok(content) => assert_eq(content, "{\"name\":\"test\",\"version\":\"1.0.0\"}")
    Err(msg) => fail("Should succeed: " + msg)
  }
}

test "fetch_package_meta falls back to master branch" {
  let mut call_count = 0
  fn mock_get(url : String) -> Result[String, String] {
    call_count = call_count + 1
    if url.contains("main") {
      Err("404")
    } else {
      Ok("{\"name\":\"test\",\"version\":\"1.0.0\"}")
    }
  }

  let result = @fetch.fetch_package_meta(mock_get, "test", "1.0.0", "https://github.com/user/test")
  match result {
    Ok(content) => {
      assert_eq(content, "{\"name\":\"test\",\"version\":\"1.0.0\"}")
      assert_eq(call_count, 2)
    }
    Err(msg) => fail("Should fallback: " + msg)
  }
}

test "fetch_package_meta returns error on both branches fail" {
  fn mock_get(url : String) -> Result[String, String] {
    Err("Network error")
  }

  let result = @fetch.fetch_package_meta(mock_get, "test", "1.0.0", "https://github.com/user/test")
  match result {
    Ok(_) => fail("Should fail")
    Err(msg) => assert_true(msg.contains("Failed to fetch"))
  }
}

test "Registry fetch known package" {
  let reg = @fetch.Registry::new()
  reg.add("moonbitlang/x", "https://github.com/moonbitlang/x")

  fn mock_get(url : String) -> Result[String, String] {
    Ok("{\"name\":\"moonbitlang/x\",\"version\":\"0.4.44\"}")
  }

  let result = reg.fetch(mock_get, "moonbitlang/x", "0.4.44")
  match result {
    Ok(content) => assert_eq(content, "{\"name\":\"moonbitlang/x\",\"version\":\"0.4.44\"}")
    Err(msg) => fail("Should succeed: " + msg)
  }
}

test "Registry fetch unknown package returns error" {
  let reg = @fetch.Registry::new()

  fn mock_get(url : String) -> Result[String, String] {
    Ok("")
  }

  let result = reg.fetch(mock_get, "unknown/pkg", "1.0.0")
  match result {
    Ok(_) => fail("Should fail")
    Err(msg) => assert_true(msg.contains("Unknown package"))
  }
}
