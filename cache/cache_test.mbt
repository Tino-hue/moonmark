///|
let test_cache_dir = "./test_cache_tmp"

///|
fn cleanup_test_cache(fs : @cache.FileSystem) -> Unit {
  match (fs.readdir)(test_cache_dir) {
    Some(files) => {
      for file in files {
        (fs.unlink)(join_path(test_cache_dir, file))
      }
      (fs.rmdir)(test_cache_dir)
    }
    None => ()
  }
}

///|
test "cache set and get" {
  let fs = @cache.FileSystem::node_js()
  cleanup_test_cache(fs)
  let cm = @cache.CacheManager::new(test_cache_dir, fs, ttl_ms=100000)
  cm.set("pkg@1.0.0", "hello world")
  let result = cm.get("pkg@1.0.0")
  match result {
    Some(v) => assert_true(v == "hello world")
    None => fail("expected Some")
  }
  cleanup_test_cache(fs)
}

///|
test "cache miss returns none" {
  let fs = @cache.FileSystem::node_js()
  cleanup_test_cache(fs)
  let cm = @cache.CacheManager::new(test_cache_dir, fs, ttl_ms=100000)
  let result = cm.get("nonexistent@1.0.0")
  match result {
    Some(_) => fail("expected None")
    None => ()
  }
  cleanup_test_cache(fs)
}

///|
test "cache clear removes all" {
  let fs = @cache.FileSystem::node_js()
  cleanup_test_cache(fs)
  let cm = @cache.CacheManager::new(test_cache_dir, fs, ttl_ms=100000)
  cm.set("pkg@1.0.0", "content1")
  cm.set("pkg@2.0.0", "content2")
  cm.clear()
  let r1 = cm.get("pkg@1.0.0")
  let r2 = cm.get("pkg@2.0.0")
  match r1 {
    Some(_) => fail("expected None after clear")
    None => ()
  }
  match r2 {
    Some(_) => fail("expected None after clear")
    None => ()
  }
  cleanup_test_cache(fs)
}

///|
test "cache purge does not remove valid entries" {
  let fs = @cache.FileSystem::node_js()
  cleanup_test_cache(fs)
  let cm = @cache.CacheManager::new(test_cache_dir, fs, ttl_ms=100000)
  cm.set("pkg@1.0.0", "content")
  cm.purge_expired()
  let result = cm.get("pkg@1.0.0")
  match result {
    Some(v) => assert_true(v == "content")
    None => fail("expected Some")
  }
  cleanup_test_cache(fs)
}
