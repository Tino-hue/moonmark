///|
/// End-to-End Integration Tests
///
/// 验证完整工作流：moon.mod.json → 依赖图 → 审计报告 → 多种格式输出

// ========== 完整 Pipeline 测试 ==========

test "e2e minimal moon.mod.json pipeline" {
  let content =
    #|{
    #|  "name": "my/project",
    #|  "version": "1.0.0"
    #|}
  let mod_ = match @parse.parse_mod_json(content) {
    Ok(m) => m
    Err(msg) => fail("Parse failed: " + msg)
  }
  assert_true(mod_.name == "my/project")
  assert_true(mod_.version == "1.0.0")

  // Build graph with mock fetch (no deps, so fetch never called for children)
  let builder = @graph.GraphBuilder::new_with_max_depth(3)
  let graph = match
    builder.build(mod_.name, mod_.version, fn(_name, _ver) {
      // In a real scenario this would fetch from network or cache.
      // For root-only project, we just return the root module itself.
      Ok(mod_)
    }) {
    Ok(g) => g
    Err(msg) => fail("Graph build failed: " + msg)
  }
  assert_true(graph.size() == 1)

  // Run analysis（没有体积元数据的占位场景——F02 后 transitive_size=None）
  //   分数构成：freshness=100(×25%) + compliance=80(×20%) + depden=100(×25%) + size=80(×20%) + activity=80(×10%) = 90
  //   之前错误占位：Some(self_size=0) 被当作 <10KB → size=100 → 94（误高 4 分）
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let report = @analyze.run_analysis(graph, metas)
  assert_true(report.node_count == 1)
  assert_true(report.overall_score == 90)

  // Verify terminal report
  let terminal = @analyze.render_terminal_report(
    report, graph, "my/project@1.0.0",
  )
  assert_true(terminal.contains("MoonBit Depsight"))
  assert_true(terminal.contains("Nodes: 1"))

  // Verify JSON report
  let json = @analyze.render_audit_json(report)
  assert_true(json.contains("\"overall_score\":90"))
  assert_true(json.contains("\"node_count\":1"))

  // Verify HTML report
  let html = @analyze.render_html_report(report, graph, "my/project@1.0.0")
  assert_true(html.contains("<!DOCTYPE html>"))
  assert_true(html.contains("MoonBit Depsight"))
}

///|
test "e2e multi-dep moon.mod.json pipeline" {
  let root =
    #|{
    #|  "name": "app/main",
    #|  "version": "1.0.0",
    #|  "license": "MIT",
    #|  "deps": {
    #|    "lib/core": "0.5.0",
    #|    "lib/util": "0.3.0"
    #|  }
    #|}
  let root_mod = match @parse.parse_mod_json(root) {
    Ok(m) => m
    Err(msg) => fail("Parse root failed: " + msg)
  }

  // Mock fetch registry
  let registry : Map[String, @parse.Module] = Map([])
  registry["lib/core@0.5.0"] = @parse.Module::new("lib/core", "0.5.0", Map([]))
  registry["lib/util@0.3.0"] = @parse.Module::new("lib/util", "0.3.0", {
    "lib/core": "0.5.0",
  })

  let builder = @graph.GraphBuilder::new_with_max_depth(3)
  let graph = match
    builder.build(root_mod.name, root_mod.version, fn(name, ver) {
      let key = name + "@" + ver
      match registry.get(key) {
        Some(m) => Ok(m)
        None =>
          if name == root_mod.name && ver == root_mod.version {
            Ok(root_mod)
          } else {
            Err("Not found: " + key)
          }
      }
    }) {
    Ok(g) => g
    Err(msg) => fail("Graph build failed: " + msg)
  }

  // app → core, util; util → core
  assert_true(graph.size() == 3)

  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let report = @analyze.run_analysis(graph, metas)
  assert_true(report.node_count == 3)

  let html = @analyze.render_html_report(report, graph, "app/main@1.0.0")
  assert_true(html.contains("app/main@1.0.0"))
  assert_true(html.contains("lib/core@0.5.0"))
  assert_true(html.contains("lib/util@0.3.0"))
}

///|
test "e2e moon.mod.json with all optional fields" {
  let content =
    #|{
    #|  "name": "full/pkg",
    #|  "version": "2.0.0",
    #|  "readme": "README.md",
    #|  "repository": "https://github.com/user/repo",
    #|  "license": "Apache-2.0",
    #|  "keywords": ["tool", "cli"],
    #|  "description": "A full package",
    #|  "source": "src",
    #|  "deps": {
    #|    "a/lib": "1.0.0"
    #|  }
    #|}
  let mod_ = match @parse.parse_mod_json(content) {
    Ok(m) => m
    Err(msg) => fail("Parse failed: " + msg)
  }
  assert_true(mod_.license == Some("Apache-2.0"))
  assert_true(mod_.repository == Some("https://github.com/user/repo"))
  assert_true(mod_.keywords.length() == 2)
  assert_true(mod_.deps.length() == 1)
}

// ========== 兼容性测试 ==========

///|
test "e2e legacy moon.mod.json without deps field" {
  let content =
    #|{
    #|  "name": "legacy/pkg",
    #|  "version": "0.1.0"
    #|}
  let mod_ = match @parse.parse_mod_json(content) {
    Ok(m) => m
    Err(msg) => fail("Parse legacy failed: " + msg)
  }
  assert_true(mod_.deps.is_empty())

  let builder = @graph.GraphBuilder::new_with_max_depth(3)
  let graph = match
    builder.build(mod_.name, mod_.version, fn(_n, _v) { Ok(mod_) }) {
    Ok(g) => g
    Err(msg) => fail("Build failed: " + msg)
  }
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let report = @analyze.run_analysis(graph, metas)
  let json = @analyze.render_audit_json(report)
  // F02 后：没有体积元数据 → transitive_size=None → size_reasonableness=80 → overall = 90
  // （之前占位 Some(0) 误计为 <10KB → 100 → 94）
  assert_true(json.contains("\"overall_score\":90"))
}

///|
test "e2e empty string version in deps" {
  let content =
    #|{
    #|  "name": "app",
    #|  "version": "1.0.0",
    #|  "deps": {
    #|    "moonbitlang/core": ""
    #|  }
    #|}
  let mod_ = match @parse.parse_mod_json(content) {
    Ok(m) => m
    Err(msg) => fail("Parse failed: " + msg)
  }
  assert_true(mod_.deps.get("moonbitlang/core") == Some(""))
}

// ========== 离线场景测试 ==========

///|
test "e2e offline mode with local cache fallback" {
  // Simulate offline: all deps resolved from local registry
  let registry : Map[String, @parse.Module] = Map([])
  registry["offline/root@1.0.0"] = @parse.Module::new("offline/root", "1.0.0", {
    "offline/a": "1.0.0",
  })
  registry["offline/a@1.0.0"] = @parse.Module::new(
    "offline/a",
    "1.0.0",
    Map([]),
  )

  let builder = @graph.GraphBuilder::new_with_max_depth(3)
  let graph = match
    builder.build("offline/root", "1.0.0", fn(name, ver) {
      match registry.get(name + "@" + ver) {
        Some(m) => Ok(m)
        None => Err("Offline: not cached")
      }
    }) {
    Ok(g) => g
    Err(msg) => fail("Offline build failed: " + msg)
  }

  assert_true(graph.size() == 2)
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let report = @analyze.run_analysis(graph, metas)
  let html = @analyze.render_html_report(report, graph, "offline/root@1.0.0")
  assert_true(html.contains("offline/root@1.0.0"))
  assert_true(html.contains("offline/a@1.0.0"))
}

// ========== 报告格式完整性测试 ==========

///|
test "e2e html report structure completeness" {
  let content =
    #|{
    #|  "name": "report/test",
    #|  "version": "1.0.0"
    #|}
  let mod_ = match @parse.parse_mod_json(content) {
    Ok(m) => m
    Err(msg) => fail("Parse failed: " + msg)
  }
  let builder = @graph.GraphBuilder::new_with_max_depth(3)
  let graph = match
    builder.build(mod_.name, mod_.version, fn(_n, _v) { Ok(mod_) }) {
    Ok(g) => g
    Err(msg) => fail("Build failed: " + msg)
  }
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let report = @analyze.run_analysis(graph, metas)
  let html = @analyze.render_html_report(report, graph, "report/test@1.0.0")

  // Structural checks
  assert_true(html.contains("<!DOCTYPE html>"))
  assert_true(html.contains("<html"))
  assert_true(html.contains("<head>"))
  assert_true(html.contains("<body>"))
  assert_true(html.contains("</html>"))
  assert_true(html.contains("Health Score"))
  assert_true(html.contains("score-good"))
}

///|
test "e2e json report schema validation" {
  let content =
    #|{
    #|  "name": "json/test",
    #|  "version": "1.0.0"
    #|}
  let mod_ = match @parse.parse_mod_json(content) {
    Ok(m) => m
    Err(msg) => fail("Parse failed: " + msg)
  }
  let builder = @graph.GraphBuilder::new_with_max_depth(3)
  let graph = match
    builder.build(mod_.name, mod_.version, fn(_n, _v) { Ok(mod_) }) {
    Ok(g) => g
    Err(msg) => fail("Build failed: " + msg)
  }
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let report = @analyze.run_analysis(graph, metas)
  let json = @analyze.render_audit_json(report)

  assert_true(json.contains("\"overall_score\":"))
  assert_true(json.contains("\"node_count\":"))
  assert_true(json.contains("\"diagnostics\":"))
  assert_true(json.contains("\"health_scores\":"))
  assert_true(json.contains("\"summary\":"))
}

// ========== 异常路径测试 ==========

///|
test "e2e malformed moon.mod.json fails gracefully" {
  let content = "{ invalid json }"
  match @parse.parse_mod_json(content) {
    Ok(_) => fail("Should fail on malformed JSON")
    Err(_) => ()
  }
}

///|
test "e2e fetch failure propagates error" {
  let builder = @graph.GraphBuilder::new_with_max_depth(3)
  match
    builder.build("missing", "1.0.0", fn(_n, _v) { Err("Network unreachable") }) {
    Ok(_) => fail("Should fail when fetch errors")
    Err(msg) => assert_true(msg.contains("Network unreachable"))
  }
}

///|
test "e2e cycle detection in pipeline" {
  let registry : Map[String, @parse.Module] = Map([])
  registry["cycle/a@1.0.0"] = @parse.Module::new("cycle/a", "1.0.0", {
    "cycle/b": "1.0.0",
  })
  registry["cycle/b@1.0.0"] = @parse.Module::new("cycle/b", "1.0.0", {
    "cycle/a": "1.0.0",
  })

  let builder = @graph.GraphBuilder::new_with_max_depth(5)
  let graph = match
    builder.build("cycle/a", "1.0.0", fn(name, ver) {
      match registry.get(name + "@" + ver) {
        Some(m) => Ok(m)
        None => Err("Not found")
      }
    }) {
    Ok(g) => g
    Err(msg) => fail("Build failed: " + msg)
  }

  // Builder caches nodes, so cycle is prevented by early return; graph has 2 nodes
  assert_true(graph.size() == 2)

  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let report = @analyze.run_analysis(graph, metas)
  // Cycle should be detected by analysis (edge exists even though recursive build stopped)
  let has_cycle_diag = report.diagnostics
    .iter()
    .any(fn(d) { d.code == "CYCLE-001" })
  assert_true(has_cycle_diag)
}
