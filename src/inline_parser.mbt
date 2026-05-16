// MoonMark Inline Parser — Processes inline elements within block-level content
// Phase 3: Block text → Inline AST nodes

pub use ast.{Inline, Text, Code, Emph, Strong, StrongEmph,
              HardBreak, SoftBreak, Image, ImageInfo, Link, LinkInfo,
              HTMLInline, Strikethrough}

// ============================================================
// Inline parser state
// ============================================================

pub struct InlineParser {
  input : String
  pos : Int
  len : Int
}

// ============================================================
// Public API
// ============================================================

/// Parse inline content from a plain text string into an array of Inline nodes.
/// This is called after block parsing to resolve inline elements within paragraphs,
/// headings, list items, etc.
pub fn parse_inline(text : String) -> Array[Inline] {
  if text == "" { return Array[Inline]() }
  let parser = InlineParser { input: text, pos: 0, len: text.length() }
  parse_inlines(ref parser, Array[String]())  // No delimiters stack initially
}

/// Parse inline content with a set of active delimiter openers (for emphasis matching).
fn parse_inlines(ref parser : InlineParser, delimiters : Array[String]) -> Array[Inline] {
  let mut inlines = Array[Inline]()
  let mut current_text = ""

  while parser.pos < parser.len {
    let c = char_at(parser)

    // Escape character: treat next char as literal
    if c == '\\' && parser.pos + 1 < parser.len {
      if current_text != "" {
        inlines.push(Inline::Text(current_text))
        current_text = ""
      }
      advance_pos(ref parser)
      current_text = current_text + char_at(parser)
      advance_pos(ref parser)
      continue
    }

    // Backtick: inline code
    if c == '`' {
      if current_text != "" {
        inlines.push(Inline::Text(current_text))
        current_text = ""
      }
      let code_node = parse_inline_code(ref parser)
      inlines.push(code_node)
      continue
    }

    // Asterisk / Underscore: emphasis/strong
    if c == '*' || c == '_' {
      if current_text != "" {
        inlines.push(Inline::Text(current_text))
        current_text = ""
      }
      let emph_result = parse_emphasis(ref parser, c)
      match emph_result {
        Some(node) => inlines.push(node),
        None => { current_text = current_text + c; advance_pos(ref parser) }
      }
      continue
    }

    // Open bracket: potential link or image
    if c == '[' {
      if current_text != "" {
        inlines.push(Inline::Text(current_text))
        current_text = ""
      }
      let link_result = parse_link(ref parser)
      match link_result {
        Some(node) => inlines.push(node),
        None => { current_text = current_text + "["; advance_pos(ref parser) }
      }
      continue
    }

    // Exclamation + bracket: potential image
    if c == '!' && peek_char(parser) == '[' {
      if current_text != "" {
        inlines.push(Inline::Text(current_text))
        current_text = ""
      }
      advance_pos(ref parser)  // consume !
      let img_result = parse_image(ref parser)
      match img_result {
        Some(node) => inlines.push(node),
        None => { current_text = current_text + "!["; advance_pos(ref parser) }
      }
      continue
    }

    // Tilde: strikethrough (GFM extension)
    if c == '~' && peek_char(parser) == '~' {
      if current_text != "" {
        inlines.push(Inline::Text(current_text))
        current_text = ""
      }
      let strike_result = parse_strikethrough(ref parser)
      match strike_result {
        Some(node) => inlines.push(node),
        None => { current_text = current_text + "~"; advance_pos(ref parser) }
      }
      continue
    }

    // Hard break: two or more trailing spaces before newline
    if c == ' ' && count_trailing_spaces(parser) >= 2 &&
       (parser.pos + 2 >= parser.len ||
        (peek_n(parser, 1) == '\n' || peek_n(parser, 1) == '\r')) {
      if current_text != "" {
        inlines.push(Inline::Text(current_text))
        current_text = ""
      }
      inlines.push(Inline::HardBreak)
      // Skip spaces and newline
      while parser.pos < parser.len && char_at(parser) == ' ' { advance_pos(ref parser) }
      if parser.pos < parser.len && char_at(parser) == '\n' { advance_pos(ref parser) }
      continue
    }

    // Soft break (newline not preceded by two spaces)
    if c == '\n' || c == '\r' {
      if current_text != "" {
        inlines.push(Inline::Text(current_text))
        current_text = ""
      }
      inlines.push(Inline::SoftBreak)
      advance_pos(ref parser)
      if c == '\r' && char_at(parser) == '\n' { advance_pos(ref parser) }  // \r\n
      continue
    }

    // Default: accumulate text
    current_text = current_text + c
    advance_pos(ref parser)
  }

  // Flush remaining text
  if current_text != "" {
    inlines.push(Inline::Text(current_text))
  }

  inlines
}

// ============================================================
// Inline element parsers
// ============================================================

/// Parse inline code between backticks: `code`
fn parse_inline_code(ref parser : InlineParser) -> Inline {
  advance_pos(ref parser)  // opening `
  let mut code = ""
  // Count opening backticks to handle nested `` ` ``
  let mut tick_count = 1
  while parser.pos < parser.len && char_at(parser) == '`' {
    tick_count = tick_count + 1
    advance_pos(ref parser)
  }

  // Find closing backtick sequence of same length
  while parser.pos < parser.len {
    if char_at(parser) == '`' {
      let mut close_ticks = 0
      let save_pos = parser.pos
      while parser.pos < parser.len && char_at(parser) == '`' {
        close_ticks = close_ticks + 1
        advance_pos(ref parser)
      }
      if close_ticks == tick_count {
        return Inline::Code(code.trim())
      } else {
        // Not enough ticks, include as part of code
        parser.pos = save_pos
        code = code + "`"
        advance_pos(ref parser)
      }
    } else {
      code = code + char_at(parser)
      advance_pos(ref parser)
    }
  }
  // Unclosed backtick — return what we have
  Inline::Code(code)
}

/// Parse emphasis (*text*, _text_), strong (**text**, __text__), or strong+emph (***text***)
fn parse_emphasis(ref parser : InlineParser, delim : String) -> Option[Inline] {
  let start_pos = parser.pos
  // Count consecutive delimiter characters
  let mut count = 0
  while parser.pos < parser.len && char_at(parser) == delim {
    count = count + 1
    advance_pos(ref parser)
  }

  if count == 0 { return None }

  // Need at least one character of content for valid emphasis
  if parser.pos >= parser.len || is_whitespace(char_at(parser)) {
    return None
  }

  // Recursively parse inner content until we find matching delimiters
  let inner_text = collect_until_delim(ref parser, delim, count)

  if inner_text == "" {
    // No matching closer found — revert
    parser.pos = start_pos
    return None
  }

  let inner_inlines = parse_inline(inner_text)

  match count {
    1 => Some(Inline::Emph(inner_inlines)),
    2 => Some(Inline::Strong(inner_inlines)),
    _ => Some(Inline::StrongEmph(inner_inlines))  // 3+
  }
}

/// Collect text until we find matching closing delimiter(s).
fn collect_until_delim(ref parser : InlineParser, delim : String, open_count : Int) -> String {
  let mut text = ""
  let mut paren_depth = 0  // Don't break inside [link](url) parens

  while parser.pos < parser.len {
    let c = char_at(parser)

    if c == '(' { paren_depth = paren_depth + 1 }
    if c == ')' { paren_depth = paren_depth - 1 }

    // Check for closing delimiter sequence
    if c == delim && paren_depth <= 0 {
      let mut close_count = 0
      let check_pos = parser.pos
      while check_pos < parser.input.length() &&
            parser.input.char_at(check_pos) == delim {
        close_count = close_count + 1
        check_pos = check_pos + 1
      }
      // Match if close_count >= open_count (or same rule variant)
      if close_count >= open_count {
        // Consume the closing delimiters
        for _ in 0..close_count { advance_pos(ref parser) }
        return text
      }
    }

    // Stop at newline for single * or _
    if (delim == "*" || delim == "_") && open_count <= 2 &&
       (c == '\n' || c == '\r') && text != "" {
      break
    }

    text = text + c
    advance_pos(ref parser)
  }

  text
}

/// Parse link: [text](url "title")
fn parse_link(ref parser : InlineParser) -> Option[Inline] {
  advance_pos(ref parser)  // consume [

  // Collect link text until ]
  let mut link_text = ""
  let mut bracket_depth = 1

  while parser.pos < parser.len && bracket_depth > 0 {
    let c = char_at(parser)
    if c == '[' { bracket_depth = bracket_depth + 1 }
    if c == ']' { bracket_depth = bracket_depth - 1 }
    if bracket_depth > 0 { link_text = link_text + c }
    advance_pos(ref parser)
  }

  if bracket_depth != 0 { return None }  // Unclosed [

  // Expect ( immediately after ]
  if parser.pos >= parser.len || char_at(parser) != '(' { return None }
  advance_pos(ref parser)  // consume (

  // Parse URL
  let url = parse_link_url(ref parser)

  // Parse optional title
  let title = parse_link_title(ref parser)

  // Expect )
  if parser.pos >= parser.len || char_at(parser) != ')' { return None }
  advance_pos(ref parser)  // consume )

  let inner_inlines = parse_inline(link_text)
  Some(Inline::Link(LinkInfo {
    text: inner_inlines,
    url: url,
    title: title
  }))
}

/// Parse image: ![alt](url "title")
fn parse_image(ref parser : InlineParser) -> Option[Inline] {
  advance_pos(ref parser)  // consume [

  // Collect alt text until ]
  let mut alt = ""
  while parser.pos < parser.len && char_at(parser) != ']' {
    alt = alt + char_at(parser)
    advance_pos(ref parser)
  }

  if parser.pos >= parser.len { return None }
  advance_pos(ref parser)  // consume ]

  // Expect (
  if parser.pos >= parser.len || char_at(parser) != '(' { return None }
  advance_pos(ref parser)  // consume (

  let url = parse_link_url(ref parser)
  let title = parse_link_title(ref parser)

  if parser.pos >= parser.len || char_at(parser) != ')' { return None }
  advance_pos(ref parser)  // consume )

  Some(Inline::Image(ImageInfo {
    alt: alt,
    url: url,
    title: title
  }))
}

/// Parse strikethrough: ~~deleted~~ (GFM)
fn parse_strikethrough(ref parser : InlineParser) -> Option[Inline] {
  advance_pos(ref parser)  // first ~
  advance_pos(ref parser)  // second ~

  let mut text = ""
  while parser.pos < parser.len {
    if char_at(parser) == '~' && peek_char(parser) == '~' {
      advance_pos(ref parser)  // first ~
      advance_pos(ref parser)  // second ~
      let inner = parse_inline(text)
      return Some(Inline::Strikethrough(inner))
    }
    text = text + char_at(parser)
    advance_pos(ref parser)
  }

  None  // Unclosed strikethrough
}

// ============================================================
// Link URL and title helpers
// ============================================================

fn parse_link_url(ref parser : InlineParser) -> String {
  let mut url = ""
  // Skip leading whitespace
  while parser.pos < parser.len && is_whitespace(char_at(parser)) {
    advance_pos(ref parser)
  }
  // Handle angle-bracket URLs: <http://...>
  if char_at(parser) == '<' {
    advance_pos(ref parser)
    while parser.pos < parser.len && char_at(parser) != '>' {
      url = url + char_at(parser)
      advance_pos(ref parser)
    }
    if parser.pos < parser.len { advance_pos(ref parser) }  // >
  } else {
    // Regular URL until whitespace, ), or "
    while parser.pos < parser.len {
      let c = char_at(parser)
      if is_whitespace(c) || c == '"' || c == '\'' || c == ')' { break }
      url = url + c
      advance_pos(ref parser)
    }
  }
  url
}

fn parse_link_title(ref parser : InlineParser) -> String? {
  // Skip whitespace
  while parser.pos < parser.len && is_whitespace(char_at(parser)) {
    advance_pos(ref parser)
  }
  if parser.pos >= parser.len { return null }

  let quote = char_at(parser)
  if quote != '"' && quote != '\'' { return null }

  advance_pos(ref parser)  // consume opening quote
  let mut title = ""
  while parser.pos < parser.len && char_at(parser) != quote {
    title = title + char_at(parser)
    advance_pos(ref parser)
  }
  if parser.pos < parser.len { advance_pos(ref parser) }  // consume closing quote

  Some(title)
}

// ============================================================
// Character helpers
// ============================================================

fn char_at(parser : InlineParser) -> String {
  if parser.pos >= parser.len { "" }
  else { parser.input.char_at(parser.pos).to_string() }
}

fn peek_char(parser : InlineParser) -> String {
  if parser.pos + 1 >= parser.len { "" }
  else { parser.input.char_at(parser.pos + 1).to_string() }
}

fn peek_n(parser : InlineParser, n : Int) -> String {
  let idx = parser.pos + n
  if idx >= parser.len { "" }
  else { parser.input.char_at(idx).to_string() }
}

fn advance_pos(ref parser : InlineParser) {
  parser.pos = parser.pos + 1
}

fn is_whitespace(c : String) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

fn count_trailing_spaces(parser : InlineParser) -> Int {
  let mut count = 0
  let mut i = parser.pos
  while i < parser.input.length() && parser.input.char_at(i) == ' ' {
    count = count + 1
    i = i + 1
  }
  count
}
