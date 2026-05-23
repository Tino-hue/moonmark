/// 依赖图构建器：从根模块递归解析传递依赖
pub struct GraphBuilder {
  max_depth : Int
  cache : Map[String, @parse.Module]
}

/// 创建构建器，默认最大递归深度 10
pub fn GraphBuilder::new() -> GraphBuilder {
  { max_depth: 10, cache: {} }
}

/// 创建构建器，指定最大递归深度
pub fn GraphBuilder::new_with_max_depth(max_depth : Int) -> GraphBuilder {
  { max_depth, cache: {} }
}

/// 从根模块递归构建完整依赖图
/// 
/// `fetch` 是一个同步函数，输入 (包名, 版本)，返回 `Module` 或错误。
/// 实际使用时可替换为 mooncakes.io HTTP 请求或本地文件读取。
pub fn GraphBuilder::build(
  self : GraphBuilder,
  root_name : String,
  root_version : String,
  fetch : (String, String) -> Result[@parse.Module, String]
) -> Result[DependencyGraph, String] {
  let graph = DependencyGraph::new()
  self.build_recursive(graph, root_name, root_version, 0, fetch)?
  Ok(graph)
}

fn build_recursive(
  self : GraphBuilder,
  graph : DependencyGraph,
  name : String,
  version : String,
  depth : Int,
  fetch : (String, String) -> Result[@parse.Module, String]
) -> Result[Unit, String] {
  if depth > self.max_depth {
    return Err("Max depth exceeded at " + name + "@" + version)
  }

  // 若节点已在图中，说明已处理过，直接返回
  if graph.get_node(name, version) is Some(_) {
    return Ok(())
  }

  let id = node_id(name, version)

  // 从缓存或 fetch 获取模块元数据
  let module = match self.cache.get(id) {
    Some(m) => m
    None => {
      let m = fetch(name, version)?
      self.cache[id] = m
      m
    }
  }

  // 将当前节点加入图
  graph.add_node(name, version, depth)

  // 递归处理依赖
  for pair in module.deps {
    let (dep_name, dep_version) = pair
    graph.add_node(dep_name, dep_version, depth + 1)
    graph.add_edge(name, version, dep_name, dep_version)
    self.build_recursive(graph, dep_name, dep_version, depth + 1, fetch)?
  }

  Ok(())
}
