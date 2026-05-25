test "single node transitive size" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)

  let self_sizes = { "root@1.0.0": 100 }
  let trans = calculate_transitive_sizes(graph, self_sizes)

  let root_size = match trans.get("root@1.0.0") {
    Some(s) => s
    None => 0
  }
  inspect!(root_size, content="100")
}

test "chain transitive size" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("a", "1.0.0", 0)
  graph.add_node("b", "1.0.0", 1)
  graph.add_node("c", "1.0.0", 2)

  graph.add_edge("a", "1.0.0", "b", "1.0.0")
  graph.add_edge("b", "1.0.0", "c", "1.0.0")

  let self_sizes = {
    "a@1.0.0": 100,
    "b@1.0.0": 200,
    "c@1.0.0": 300,
  }
  let trans = calculate_transitive_sizes(graph, self_sizes)

  let c_size = match trans.get("c@1.0.0") {
    Some(s) => s
    None => 0
  }
  let b_size = match trans.get("b@1.0.0") {
    Some(s) => s
    None => 0
  }
  let a_size = match trans.get("a@1.0.0") {
    Some(s) => s
    None => 0
  }
  inspect!(c_size, content="300")
  inspect!(b_size, content="500")
  inspect!(a_size, content="600")
}

test "fork transitive size" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)
  graph.add_node("a", "1.0.0", 1)
  graph.add_node("b", "1.0.0", 1)

  graph.add_edge("root", "1.0.0", "a", "1.0.0")
  graph.add_edge("root", "1.0.0", "b", "1.0.0")

  let self_sizes = {
    "root@1.0.0": 50,
    "a@1.0.0": 100,
    "b@1.0.0": 200,
  }
  let trans = calculate_transitive_sizes(graph, self_sizes)

  let root_size = match trans.get("root@1.0.0") {
    Some(s) => s
    None => 0
  }
  let a_size = match trans.get("a@1.0.0") {
    Some(s) => s
    None => 0
  }
  let b_size = match trans.get("b@1.0.0") {
    Some(s) => s
    None => 0
  }
  inspect!(root_size, content="350")
  inspect!(a_size, content="100")
  inspect!(b_size, content="200")
}

test "find size offenders" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)
  graph.add_node("a", "1.0.0", 1)
  graph.add_node("b", "1.0.0", 1)

  graph.add_edge("root", "1.0.0", "a", "1.0.0")
  graph.add_edge("root", "1.0.0", "b", "1.0.0")

  let self_sizes = {
    "root@1.0.0": 50,
    "a@1.0.0": 100,
    "b@1.0.0": 200,
  }

  let offenders = find_size_offenders(graph, self_sizes, 2)
  inspect!(offenders.length(), content="2")
  inspect!(offenders[0].node_id, content="root@1.0.0")
  inspect!(offenders[0].transitive_size, content="350")
  inspect!(offenders[1].node_id, content="b@1.0.0")
  inspect!(offenders[1].transitive_size, content="200")
}

test "format size bytes" {
  inspect!(format_size(512), content="512 B")
}

test "format size kb" {
  inspect!(format_size(12 * 1024), content="12 KB")
}

test "format size mb" {
  inspect!(format_size(3 * 1024 * 1024), content="3 MB")
}

test "render size report" {
  let infos : Array[SizeInfo] = [
    SizeInfo::new("root@1.0.0", 50, 350),
    SizeInfo::new("b@1.0.0", 200, 200),
  ]
  let report = render_size_report(infos)
  assert_true(report.contains("root@1.0.0: self 50 B / transitive 350 B"))
  assert_true(report.contains("b@1.0.0: self 200 B / transitive 200 B"))
}
