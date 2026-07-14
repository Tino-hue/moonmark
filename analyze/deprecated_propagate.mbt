///|
/// 跨包废弃 API 传递检测结果
pub struct DeprecatedPropagation {
  node_id : String
  source_node_id : String
  api_name : String
  level : String
} derive(Debug)

///|
/// 构造 DeprecatedPropagation（用于测试）
pub fn DeprecatedPropagation::new(
  node_id : String,
  source_node_id : String,
  api_name : String,
  level : String,
) -> DeprecatedPropagation {
  { node_id, source_node_id, api_name, level }
}

///|
/// 在依赖图中发现所有暴露于废弃 API 的节点
/// `deprecated_map` 的 key 是节点 ID（name@version），value 是该节点的废弃 API 列表
pub fn find_deprecated_propagation(
  graph : @graph.DependencyGraph,
  deprecated_map : Map[String, Array[DeprecatedApi]],
) -> Array[DeprecatedPropagation] {
  let result : Array[DeprecatedPropagation] = []
  for pair in deprecated_map {
    let (source_id, apis) = pair
    let visited = bfs_ancestors(graph, source_id)
    for entry in visited {
      let (node_id, dist) = entry
      if dist == 0 {
        continue
      } // 跳过源节点自身
      let level = if dist == 1 { "direct" } else { "indirect" }
      for api in apis {
        result.push({
          node_id,
          source_node_id: source_id,
          api_name: api.name,
          level,
        })
      }
    }
  }
  result
}

// ---------- 内部辅助 ----------

///|
fn bfs_ancestors(
  graph : @graph.DependencyGraph,
  start_id : String,
) -> Array[(String, Int)] {
  let queue : Array[(String, Int)] = [(start_id, 0)]
  let visited : Map[String, Int] = Map([])
  let mut head = 0
  while head < queue.length() {
    let (current, dist) = queue[head]
    head = head + 1
    if visited.get(current) is Some(_) {
      continue
    }
    visited[current] = dist
    let (name, version) = split_node_id(current)
    let parents = graph.get_parents(name, version)
    for parent in parents {
      if visited.get(parent) is None {
        queue.push((parent, dist + 1))
      }
    }
  }
  let result : Array[(String, Int)] = []
  for pair in visited {
    let (id, dist) = pair
    result.push((id, dist))
  }
  result
}
