/// 终端输出工具集：ANSI 颜色、表格格式化、字符串填充
///
/// 所有颜色函数返回包含 ANSI 转义码的字符串，
/// 直接在终端打印即可看到彩色效果；非终端环境会原样显示转义码。

// ========== ANSI 颜色常量 ==========

fn color_red() -> String { "\u{001b}[31m" }
fn color_green() -> String { "\u{001b}[32m" }
fn color_yellow() -> String { "\u{001b}[33m" }
fn color_bold() -> String { "\u{001b}[1m" }
fn color_dim() -> String { "\u{001b}[2m" }
fn color_reset() -> String { "\u{001b}[0m" }

// ========== 颜色包装函数 ==========

/// 红色文本（用于 Critical / 低分）
pub fn red(text : String) -> String {
  color_red() + text + color_reset()
}

/// 绿色文本（用于 OK / 高分）
pub fn green(text : String) -> String {
  color_green() + text + color_reset()
}

/// 黄色文本（用于 Warning / 中等分数）
pub fn yellow(text : String) -> String {
  color_yellow() + text + color_reset()
}

/// 加粗文本
pub fn bold(text : String) -> String {
  color_bold() + text + color_reset()
}

/// 暗淡文本（次要信息）
pub fn dim(text : String) -> String {
  color_dim() + text + color_reset()
}

/// 根据 0-100 分数返回带颜色的字符串
pub fn color_score(score : Int) -> String {
  let s = score.to_string() + "/100"
  if score >= 80 { return green(s) }
  if score >= 50 { return yellow(s) }
  red(s)
}

/// 根据诊断级别返回带颜色的标签
pub fn color_level(level : String) -> String {
  if level == @report.level_critical() { return red("[CRIT]") }
  if level == @report.level_warning() { return yellow("[WARN]") }
  green("[INFO]")
}

// ========== 字符串格式化 ==========

/// 左对齐到指定宽度（不足补空格）
pub fn pad_left(text : String, width : Int) -> String {
  let len = string_length(text)
  let pad_count = width - len
  if pad_count <= 0 { return text }
  text + repeat_char(" ", pad_count)
}

/// 右对齐到指定宽度（不足左侧补空格）
pub fn pad_right(text : String, width : Int) -> String {
  let len = string_length(text)
  let pad_count = width - len
  if pad_count <= 0 { return text }
  repeat_char(" ", pad_count) + text
}

/// 居中对齐
pub fn pad_center(text : String, width : Int) -> String {
  let len = string_length(text)
  let pad_count = width - len
  if pad_count <= 0 { return text }
  let left_pad = pad_count / 2
  let right_pad = pad_count - left_pad
  repeat_char(" ", left_pad) + text + repeat_char(" ", right_pad)
}

/// 计算字符串的显示长度（ANSI 转义码不计入宽度）
fn string_length(text : String) -> Int {
  strip_ansi_length(text, 0, 0)
}

fn strip_ansi_length(text : String, idx : Int, count : Int) -> Int {
  if idx >= text.length() { return count }
  let code = text[idx].to_int()
  // 检测 ANSI 开始 \u{001b}[
  if code == '\u{001b}'.to_int() && idx + 1 < text.length() && text[idx + 1].to_int() == '['.to_int() {
    let new_idx = skip_ansi_seq(text, idx + 2)
    strip_ansi_length(text, new_idx, count)
  } else {
    strip_ansi_length(text, idx + 1, count + 1)
  }
}

fn skip_ansi_seq(text : String, idx : Int) -> Int {
  if idx >= text.length() { return idx }
  let code = text[idx].to_int()
  if code == 'm'.to_int() { return idx + 1 }
  skip_ansi_seq(text, idx + 1)
}

/// 重复字符 n 次
pub fn repeat_char(ch : String, n : Int) -> String {
  repeat_char_loop(ch, n, "")
}

fn repeat_char_loop(ch : String, remaining : Int, acc : String) -> String {
  if remaining <= 0 { return acc }
  repeat_char_loop(ch, remaining - 1, acc + ch)
}
