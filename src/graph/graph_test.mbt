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
