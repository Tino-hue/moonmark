///|
/// 依赖图节点，唯一标识为 name@version
pub struct DependencyNode {
  name : String
  version : String
  depth : Int
  parents : Array[String]
  children : Array[String]
} derive(Debug)

///|
/// 依赖图
pub struct DependencyGraph {
  nodes : Map[String, DependencyNode]
} derive(Debug)

///|
/// 构造节点唯一标识
fn node_id(name : String, version : String) -> String {
  name + "@" + version
}

///|
/// 辅助：判断数组是否包含某元素
pub fn array_contains(arr : Array[String], item : String) -> Bool {
  for x in arr {
    if x == item {
      return true
    }
  }
  false
}

///|
/// 创建空依赖图
pub fn DependencyGraph::new() -> DependencyGraph {
  { nodes: {} }
}

///|
/// 添加节点（若已存在则忽略）
pub fn DependencyGraph::add_node(
  self : DependencyGraph,
  name : String,
  version : String,
  depth : Int,
) -> Unit {
  let id = node_id(name, version)
  if self.nodes.get(id) is None {
    self.nodes[id] = { name, version, depth, parents: [], children: [] }
  }
}

///|
/// 添加有向边：from 依赖 to
pub fn DependencyGraph::add_edge(
  self : DependencyGraph,
  from_name : String,
  from_version : String,
  to_name : String,
  to_version : String,
) -> Unit {
  let from_id = node_id(from_name, from_version)
  let to_id = node_id(to_name, to_version)

  guard self.nodes.get(from_id) is Some(from_node) else { return }
  guard self.nodes.get(to_id) is Some(to_node) else { return }

  if array_contains(from_node.children, to_id) == false {
    from_node.children.push(to_id)
  }
  if array_contains(to_node.parents, from_id) == false {
    to_node.parents.push(from_id)
  }
}

///|
/// 获取节点
pub fn DependencyGraph::get_node(
  self : DependencyGraph,
  name : String,
  version : String,
) -> DependencyNode? {
  self.nodes.get(node_id(name, version))
}

///|
/// 通过节点 ID 获取节点
pub fn DependencyGraph::get_node_by_id(
  self : DependencyGraph,
  id : String,
) -> DependencyNode? {
  self.nodes.get(id)
}

///|
/// 获取子节点 ID 列表
pub fn DependencyGraph::get_children(
  self : DependencyGraph,
  name : String,
  version : String,
) -> Array[String] {
  let id = node_id(name, version)
  match self.nodes.get(id) {
    Some(node) => node.children
    None => []
  }
}

///|
/// 获取父节点 ID 列表
pub fn DependencyGraph::get_parents(
  self : DependencyGraph,
  name : String,
  version : String,
) -> Array[String] {
  let id = node_id(name, version)
  match self.nodes.get(id) {
    Some(node) => node.parents
    None => []
  }
}

///|
/// 获取所有节点 ID
pub fn DependencyGraph::get_all_node_ids(
  self : DependencyGraph,
) -> Array[String] {
  let result = []
  for pair in self.nodes {
    let (id, _) = pair
    result.push(id)
  }
  result
}

///|
/// 拓扑排序（Kahn 算法）。若存在环则返回错误。
pub fn DependencyGraph::topological_sort(
  self : DependencyGraph,
) -> Result[Array[String], String] {
  let in_degree : Map[String, Int] = {}
  for pair in self.nodes {
    let (id, _) = pair
    in_degree[id] = 0
  }

  // 计算入度
  for pair in self.nodes {
    let (_, node) = pair
    for child_id in node.children {
      in_degree[child_id] = (match in_degree.get(child_id) {
          Some(d) => d
          None => 0
        }) +
        1
    }
  }

  // 入度为 0 的节点入队
  let queue = []
  for pair in in_degree {
    let (id, degree) = pair
    if degree == 0 {
      queue.push(id)
    }
  }

  let result = []
  while queue.length() > 0 {
    let current = match queue.pop() {
      Some(x) => x
      None => break
    }
    result.push(current)

    guard self.nodes.get(current) is Some(node) else { continue }
    for child_id in node.children {
      let new_degree = (match in_degree.get(child_id) {
          Some(d) => d
          None => 1
        }) -
        1
      in_degree[child_id] = new_degree
      if new_degree == 0 {
        queue.push(child_id)
      }
    }
  }

  if result.length() != self.nodes.length() {
    return Err("Cycle detected in dependency graph")
  }

  Ok(result)
}

///|
/// 获取节点数量
pub fn DependencyGraph::size(self : DependencyGraph) -> Int {
  self.nodes.length()
}

///|
/// 将依赖图以树形文本格式输出。
/// `root_id` 是完整的节点标识（如 `"root@1.0.0"`）。
/// `max_depth` 控制展开深度，0 表示只显示根节点。
pub fn DependencyGraph::render_tree(
  self : DependencyGraph,
  root_id : String,
  max_depth : Int,
) -> String {
  self.render_tree_with_markers(root_id, max_depth, {})
}

///|
/// 带标记的依赖树渲染。
/// `markers` 的 key 为节点 ID，value 为附加在该行末尾的标记文本。
pub fn DependencyGraph::render_tree_with_markers(
  self : DependencyGraph,
  root_id : String,
  max_depth : Int,
  markers : Map[String, String],
) -> String {
  let lines = []
  render_tree_node_with_markers(
    self, root_id, 0, max_depth, "", true, markers, lines,
  )
  join_lines(lines)
}

///|
fn render_tree_node_with_markers(
  graph : DependencyGraph,
  id : String,
  depth : Int,
  max_depth : Int,
  prefix : String,
  is_last : Bool,
  markers : Map[String, String],
  lines : Array[String],
) -> Unit {
  if depth > max_depth {
    return
  }

  guard graph.nodes.get(id) is Some(node) else { return }

  let connector = if depth == 0 {
    ""
  } else if is_last {
    "└── "
  } else {
    "├── "
  }
  let marker = match markers.get(id) {
    Some(m) => " " + m
    None => ""
  }
  lines.push(prefix + connector + id + marker)

  let child_count = node.children.length()
  let child_prefix = if depth == 0 {
    ""
  } else if is_last {
    "    "
  } else {
    "│   "
  }
  let new_prefix = prefix + child_prefix

  let mut i = 0
  while i < child_count {
    let is_last_child = i == child_count - 1
    render_tree_node_with_markers(
      graph,
      node.children[i],
      depth + 1,
      max_depth,
      new_prefix,
      is_last_child,
      markers,
      lines,
    )
    i = i + 1
  }
}

///|
fn join_lines(lines : Array[String]) -> String {
  join_lines_loop(lines, 0, "")
}

///|
fn join_lines_loop(lines : Array[String], idx : Int, acc : String) -> String {
  if idx >= lines.length() {
    return acc
  }
  let sep = if idx == 0 { "" } else { "\n" }
  join_lines_loop(lines, idx + 1, acc + sep + lines[idx])
}

///|
/// 环检测器（内部辅助结构）
priv struct CycleDetector {
  grey : Map[String, Bool]
  black : Map[String, Bool]
}

///|
fn CycleDetector::new() -> CycleDetector {
  { grey: {}, black: {} }
}

///|
fn CycleDetector::dfs(
  self : CycleDetector,
  graph : DependencyGraph,
  id : String,
  path : Array[String],
) -> Array[String] {
  if self.black.get(id) is Some(_) {
    return []
  }
  if self.grey.get(id) is Some(_) {
    return extract_cycle(path, id)
  }

  self.grey[id] = true
  path.push(id)

  guard graph.nodes.get(id) is Some(node) else {
    let _ = path.pop()
    self.black[id] = true
    return []
  }

  for child_id in node.children {
    let result = self.dfs(graph, child_id, path)
    if result.length() > 0 {
      return result
    }
  }

  let _ = path.pop()
  self.black[id] = true
  []
}

///|
fn extract_cycle(path : Array[String], id : String) -> Array[String] {
  extract_cycle_loop(path, id, 0, false, [])
}

///|
fn extract_cycle_loop(
  path : Array[String],
  id : String,
  idx : Int,
  started : Bool,
  acc : Array[String],
) -> Array[String] {
  if idx >= path.length() {
    acc.push(id)
    return acc
  }
  let node_id = path[idx]
  let new_started = if node_id == id { true } else { started }
  if new_started {
    acc.push(node_id)
  }
  extract_cycle_loop(path, id, idx + 1, new_started, acc)
}

///|
/// 查找图中第一个循环依赖环。
/// 返回环上的节点 ID 数组（按发现顺序，末尾重复起点以闭合环）。
/// 若无环，返回空数组。
pub fn DependencyGraph::find_cycle(self : DependencyGraph) -> Array[String] {
  let detector = CycleDetector::new()
  let path : Array[String] = []

  for pair in self.nodes {
    let (id, _) = pair
    let result = detector.dfs(self, id, path)
    if result.length() > 0 {
      return result
    }
  }

  []
}

///|
/// 检查图中是否存在循环依赖，并返回结构化诊断信息数组。
/// 若无环，返回空数组。
pub fn DependencyGraph::check_cycles(
  self : DependencyGraph,
) -> Array[@report.Diagnostic] {
  let cycle = self.find_cycle()
  if cycle.length() == 0 {
    return []
  }

  let cycle_path = cycle_to_path(cycle)
  let diag = @report.Diagnostic::critical(
    "CYCLE-001", "Circular dependency detected", cycle_path,
  ).with_suggestion(
    "Review the dependency chain and remove one of the edges to break the cycle.",
  )

  [diag]
}

///|
/// 将环数组（末尾重复起点）转为路径数组（不重复）
fn cycle_to_path(cycle : Array[String]) -> Array[String] {
  if cycle.length() == 0 {
    return []
  }
  cycle_to_path_loop(cycle, 0, cycle.length() - 1, [])
}

///|
fn cycle_to_path_loop(
  cycle : Array[String],
  idx : Int,
  limit : Int,
  acc : Array[String],
) -> Array[String] {
  if idx >= limit {
    return acc
  }
  acc.push(cycle[idx])
  cycle_to_path_loop(cycle, idx + 1, limit, acc)
}
