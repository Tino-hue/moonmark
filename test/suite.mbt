// MoonMark Test Suite — CommonMark compliance tests
//
// These tests verify that the parser produces correct output
// for various Markdown inputs per the CommonMark spec.

import moonmark { markdown_to_html, parse }

// ============================================================
// Test runner utilities
// ============================================================

struct TestResult {
  name : String
  passed : Bool
  expected : String
  actual : String
}

mut test_results : Array[TestResult] = Array[TestResult]()

fn assert_eq(test_name : String, expected : String, actual : String) {
  let passed = expected == actual
  test_results.push(TestResult {
    name: test_name,
    passed: passed,
    expected: expected,
    actual: actual
  })
  if !passed {
    println("❌ FAIL: " + test_name)
    println("   Expected: " + expected)
    println("   Actual:   " + actual)
  } else {
    println("✅ PASS: " + test_name)
  }
}

fn print_summary() {
  let mut pass_count = 0
  let mut fail_count = 0
  for r in test_results {
    if r.passed { pass_count = pass_count + 1 }
    else { fail_count = fail_count + 1 }
  }
  let total = pass_count + fail_count
  println("\n" + "=" .repeat(40))
  println("Test Summary: " + pass_count.to_string() + "/" + total.to_string() + " passed")
  if fail_count > 0 {
    println("⚠️  " + fail_count.to_string() + " test(s) failed!")
  } else {
    println("🎉 All tests passed!")
  }
}

// ============================================================
// ATX Heading Tests
// ============================================================

fn test_atx_heading_h1() {
  let result = markdown_to_html("# Hello")
  assert_eq("ATX heading H1", "<h1>Hello</h1>\n", result)
}

fn test_atx_heading_h2() {
  let result = markdown_to_html("## World")
  assert_eq("ATX heading H2", "<h2>World</h2>\n", result)
}

fn test_atx_heading_h3_with_content() {
  let result = markdown_to_html("### Hello MoonBit")
  assert_eq("ATX heading H3", "<h3>Hello MoonBit</h3>\n", result)
}

// ============================================================
// Paragraph Tests
// ============================================================

fn test_simple_paragraph() {
  let result = markdown_to_html("Hello, world!")
  assert_eq("Simple paragraph", "<p>Hello, world!</p>\n", result)
}

fn test_multi_line_paragraph() {
  let result = markdown_to_html("Line one\nLine two")
  // Soft breaks within paragraph
  assert_eq("Multi-line paragraph", "<p>Line one\nLine two</p>\n", result)
}

// ============================================================
// Thematic Break Tests
// ============================================================

fn test_thematic_break_asterisks() {
  let result = markdown_to_html("***")
  assert_eq("Thematic break ***", "<hr />\n", result)
}

fn test_thematic_break_dashes() {
  let result = markdown_to_html("---")
  assert_eq("Thematic break ---", "<hr />\n", result)
}

fn test_thematic_break_underscores() {
  let result = markdown_to_html("___")
  assert_eq("Thematic break ___", "<hr />\n", result)
}

// ============================================================
// Fenced Code Block Tests
// ============================================================

fn test_fenced_code_block() {
  let input = "```\nlet x = 42\n```"
  let result = markdown_to_html(input)
  assert_eq("Fenced code block",
    "<pre><code>let x = 42\n</code></pre>\n",
    result)
}

fn test_fenced_code_block_with_language() {
  let input = "```moonbit\nlet x : Int = 42\n```"
  let result = markdown_to_html(input)
  assert_eq("Fenced code with language",
    "<pre><code class=\"language-moonbit\">let x : Int = 42\n</code></pre>\n",
    result)
}

// ============================================================
// Inline Emphasis Tests
// ============================================================

fn test_emphasis_asterisk() {
  let result = markdown_to_html("*hello*")
  assert_eq("Emphasis *text*", "<p><em>hello</em></p>\n", result)
}

fn test_emphasis_underscore() {
  let result = markdown_to_html("_world_")
  assert_eq("Emphasis _text_", "<p><em>world</em></p>\n", result)
}

fn test_strong_double_asterisk() {
  let result = markdown_to_html("**bold**")
  assert_eq("Strong **text**", "<p><strong>bold</strong></p>\n", result)
}

fn test_strong_emph_triple() {
  let result = markdown_to_html("***both***")
  assert_eq("Strong+Emph ***text***",
    "<p><strong><em>both</em></strong></p>\n",
    result)
}

// ============================================================
// Inline Code Tests
// ============================================================

fn test_inline_code() {
  let result = markdown_to_html("`let x = 1`")
  assert_eq("Inline code",
    "<p><code>let x = 1</code></p>\n",
    result)
}

// ============================================================
// Link & Image Tests
// ============================================================

fn test_link() {
  let result = markdown_to_html("[MoonBit](https://moonbitlang.cn)")
  assert_eq("Link",
    "<p><a href=\"https://moonbitlang.cn\">MoonBit</a></p>\n",
    result)
}

fn test_image() {
  let result = markdown_to_html("![alt text](image.png)")
  assert_eq("Image",
    "<p><img src=\"image.png\" alt=\"alt text\" /></p>\n",
    result)
}

// ============================================================
// Strikethrough (GFM) Tests
// ============================================================

fn test_strikethrough() {
  let result = markdown_to_html("~~deleted~~")
  assert_eq("Strikethrough",
    "<p><del>deleted</del></p>\n",
    result)
}

// ============================================================
// HTML Escaping Tests
// ============================================================

fn test_html_escape_in_text() {
  let result = markdown_to_html("<script>alert('xss')</script>")
  assert_eq("HTML escaping in text",
    "<p>&lt;script&gt;alert('xss')&lt;/script&gt;</p>\n",
    result)
}

// ============================================================
// Complex Document Tests
// ============================================================

fn test_full_document() {
  let input = "# Title\n\n## Section\n\nParagraph with **bold** and *italic*.\n\n---\n\n```\ncode here\n```"
  let result = markdown_to_html(input)

  // Verify document structure exists (partial check)
  let has_h1 = result.index_of("<h1>") >= 0
  let has_h2 = result.index_of("<h2>") >= 0
  let has_p = result.index_of("<p>") >= 0
  let has_strong = result.index_of("<strong>") >= 0
  let has_hr = result.index_of("<hr") >= 0
  let has_pre = result.index_of("<pre") >= 0

  assert_eq("Full document structure",
    if has_h1 && has_h2 && has_p && has_strong && has_hr && has_pre { "OK" }
    else { "MISSING_NODES:" +
      (if !has_h1 { " h1" } else { "" }) +
      (if !has_h2 { " h2" } else { "" }) +
      (if !has_p { " p" } else { "" }) +
      (if !has_strong { " strong" } else { "" }) +
      (if !has_hr { " hr" } else { "" }) +
      (if !has_pre { " pre" } else { "" })
    },
    "OK"
  )
}

// ============================================================
// Main — Run all tests
// ============================================================

fn main {
  println("🌙 MoonMark Test Suite")
  println("=" .repeat(40))

  // ATX Headings
  test_atx_heading_h1()
  test_atx_heading_h2()
  test_atx_heading_h3_with_content()

  // Paragraphs
  test_simple_paragraph()
  test_multi_line_paragraph()

  // Thematic Breaks
  test_thematic_break_asterisks()
  test_thematic_break_dashes()
  test_thematic_break_underscores()

  // Code Blocks
  test_fenced_code_block()
  test_fenced_code_block_with_language()

  // Inline Elements
  test_emphasis_asterisk()
  test_emphasis_underscore()
  test_strong_double_asterisk()
  test_strong_emph_triple()
  test_inline_code()

  // Links & Images
  test_link()
  test_image()

  // GFM Extensions
  test_strikethrough()

  // Safety
  test_html_escape_in_text()

  // Integration
  test_full_document()

  // Print results
  print_summary()
}
