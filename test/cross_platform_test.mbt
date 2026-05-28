/// Cross-Platform Compatibility Tests
///
/// 验证路径分隔符、换行符、编码在不同平台下行为一致。

// ========== 路径分隔符测试 ==========

test "default_cache_dir uses platform separator" {
  let dir = @cache.default_cache_dir()
  let sep = @cache.platform_path_sep()
  assert_true(dir.contains(".depsight"))
  assert_true(dir.contains("cache"))
  // Should not contain the WRONG separator
  if sep == "\\" {
    // Windows: should not contain unmixed "/" before .depsight
    assert_true(dir.contains("\\"))
  } else {
    // Unix: should use "/"
    assert_true(dir.contains("/"))
  }
}

test "platform home dir is non-empty" {
  let home = @cache.platform_home_dir()
  assert_true(home.length() > 0)
}

test "platform path sep is single char" {
  let sep = @cache.platform_path_sep()
  assert_true(sep == "\\" || sep == "/")
}

// ========== 换行符兼容性测试 ==========

test "parse_mod_json handles LF line endings" {
  let content = "{\n  \"name\": \"a\",\n  \"version\": \"1.0.0\"\n}"
  match @parse.parse_mod_json(content) {
    Ok(pkg) => {
      assert_true(pkg.name == "a")
      assert_true(pkg.version == "1.0.0")
    }
    Err(msg) => fail("Should parse LF: " + msg)
  }
}

test "parse_mod_json handles CRLF line endings" {
  let content = "{\r\n  \"name\": \"a\",\r\n  \"version\": \"1.0.0\"\r\n}"
  match @parse.parse_mod_json(content) {
    Ok(pkg) => {
      assert_true(pkg.name == "a")
      assert_true(pkg.version == "1.0.0")
    }
    Err(msg) => fail("Should parse CRLF: " + msg)
  }
}

// ========== 编码兼容性测试 ==========

test "parse_mod_json handles unicode package names" {
  let content =
    #|{
    #|  "name": "用户/项目",
    #|  "version": "1.0.0",
    #|  "description": "测试 UTF-8 支持"
    #|}
  match @parse.parse_mod_json(content) {
    Ok(pkg) => {
      assert_true(pkg.name == "用户/项目")
      assert_true(pkg.description == Some("测试 UTF-8 支持"))
    }
    Err(msg) => fail("Should parse unicode: " + msg)
  }
}

test "html report preserves unicode characters" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("测试包", "1.0.0", 0)
  let metas : Map[String, @analyze.NodeMeta] = {}
  let report = @analyze.run_analysis(graph, metas)
  let html = @analyze.render_html_report(report, graph, "测试包@1.0.0")
  assert_true(html.contains("测试包"))
}

// ========== 真实文件系统缓存测试 ==========

let test_cp_dir = "./test_crossplatform_cache"

test "cache set and get roundtrip on real fs" {
  let fs = @cache.FileSystem::node_js()
  let cache = @cache.CacheManager::new(test_cp_dir, fs, ttl_ms=3600000)
  cache.set("key1", "value1")
  match cache.get("key1") {
    Some(v) => assert_true(v == "value1")
    None => fail("Cache get should return value")
  }
  // cleanup
  cache.clear()
}

test "cache clear removes all entries on real fs" {
  let fs = @cache.FileSystem::node_js()
  let cache = @cache.CacheManager::new(test_cp_dir, fs, ttl_ms=3600000)
  cache.set("a", "1")
  cache.set("b", "2")
  cache.clear()
  match cache.get("a") {
    Some(_) => fail("Cleared entry should not exist")
    None => ()
  }
  match cache.get("b") {
    Some(_) => fail("Cleared entry should not exist")
    None => ()
  }
}

test "cache purge expired removes old entries on real fs" {
  let fs = @cache.FileSystem::node_js()
  let cache = @cache.CacheManager::new(test_cp_dir, fs, ttl_ms=10)
  cache.set("old", "data")
  // Small sleep to exceed 10ms TTL
  sleep_ms(50)
  cache.purge_expired()
  match cache.get("old") {
    Some(_) => fail("Expired entry should be removed")
    None => ()
  }
}

extern "js" fn sleep_ms(ms : Int) -> Unit =
  #| (ms) => {
  #|   const start = Date.now();
  #|   while (Date.now() - start < ms) {}
  #| }