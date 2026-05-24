/// 体积信息结构体
pub struct SizeInfo {
  node_id : String
  self_size : Int
  transitive_size : Int
} derive(Debug)

/// 计算所有节点的传递大小（自身 + 所有子孙）
/// `self_sizes` 是节点 ID -> 自身大小的映射
pub fn calculate_transitive_sizes(
  graph : @graph.DependencyGraph,
  self_sizes : Map[String, Int]
) -> Map[String, Int] {
  let memo : Map[String, Int] = {}
  let all_ids = graph.get_all_node_ids()
  for id in all_ids {
    let _ = calc_transitive(graph, id, self_sizes, memo)
  }
  memo
}

fn calc_transitive(
  graph : @graph.DependencyGraph,
  node_id : String,
  self_sizes : Map[String, Int],
  memo : Map[String, Int]
) -> Int {
  if memo.get(node_id) is Some(size) {
    return size
  }

  let self_size = match self_sizes.get(node_id) {
    Some(s) => s
    None => 0
  }

  let (name, version) = split_node_id(node_id)
  let children = graph.get_children(name, version)
  let mut total = self_size

  for child_id in children {
    total = total + calc_transitive(graph, child_id, self_sizes, memo)
  }

  memo[node_id] = total
  total
}

/// 找出体积罪魁祸首：按传递大小降序排列，返回前 top_n 个
pub fn find_size_offenders(
  graph : @graph.DependencyGraph,
  self_sizes : Map[String, Int],
  top_n : Int
) -> Array[SizeInfo] {
  let trans_sizes = calculate_transitive_sizes(graph, self_sizes)
  let all_ids = graph.get_all_node_ids()

  let infos : Array[SizeInfo] = []
  for id in all_ids {
    let self_size = match self_sizes.get(id) {
      Some(s) => s
      None => 0
    }
    let trans_size = match trans_sizes.get(id) {
      Some(s) => s
      None => 0
    }
    infos.push({ node_id: id, self_size, transitive_size: trans_size })
  }

  sort_by_transitive_size_desc(infos)

  let result : Array[SizeInfo] = []
  let limit = if top_n > infos.length() { infos.length() } else { top_n }
  let mut i = 0
  while i < limit {
    result.push(infos[i])
    i = i + 1
  }
  result
}

/// 格式化字节数为人类可读字符串
pub fn format_size(bytes : Int) -> String {
  if bytes < 1024 {
    bytes.to_string() + " B"
  } else if bytes < 1024 * 1024 {
    (bytes / 1024).to_string() + " KB"
  } else {
    (bytes / (1024 * 1024)).to_string() + " MB"
  }
}

/// 将 SizeInfo 数组渲染为可读的文本报告
pub fn render_size_report(offenders : Array[SizeInfo]) -> String {
  let lines : Array[String] = []
  lines.push("Size Attribution Report")
  lines.push("=======================")
  for info in offenders {
    let line = info.node_id + ": self " + format_size(info.self_size) +
      " / transitive " + format_size(info.transitive_size)
    lines.push(line)
  }
  join_lines(lines)
}

// ---------- 内部辅助 ----------

fn split_node_id(node_id : String) -> (String, String) {
  let at_idx = index_of_char(node_id, '@')
  if at_idx < 0 {
    return (node_id, "")
  }
  (substring(node_id, 0, at_idx), substring(node_id, at_idx + 1, node_id.length() - at_idx - 1))
}

fn sort_by_transitive_size_desc(arr : Array[SizeInfo]) -> Unit {
  let n = arr.length()
  let mut i = 0
  while i < n {
    let mut j = 0
    while j < n - i - 1 {
      if arr[j].transitive_size < arr[j + 1].transitive_size {
        let tmp = arr[j]
        arr[j] = arr[j + 1]
        arr[j + 1] = tmp
      }
      j = j + 1
    }
    i = i + 1
  }
}

fn join_lines(lines : Array[String]) -> String {
  join_lines_loop(lines, 0, "")
}

fn join_lines_loop(lines : Array[String], idx : Int, acc : String) -> String {
  if idx >= lines.length() { return acc }
  let sep = if idx == 0 { "" } else { "\n" }
  join_lines_loop(lines, idx + 1, acc + sep + lines[idx])
}
