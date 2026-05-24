fn find_prop_by_node(
  props : Array[DeprecatedPropagation],
  node_id : String
) -> DeprecatedPropagation? {
  for p in props {
    if p.node_id == node_id { return Some(p) }
  }
  None
}

test "three-level propagation" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_node("C", "1.0.0", 2)
  graph.add_edge("B", "1.0.0", "A", "1.0.0")
  graph.add_edge("C", "1.0.0", "B", "1.0.0")

  let deprecated_map : Map[String, Array[DeprecatedApi]] = {
    "A@1.0.0": [{ name: "old_fn", since: Some("0.1.0"), message: None }],
  }

  let props = find_deprecated_propagation(graph, deprecated_map)
  assert_eq(props.length(), 2)

  let b_prop = match find_prop_by_node(props, "B@1.0.0") {
    Some(p) => p
    None => panic()
  }
  assert_eq(b_prop.level, "direct")
  assert_eq(b_prop.api_name, "old_fn")
  assert_eq(b_prop.source_node_id, "A@1.0.0")

  let c_prop = match find_prop_by_node(props, "C@1.0.0") {
    Some(p) => p
    None => panic()
  }
  assert_eq(c_prop.level, "indirect")
  assert_eq(c_prop.api_name, "old_fn")
}

test "direct and indirect mixed" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_node("C", "1.0.0", 1)
  graph.add_node("D", "1.0.0", 2)
  graph.add_edge("B", "1.0.0", "A", "1.0.0")
  graph.add_edge("C", "1.0.0", "A", "1.0.0")
  graph.add_edge("D", "1.0.0", "B", "1.0.0")

  let deprecated_map : Map[String, Array[DeprecatedApi]] = {
    "A@1.0.0": [{ name: "old_fn", since: None, message: None }],
  }

  let props = find_deprecated_propagation(graph, deprecated_map)
  assert_eq(props.length(), 3)

  let b = find_prop_by_node(props, "B@1.0.0").unwrap()
  assert_eq(b.level, "direct")

  let c = find_prop_by_node(props, "C@1.0.0").unwrap()
  assert_eq(c.level, "direct")

  let d = find_prop_by_node(props, "D@1.0.0").unwrap()
  assert_eq(d.level, "indirect")
}

test "no deprecated nodes" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_edge("B", "1.0.0", "A", "1.0.0")

  let deprecated_map : Map[String, Array[DeprecatedApi]] = {}
  let props = find_deprecated_propagation(graph, deprecated_map)
  assert_eq(props.length(), 0)
}

test "multiple deprecated apis" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_edge("B", "1.0.0", "A", "1.0.0")

  let deprecated_map : Map[String, Array[DeprecatedApi]] = {
    "A@1.0.0": [
      { name: "old_fn", since: None, message: None },
      { name: "old_struct", since: None, message: None },
    ],
  }

  let props = find_deprecated_propagation(graph, deprecated_map)
  assert_eq(props.length(), 2)
}

test "self deprecated not included" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)

  let deprecated_map : Map[String, Array[DeprecatedApi]] = {
    "A@1.0.0": [{ name: "old_fn", since: None, message: None }],
  }

  let props = find_deprecated_propagation(graph, deprecated_map)
  assert_eq(props.length(), 0)
}
