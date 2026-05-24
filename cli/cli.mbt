pub fn run_cli() -> Unit {
  println("MoonBit Depsight v0.1.0")

  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)
  graph.add_node("a", "1.0.0", 1)
  graph.add_node("b", "1.0.0", 1)
  graph.add_node("c", "1.0.0", 2)

  graph.add_edge("root", "1.0.0", "a", "1.0.0")
  graph.add_edge("root", "1.0.0", "b", "1.0.0")
  graph.add_edge("a", "1.0.0", "c", "1.0.0")

  let tree = graph.render_tree("root@1.0.0", 10)
  println("")
  println("Dependency Tree:")
  println(tree)
}
