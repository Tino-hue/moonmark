///|
/// 依赖图构建器：从根模块递归解析传递依赖
pub struct GraphBuilder {
  max_depth : Int
  cache : Map[String, @parse.Module]
}

///|
/// 创建构建器，默认最大递归深度 10
pub fn GraphBuilder::new() -> GraphBuilder {
  { max_depth: 10, cache: Map([]) }
}

///|
/// 创建构建器，指定最大递归深度
pub fn GraphBuilder::new_with_max_depth(max_depth : Int) -> GraphBuilder {
  { max_depth, cache: Map([]) }
}

///|
/// 从根模块递归构建完整依赖图
/// 
/// `fetch` 是一个同步函数，输入 (包名, 版本)，返回 `Module` 或错误。
/// 实际使用时可替换为 mooncakes.io HTTP 请求或本地文件读取。
pub fn GraphBuilder::build(
  self : GraphBuilder,
  root_name : String,
  root_version : String,
  fetch : (String, String) -> Result[@parse.Module, String],
) -> Result[DependencyGraph, String] {
  let graph = DependencyGraph::new()
  match self.build_recursive(graph, root_name, root_version, 0, fetch) {
    Ok(_) => Ok(graph)
    Err(e) => Err(e)
  }
}

///|
fn GraphBuilder::build_recursive(
  self : GraphBuilder,
  graph : DependencyGraph,
  name : String,
  version : String,
  depth : Int,
  fetch : (String, String) -> Result[@parse.Module, String],
) -> Result[String, String] {
  // 超过最大深度时停止探索（不报错，只截断）
  if depth > self.max_depth {
    return Ok(version)
  }

  let id = node_id(name, version)

  // 若已在缓存中，说明已处理过，直接返回避免重复和循环
  if self.cache.get(id) is Some(pkg) {
    return Ok(pkg.version)
  }

  // 从 fetch 获取模块元数据
  let pkg = match fetch(name, version) {
    Ok(m) => m
    Err(e) => return Err(e)
  }
  self.cache[id] = pkg

  // 将当前节点加入图（使用模块声明的实际版本号）
  let resolved = pkg.version
  graph.add_node(name, resolved, depth)

  // 递归处理依赖
  for pair in pkg.deps {
    let (dep_name, dep_version) = pair
    match self.build_recursive(graph, dep_name, dep_version, depth + 1, fetch) {
      Ok(child_resolved) =>
        graph.add_edge(name, resolved, dep_name, child_resolved)
      Err(e) => return Err(e)
    }
  }

  Ok(resolved)
}
