///|
/// 跨包废弃 API 传递检测结果
pub struct DeprecatedPropagation {
  /// 被「间接暴露废弃 API」的节点（用户直接依赖或更上层的包）
  node_id : String
  /// 废弃 API 的源头节点（源头直接声明了 deprecated API）
  source_node_id : String
  /// 废弃 API 名称
  api_name : String
  /// 传播深度：1 = 使用者直接依赖源头包（direct），2+ = 隔了 1 层以上
  depth : Int
  /// 完整传播路径，从源头到暴露节点（含两端）：[source, p1, p2, ..., node_id]。
  /// path.length() == depth + 1。
  path : Array[String]
} derive(Debug)

///|
/// 构造 DeprecatedPropagation（主要用于测试断言）
pub fn DeprecatedPropagation::new(
  node_id : String,
  source_node_id : String,
  api_name : String,
  depth : Int,
  path : Array[String],
) -> DeprecatedPropagation {
  { node_id, source_node_id, api_name, depth, path, }
}

///|
/// 在依赖图中发现所有「暴露了废弃 API」的祖先节点。
///
/// 传播规则：如果 package S 本身 deprecated 了某个 API，那么所有依赖 S（无论多少跳）
/// 的祖先包 A 都被视为「间接暴露」这条 API；距离=1 为直接暴露（A→S），
/// 距离≥2 为跨层暴露（A→B→S ……）。每条结果携带完整传播路径。
pub fn find_deprecated_propagation(
  graph : @graph.DependencyGraph,
  deprecated_map : Map[String, Array[DeprecatedApi]],
) -> Array[DeprecatedPropagation] {
  let result : Array[DeprecatedPropagation] = []
  for pair in deprecated_map {
    let (source_id, apis) = pair
    let (distances, prev) = bfs_ancestors_with_prev(graph, source_id)
    for pair2 in distances {
      let (node_id, dist) = pair2
      if dist == 0 {
        continue
      } // 跳过源节点自身
      let path = reconstruct_path(prev, source_id, node_id)
      for api in apis {
        result.push({
          node_id,
          source_node_id: source_id,
          api_name: api.name,
          depth: dist,
          path,
        })
      }
    }
  }
  result
}

// ---------- 内部辅助 ----------

///|
/// 从 start_id 出发，沿「依赖父边」（parent = 谁依赖我）做 BFS，
/// 返回 `(距离 map, 前驱 map)` 两个结果。每个可达祖先的最短距离
/// 与其在 BFS 树上的前驱节点 ID（用来回溯路径）。
fn bfs_ancestors_with_prev(
  graph : @graph.DependencyGraph,
  start_id : String,
) -> (Map[String, Int], Map[String, String]) {
  let queue : Array[(String, Int)] = [(start_id, 0)]
  let dist : Map[String, Int] = Map([])
  let prev : Map[String, String] = Map([])
  let mut head = 0
  while head < queue.length() {
    let (current, d) = queue[head]
    head = head + 1
    if dist.get(current) is Some(_) {
      continue
    }
    dist[current] = d
    let (name, version) = split_node_id(current)
    let parents = graph.get_parents(name, version)
    for parent in parents {
      if dist.get(parent) is None {
        queue.push((parent, d + 1))
        // 只写第一次（BFS = 最短路径），后序同距离写入不会覆盖
        if prev.get(parent) is None {
          prev[parent] = current
        }
      }
    }
  }
  (dist, prev)
}

///|
/// 用 BFS 前驱表回溯 [source -> ... -> target] 路径。若 prev 中不存在有效
/// 链，降级为 [target]（不会发生，因为只有距离可达的节点会走到这里调用）。
fn reconstruct_path(
  prev : Map[String, String],
  source_id : String,
  target_id : String,
) -> Array[String] {
  let reversed : Array[String] = []
  let mut cur = target_id
  reversed.push(cur)
  while cur != source_id {
    match prev.get(cur) {
      Some(p) => {
        reversed.push(p)
        cur = p
      }
      None => break
    }
  }
  // reverse in place
  let n = reversed.length()
  let mut i = 0
  while i < n / 2 {
    let tmp = reversed[i]
    reversed[i] = reversed[n - 1 - i]
    reversed[n - 1 - i] = tmp
    i = i + 1
  }
  reversed
}
