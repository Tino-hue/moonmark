test "pad_left aligns correctly" {
  inspect!(pad_left("abc", 5), content="abc  ")
  inspect!(pad_left("hello", 5), content="hello")
  inspect!(pad_left("x", 3), content="x  ")
}

test "pad_right aligns correctly" {
  inspect!(pad_right("abc", 5), content="  abc")
  inspect!(pad_right("hello", 5), content="hello")
  inspect!(pad_right("x", 3), content="  x")
}

test "pad_center aligns correctly" {
  inspect!(pad_center("ab", 4), content=" ab ")
  inspect!(pad_center("a", 3), content=" a ")
  inspect!(pad_center("abc", 3), content="abc")
}

test "repeat_char repeats n times" {
  inspect!(repeat_char("-", 0), content="")
  inspect!(repeat_char("*", 3), content="***")
}

test "color functions wrap with ANSI" {
  let r = red("err")
  let g = green("ok")
  let y = yellow("warn")
  assert_true(r.contains("\u{001b}[31m"))
  assert_true(g.contains("\u{001b}[32m"))
  assert_true(y.contains("\u{001b}[33m"))
  assert_true(r.contains("\u{001b}[0m"))
  assert_true(g.contains("\u{001b}[0m"))
  assert_true(y.contains("\u{001b}[0m"))
}

test "color_score returns colored string" {
  let high = color_score(90)
  let mid = color_score(60)
  let low = color_score(30)
  assert_true(high.contains("\u{001b}[32m"))
  assert_true(mid.contains("\u{001b}[33m"))
  assert_true(low.contains("\u{001b}[31m"))
  assert_true(high.contains("90/100"))
}

test "color_level returns level labels" {
  let crit = color_level(@report.LEVEL_CRITICAL)
  let warn = color_level(@report.LEVEL_WARNING)
  let info = color_level(@report.LEVEL_INFO)
  assert_true(crit.contains("[CRIT]"))
  assert_true(warn.contains("[WARN]"))
  assert_true(info.contains("[INFO]"))
}

test "render_terminal_report contains key sections" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("root", "1.0.0", 0)

  let metas : Map[String, NodeMeta] = {
    "root@1.0.0": NodeMeta::new(license=Some("MIT")),
  }
  let report = run_analysis(graph, metas)
  let text = render_terminal_report(report, graph, "root@1.0.0")

  assert_true(text.contains("MoonBit Depsight"))
  assert_true(text.contains("Nodes: 1"))
  assert_true(text.contains("Overall"))
  assert_true(text.contains("Dependency Tree"))
  assert_true(text.contains("root@1.0.0"))
}

test "render_terminal_report with diagnostics" {
  let graph = @graph.DependencyGraph::new()
  graph.add_node("A", "1.0.0", 0)
  graph.add_node("B", "1.0.0", 1)
  graph.add_node("C", "1.0.0", 2)
  graph.add_edge("A", "1.0.0", "B", "1.0.0")
  graph.add_edge("B", "1.0.0", "C", "1.0.0")
  graph.add_edge("C", "1.0.0", "A", "1.0.0")

  let metas : Map[String, NodeMeta] = {}
  let report = run_analysis(graph, metas)
  let text = render_terminal_report(report, graph, "A@1.0.0")

  assert_true(text.contains("CRIT"))
  assert_true(text.contains("CYCLE-001"))
  assert_true(text.contains("Summary"))
}
