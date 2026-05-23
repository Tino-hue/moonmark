/// 快速构造 Module（仅填充 build 所需的字段）
fn make_module(name : String, version : String, deps : Map[String, String]) -> @parse.Module {
  { name, version, readme: None, repository: None, license: None, keywords: [], description: None, source: None, deps }
}

/// 构造 mock fetch 闭包
fn make_mock_fetch(registry : Map[String, @parse.Module]) -> (String, String) -> Result[@parse.Module, String] {
  fn fetch(name : String, version : String) -> Result[@parse.Module, String] {
    let id = name + "@" + version
    match registry.get(id) {
      Some(m) => Ok(m)
      None => Err("Package not found: " + id)
    }
  }
  fetch
}

test "build simple dependency tree" {
  let a = make_module("a", "1.0.0", { "c": "1.0.0" })
  let b = make_module("b", "1.0.0", {})
  let c = make_module("c", "1.0.0", {})
  let root = make_module("root", "1.0.0", { "a": "1.0.0", "b": "1.0.0" })

  let registry = {
    "root@1.0.0": root,
    "a@1.0.0": a,
    "b@1.0.0": b,
    "c@1.0.0": c,
  }

  let fetch = make_mock_fetch(registry)
  let builder = @graph.GraphBuilder::new()
  let graph = match builder.build("root", "1.0.0", fetch) {
    Ok(g) => g
    Err(msg) => fail!("Build failed: " + msg)
  }

  assert_eq!(graph.size(), 4)
  assert_eq!(graph.get_children("root", "1.0.0").length(), 2)
  assert_eq!(graph.get_children("a", "1.0.0").length(), 1)
  assert_eq!(graph.get_children("b", "1.0.0").length(), 0)
  assert_eq!(graph.get_children("c", "1.0.0").length(), 0)
}

test "build with version conflict" {
  // 同一包的两个不同版本应作为独立节点存在
  let a1 = make_module("a", "1.0.0", { "b": "1.0.0" })
  let a2 = make_module("a", "2.0.0", { "b": "2.0.0" })
  let b1 = make_module("b", "1.0.0", {})
  let b2 = make_module("b", "2.0.0", {})
  let root = make_module("root", "1.0.0", { "a": "1.0.0", "x": "1.0.0" })
  let x = make_module("x", "1.0.0", { "a": "2.0.0" })

  let registry = {
    "root@1.0.0": root,
    "a@1.0.0": a1,
    "a@2.0.0": a2,
    "b@1.0.0": b1,
    "b@2.0.0": b2,
    "x@1.0.0": x,
  }

  let fetch = make_mock_fetch(registry)
  let builder = @graph.GraphBuilder::new()
  let graph = match builder.build("root", "1.0.0", fetch) {
    Ok(g) => g
    Err(msg) => fail!("Build failed: " + msg)
  }

  assert_eq!(graph.size(), 6)
  assert_true!(graph.get_node("a", "1.0.0") is Some(_))
  assert_true!(graph.get_node("a", "2.0.0") is Some(_))
  assert_true!(graph.get_node("b", "1.0.0") is Some(_))
  assert_true!(graph.get_node("b", "2.0.0") is Some(_))
}

test "build respects max depth" {
  let a = make_module("a", "1.0.0", { "b": "1.0.0" })
  let b = make_module("b", "1.0.0", { "c": "1.0.0" })
  let c = make_module("c", "1.0.0", { "d": "1.0.0" })
  let d = make_module("d", "1.0.0", {})
  let root = make_module("root", "1.0.0", { "a": "1.0.0" })

  let registry = {
    "root@1.0.0": root,
    "a@1.0.0": a,
    "b@1.0.0": b,
    "c@1.0.0": c,
    "d@1.0.0": d,
  }

  let fetch = make_mock_fetch(registry)
  let builder = @graph.GraphBuilder::new_with_max_depth(2)
  let graph = match builder.build("root", "1.0.0", fetch) {
    Ok(g) => g
    Err(msg) => fail!("Build failed: " + msg)
  }

  // max_depth=2 允许 root(0) -> a(1) -> b(2)
  // b -> c(3) 超出深度，不会递归
  assert_eq!(graph.size(), 3)
  assert_true!(graph.get_node("c", "1.0.0") is None)
}

test "cache prevents redundant fetches" {
  let a = make_module("a", "1.0.0", { "c": "1.0.0" })
  let b = make_module("b", "1.0.0", { "c": "1.0.0" })
  let c = make_module("c", "1.0.0", {})
  let root = make_module("root", "1.0.0", { "a": "1.0.0", "b": "1.0.0" })

  let registry = {
    "root@1.0.0": root,
    "a@1.0.0": a,
    "b@1.0.0": b,
    "c@1.0.0": c,
  }

  let fetch = make_mock_fetch(registry)
  let builder = @graph.GraphBuilder::new()
  let graph = match builder.build("root", "1.0.0", fetch) {
    Ok(g) => g
    Err(msg) => fail!("Build failed: " + msg)
  }

  // c 被 a 和 b 同时依赖，但图中只有一个 c 节点，且有两个父节点
  assert_eq!(graph.size(), 4)
  assert_eq!(graph.get_parents("c", "1.0.0").length(), 2)
}
