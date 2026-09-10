/// 报告渲染器 trait
///
/// 所有输出格式（terminal / markdown / html / sarif / json / audit）
/// 都实现这个 trait，统一调用入口，方便扩展和测试。

///|
pub trait ReportRenderer {
  fn render(
    self : Self,
    report : AnalysisReport,
    graph : @graph.DependencyGraph,
    root_id : String,
  ) -> String
  fn file_ext(self : Self) -> String
}

// ========== Simple Text Renderer ==========

///|
/// 最简单的纯文本渲染器（legacy 兼容）
///
/// 输出最精简的纯文本报告，无 ANSI 颜色、无依赖树、无 Top 5。
/// 主要用于测试和作为 trait 的参考实现。
pub struct SimpleTextRenderer {
  name : String
}

///|
pub fn SimpleTextRenderer::new() -> SimpleTextRenderer {
  SimpleTextRenderer::{ name: "simple-text", }
}

///|
extend SimpleTextRenderer with ReportRenderer::{render, file_ext}

///|
impl ReportRenderer for SimpleTextRenderer with fn render(
  self,
  report,
  graph,
  root_id,
) {
  let _ = graph
  let _ = root_id
  let buf = StringBuilder()
  buf <+ "MoonBit Depsight Analysis Report\n"
  buf <+ "================================\n\n"
  buf <+ "Summary: "
  buf.write_string(report.node_count.to_string())
  buf <+ " nodes analyzed\n"
  buf <+ "Overall Health Score: "
  buf.write_string(report.overall_score.to_string())
  buf <+ "/100\n\n"

  // Health scores table
  if report.health_scores.length() > 0 {
    buf <+ "Per-Node Health Scores\n"
    buf <+ "----------------------\n"
    for s in report.health_scores {
      let bar = score_bar(s.total)
      buf.write_string(s.node_id)
      buf <+ " | "
      buf.write_string(s.total.to_string())
      buf <+ "/100 "
      buf.write_string(bar)
      buf <+ "\n"
    }
    buf <+ "\n"
  }

  // Diagnostics
  if report.diagnostics.length() > 0 {
    buf <+ "Diagnostics ("
    buf.write_string(report.diagnostics.length().to_string())
    buf <+ ")\n"
    buf <+ "----------------------\n"
    let mut critical = 0
    let mut warning = 0
    let mut info = 0
    for d in report.diagnostics {
      buf.write_string(d.to_string())
      buf <+ "\n"
      if d.is_critical() {
        critical = critical + 1
      } else if d.is_warning() {
        warning = warning + 1
      } else {
        info = info + 1
      }
    }
    buf <+ "\nSummary: "
    buf.write_string(critical.to_string())
    buf <+ " critical, "
    buf.write_string(warning.to_string())
    buf <+ " warnings, "
    buf.write_string(info.to_string())
    buf <+ " info"
  } else {
    buf <+ "No diagnostics found."
  }

  buf.to_string()
}

///|
impl ReportRenderer for SimpleTextRenderer with fn file_ext(self) {
  "txt"
}

///|
/// Legacy 兼容：简单纯文本渲染
///
/// 新代码请使用 `SimpleTextRenderer::new().render(...)`。
pub fn render_report(report : AnalysisReport) -> String {
  SimpleTextRenderer::new().render(report, @graph.DependencyGraph::new(), "")
}

// ---------- 内部辅助 ----------

///|
fn score_bar(score : Int) -> String {
  if score >= 80 {
    return "[GREEN]"
  }
  if score >= 50 {
    return "[YELLOW]"
  }
  "[RED]"
}

// ========== 工厂函数 ==========

///|
/// 根据格式名选择渲染器并渲染报告
///
/// 支持的格式：`json` / `html` / `sarif` / `markdown` / `terminal` / `audit`（默认）
/// 未知格式返回 `Error`，错误信息可直接打印给用户。
pub fn render_with_format(
  format : String,
  report : AnalysisReport,
  graph : @graph.DependencyGraph,
  root_id : String,
) -> Result[String, String] {
  if format == "json" {
    Ok(JsonRenderer::{ }.render(report, graph, root_id))
  } else if format == "html" {
    Ok(HtmlRenderer::{ }.render(report, graph, root_id))
  } else if format == "sarif" {
    Ok(SarifRenderer::{ }.render(report, graph, root_id))
  } else if format == "markdown" {
    Ok(MarkdownRenderer::{ }.render(report, graph, root_id))
  } else if format == "terminal" {
    Ok(TerminalRenderer::{ }.render(report, graph, root_id))
  } else if format == "audit" || format == "" {
    Ok(AuditRenderer::{ }.render(report, graph, root_id))
  } else {
    Err("Unsupported format: \{format}")
  }
}

///|
/// 根据格式名返回对应文件扩展名（不含点）
///
/// 用于 `-o` 自动推断输出格式。未知格式返回空字符串。
pub fn format_extension(format : String) -> String {
  if format == "json" {
    "json"
  } else if format == "html" {
    "html"
  } else if format == "sarif" {
    "sarif"
  } else if format == "markdown" {
    "md"
  } else if format == "terminal" || format == "audit" || format == "" {
    "txt"
  } else {
    ""
  }
}
