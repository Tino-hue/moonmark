pub struct DependencyNode {
  name : String
  version : String
  depth : Int
  children : Array[String]
} derive(Show)

pub struct DependencyGraph {
  nodes : Map[String, DependencyNode]
} derive(Show)

pub fn DependencyGraph::new() -> DependencyGraph {
  { nodes: Map::new() }
}

pub fn add_node(self : DependencyGraph, node : DependencyNode) -> Unit {
  self.nodes[node.name + "@" + node.version] = node
}
