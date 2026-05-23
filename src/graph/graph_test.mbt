test "empty graph" {
  let graph = @graph.DependencyGraph::new()
  assert_eq(graph.size(), 0)
  assert_eq(graph.get_all_node_ids().length(), 0)
}

test "add nodes and edges" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_node("C", "1.0.0", 1)

  assert_eq(graph.size(), 3)

  graph.add_edge("A", "1.0.0", "B", "1.0.0")
  graph.add_edge("A", "1.0.0", "C", "1.0.0")

  let a_children = graph.get_children("A", "1.0.0")
  assert_eq(a_children.length(), 2)

  let b_parents = graph.get_parents("B", "1.0.0")
  assert_eq(b_parents.length(), 1)
  assert_eq(b_parents[0], "A@1.0.0")
}

test "topological sort on DAG" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_node("C", "1.0.0", 2)
  graph.add_node("D", "1.0.0", 2)

  graph.add_edge("A", "1.0.0", "B", "1.0.0")
  graph.add_edge("B", "1.0.0", "C", "1.0.0")
  graph.add_edge("B", "1.0.0", "D", "1.0.0")

  let sorted = graph.topological_sort()
  match sorted {
    Ok(ids) => {
      assert_eq(ids.length(), 4)
      assert_true(appears_before(ids, "A@1.0.0", "B@1.0.0"))
      assert_true(appears_before(ids, "B@1.0.0", "C@1.0.0"))
      assert_true(appears_before(ids, "B@1.0.0", "D@1.0.0"))
    }
    Err(msg) => fail("Should not have cycle: " + msg)
  }
}

test "topological sort detects cycle" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_node("C", "1.0.0", 2)

  graph.add_edge("A", "1.0.0", "B", "1.0.0")
  graph.add_edge("B", "1.0.0", "C", "1.0.0")
  graph.add_edge("C", "1.0.0", "A", "1.0.0")

  let sorted = graph.topological_sort()
  match sorted {
    Ok(_) => fail("Should detect cycle")
    Err(_) => ()
  }
}

/// 辅助：验证 before 在数组中出现在 after 之前（递归实现，无 mut）
fn appears_before(arr : Array[String], before : String, after : String) -> Bool {
  appears_before_loop(arr, before, after, 0, false)
}

fn appears_before_loop(arr : Array[String], before : String, after : String, idx : Int, found : Bool) -> Bool {
  if idx >= arr.length() { return false }
  let id = arr[idx]
  if id == after { return found }
  let new_found = if id == before { true } else { found }
  appears_before_loop(arr, before, after, idx + 1, new_found)
}

test "check_cycles returns empty for acyclic graph" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_edge("A", "1.0.0", "B", "1.0.0")

  let diags = graph.check_cycles()
  assert_eq(diags.length(), 0)
}

test "check_cycles returns critical diagnostic for cycle" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_node("C", "1.0.0", 2)

  graph.add_edge("A", "1.0.0", "B", "1.0.0")
  graph.add_edge("B", "1.0.0", "C", "1.0.0")
  graph.add_edge("C", "1.0.0", "A", "1.0.0")

  let diags = graph.check_cycles()
  assert_eq(diags.length(), 1)

  let d = diags[0]
  assert_eq(d.level, @report.LEVEL_CRITICAL)
  assert_eq(d.code, "CYCLE-001")
  assert_eq(d.message, "Circular dependency detected")
  assert_true(d.path.length() > 0)
  assert_eq(d.suggestions.length(), 1)
  assert_eq(d.suggestions[0], "Review the dependency chain and remove one of the edges to break the cycle.")
}

test "performance: find_cycle on 150 node linear chain" {
  let graph = @graph.DependencyGraph::new()
  let n = 150

  let mut idx = 0
  while idx < n {
    graph.add_node("p" + idx.to_string(), "1.0.0", idx)
    idx = idx + 1
  }

  let mut e = 0
  while e < n - 1 {
    graph.add_edge("p" + e.to_string(), "1.0.0", "p" + (e + 1).to_string(), "1.0.0")
    e = e + 1
  }

  let cycle = graph.find_cycle()
  assert_eq(cycle.length(), 0)
}

test "performance: topological_sort on 150 node DAG" {
  let graph = @graph.DependencyGraph::new()
  let n = 150

  let mut idx = 0
  while idx < n {
    graph.add_node("p" + idx.to_string(), "1.0.0", idx)
    idx = idx + 1
  }

  let mut e = 0
  while e < n - 1 {
    graph.add_edge("p" + e.to_string(), "1.0.0", "p" + (e + 1).to_string(), "1.0.0")
    e = e + 1
  }

  match graph.topological_sort() {
    Ok(sorted) => assert_eq(sorted.length(), n)
    Err(msg) => fail("Should sort DAG: " + msg)
  }
}

test "real package graph: moonbitlang/x has no cycle" {
  let x = @parse.Module::new("moonbitlang/x", "0.4.44", {})
  let chalk = @parse.Module::new("Lampese/moonbit-chalk", "0.4.0", {})
  let parser = @parse.Module::new("peter-jerry-ye/parser-combinator", "0.9.1", {})

  let registry = {
    "moonbitlang/x@0.4.44": x,
    "Lampese/moonbit-chalk@0.4.0": chalk,
    "peter-jerry-ye/parser-combinator@0.9.1": parser,
  }

  let fetch = make_mock_fetch(registry)
  let builder = @graph.GraphBuilder::new()
  let graph = match builder.build("moonbitlang/x", "0.4.44", fetch) {
    Ok(g) => g
    Err(msg) => fail("Build failed: " + msg)
  }

  // 真实包目前大多没有外部 deps，所以图只有 1 个节点
  assert_eq(graph.size(), 1)

  let diags = graph.check_cycles()
  assert_eq(diags.length(), 0)
}

test "real package graph: inject artificial cycle on real data" {
  let x = @parse.Module::new("moonbitlang/x", "0.4.44", { "Lampese/moonbit-chalk": "0.4.0" })
  let chalk = @parse.Module::new("Lampese/moonbit-chalk", "0.4.0", { "moonbitlang/x": "0.4.44" })

  let registry = {
    "moonbitlang/x@0.4.44": x,
    "Lampese/moonbit-chalk@0.4.0": chalk,
  }

  let fetch = make_mock_fetch(registry)
  let builder = @graph.GraphBuilder::new()
  let graph = match builder.build("moonbitlang/x", "0.4.44", fetch) {
    Ok(g) => g
    Err(msg) => fail("Build failed: " + msg)
  }

  assert_eq(graph.size(), 2)

  let diags = graph.check_cycles()
  assert_eq(diags.length(), 1)
  assert_eq(diags[0].code, "CYCLE-001")
}

test "find_cycle on acyclic graph" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_node("C", "1.0.0", 2)

  graph.add_edge("A", "1.0.0", "B", "1.0.0")
  graph.add_edge("B", "1.0.0", "C", "1.0.0")

  let cycle = graph.find_cycle()
  assert_eq(cycle.length(), 0)
}

test "find_cycle detects three node cycle" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_node("C", "1.0.0", 2)

  graph.add_edge("A", "1.0.0", "B", "1.0.0")
  graph.add_edge("B", "1.0.0", "C", "1.0.0")
  graph.add_edge("C", "1.0.0", "A", "1.0.0")

  let cycle = graph.find_cycle()
  assert_true(cycle.length() > 0)
  assert_true(array_contains(cycle, "A@1.0.0"))
  assert_true(array_contains(cycle, "B@1.0.0"))
  assert_true(array_contains(cycle, "C@1.0.0"))
}
