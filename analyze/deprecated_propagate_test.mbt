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
    "A@1.0.0": [DeprecatedApi::new("old_fn", since=Some("0.1.0"))],
  }

  let props = find_deprecated_propagation(graph, deprecated_map)
  inspect!(props.length(), content="2")

  let b_prop = match find_prop_by_node(props, "B@1.0.0") {
    Some(p) => p
    None => panic()
  }
  inspect!(b_prop.level, content="direct")
  inspect!(b_prop.api_name, content="old_fn")
  inspect!(b_prop.source_node_id, content="A@1.0.0")

  let c_prop = match find_prop_by_node(props, "C@1.0.0") {
    Some(p) => p
    None => panic()
  }
  inspect!(c_prop.level, content="indirect")
  inspect!(c_prop.api_name, content="old_fn")
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
    "A@1.0.0": [DeprecatedApi::new("old_fn")],
  }

  let props = find_deprecated_propagation(graph, deprecated_map)
  inspect!(props.length(), content="3")

  let b = find_prop_by_node(props, "B@1.0.0").unwrap()
  inspect!(b.level, content="direct")

  let c = find_prop_by_node(props, "C@1.0.0").unwrap()
  inspect!(c.level, content="direct")

  let d = find_prop_by_node(props, "D@1.0.0").unwrap()
  inspect!(d.level, content="indirect")
}

test "no deprecated nodes" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_edge("B", "1.0.0", "A", "1.0.0")

  let deprecated_map : Map[String, Array[DeprecatedApi]] = {}
  let props = find_deprecated_propagation(graph, deprecated_map)
  inspect!(props.length(), content="0")
}

test "multiple deprecated apis" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_edge("B", "1.0.0", "A", "1.0.0")

  let deprecated_map : Map[String, Array[DeprecatedApi]] = {
    "A@1.0.0": [
      DeprecatedApi::new("old_fn"),
      DeprecatedApi::new("old_struct"),
    ],
  }

  let props = find_deprecated_propagation(graph, deprecated_map)
  inspect!(props.length(), content="2")
}

test "self deprecated not included" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)

  let deprecated_map : Map[String, Array[DeprecatedApi]] = {
    "A@1.0.0": [DeprecatedApi::new("old_fn")],
  }

  let props = find_deprecated_propagation(graph, deprecated_map)
  inspect!(props.length(), content="0")
}
