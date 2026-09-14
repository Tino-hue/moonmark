///|
/// 版本号同步测试：确保单一来源（analyze/version.mbt 的 depsight_version）
/// 与根目录 /moon.mod 的 version 字段保持一致。
/// 发布新版本时若只改 depsight_version 而漏改 moon.mod，此测试会立即失败，
/// 避免出现 CLI 报告版本与包元数据版本不一致的发布事故。

///|
test "moon.mod version matches depsight_version" {
  let fs = @cache.FileSystem::node_js()
  let content = match (fs.read_file)("moon.mod") {
    Some(c) => c
    None => fail("moon.mod not found at project root")
  }
  let m = match @parse.parse_mod_toml(content) {
    Ok(m) => m
    Err(e) => fail("failed to parse moon.mod: " + e)
  }
  assert_true(m.version == @analyze.depsight_version)
}
