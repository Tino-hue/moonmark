// MoonMark Lexer — Tokenizes Markdown source into tokens
// Phase 1 of the parsing pipeline: Markdown source → Tokens

// ============================================================
// Token types
// ============================================================

pub enum TokenType {
  // Block-level tokens
  ATXHeading           // # ## ### #### ##### ######
  SetextHeading        // underline === or ---
  ThematicBreak        // --- *** ___
  IndentedCode         // 4+ space-indented code line
  FencedCodeFence      // ``` or ~~~ fence
  BlankLine            // Empty or whitespace-only line
  ListMarkerUnordered  // - * + list marker
  ListMarkerOrdered    // 1. 2. 3. etc.
  BlockQuotePrefix     // > marker
  HTMLBlockOpen        // Opening HTML block tag
  HTMLBlockClose       // Closing HTML block tag
  PlainText            // Default: plain paragraph text

  // Inline-level tokens (produced during inline lexing)
  Backtick             // ` code delimiter
  Asterisk             // * emph/strong delimiter
  Underscore           // _ emph/strong delimiter
  OpenBracket          // [ link/image start
  CloseBracket         // ] link/image end
  OpenParen            // ( URL start
  CloseParen           // ) URL end
  Exclamation          // ! image prefix
  Tilde                // ~~ strikethrough (GFM)
  Newline              // Line ending
  Text(String)         // Literal text content
  EOF                  // End of input
}

pub struct Token {
  ty : TokenType
  value : String        // Raw text slice
  line : Int            // 1-based line number
  col : Int             // 1-based column number
}

// ============================================================
// Lexer state
// ============================================================

pub struct Lexer {
  source : String
  pos : Int              // Current byte position
  line : Int             // Current line number
  col : Int              // Current column number
  len : Int              // Total length of source
}

// ============================================================
// Public API
// ============================================================

pub fn new(source : String) -> Lexer {
  Lexer { source: source, pos: 0, line: 1, col: 1, len: source.length() }
}

/// Tokenize the full Markdown source into a list of tokens.
/// Returns an array of Token for the block parser to consume.
pub fn tokenize(lexer : Lexer) -> Array[Token] {
  let mut tokens = Array[Token]()
  while lexer.pos < lexer.len {
    let token = next_token(ref lexer)
    tokens.push(token)
  }
  // Append EOF sentinel
  tokens.push(Token { ty: TokenType::EOF, value: "", line: lexer.line, col: lexer.col })
  tokens
}

// ============================================================
// Internal tokenization
// ============================================================

fn next_token(ref lexer : Lexer) -> Token {
  let start_line = lexer.line
  let start_col = lexer.col

  // Check for blank line first
  if is_blank_line(lexer) {
    consume_blank_line(ref lexer)
    return Token { ty: TokenType::BlankLine, value: "", line: start_line, col: start_col }
  }

  // Check for ATX heading (# ... ## ... etc.)
  if is_atx_heading(lexer) {
    return scan_atx_heading(ref lexer)
  }

  // Check for thematic break (--- *** ___)
  if is_thematic_break(lexer) {
    return scan_thematic_break(ref lexer)
  }

  // Check for fenced code fence (``` or ~~~)
  if is_fenced_code_fence(lexer) {
    return scan_fenced_code_fence(ref lexer)
  }

  // Check for block quote prefix (>)
  if current_char(lexer) == '>' {
    return scan_block_quote_prefix(ref lexer)
  }

  // Check for unordered list marker (- * +)
  if is_unordered_list_marker(lexer) {
    return scan_list_marker_unordered(ref lexer)
  }

  // Check for ordered list marker (1. 2. etc.)
  if is_ordered_list_marker(lexer) {
    return scan_list_marker_ordered(ref lexer)
  }

  // Default: plain text line
  scan_plain_text_line(ref lexer)
}

// ============================================================
// Character helpers
// ============================================================

fn current_char(lexer : Lexer) -> String {
  if lexer.pos >= lexer.len { "" }
  else { lexer.source.char_at(lexer.pos).to_string() }
}

fn peek_char(lexer : Lexer) -> String {
  if lexer.pos + 1 >= lexer.len { "" }
  else { lexer.source.char_at(lexer.pos + 1).to_string() }
}

fn advance(ref lexer : Lexer) -> String {
  let ch = current_char(lexer)
  if ch != "" {
    lexer.pos = lexer.pos + 1
    if ch == "\n" {
      lexer.line = lexer.line + 1
      lexer.col = 1
    } else {
      lexer.col = lexer.col + 1
    }
  }
  ch
}

fn advance_n(ref lexer : Lexer, n : Int) {
  for _ in 0..n { advance(ref lexer) }
}

// ============================================================
// Detection predicates
// ============================================================

fn is_blank_line(lexer : Lexer) -> Bool {
  let mut i = lexer.pos
  while i < lexer.len {
    let c = lexer.source.char_at(i)
    if c == '\n' || c == '\r' { break }
    if c != ' ' && c != '\t' { return false }
    i = i + 1
  }
  true
}

fn consume_blank_line(ref lexer : Lexer) {
  while lexer.pos < lexer.len {
    let c = current_char(lexer)
    if c == "\n" || c == "\r" { advance(ref lexer); break }
    if c == ' ' || c == '\t' { advance(ref lexer) }
    else { break }
  }
}

fn is_atx_heading(lexer : Lexer) -> Bool {
  // ATX heading: 1-6 # at beginning of line, followed by space
  if current_char(lexer) != '#' { return false }
  let mut count = 0
  let mut i = lexer.pos
  while i < lexer.len && lexer.source.char_at(i) == '#' && count < 6 {
    count = count + 1
    i = i + 1
  }
  if count < 1 || count > 6 { return false }
  // Must be followed by space or end of line
  if i >= lexer.len { return false }
  let next_c = lexer.source.char_at(i)
  next_c == ' ' || next_c == '\t' || next_c == '\n'
}

fn is_thematic_break(lexer : Lexer) -> Bool {
  // Thematic break: *, -, or _ repeated 3+ times with optional spaces
  let c = current_char(lexer)
  if c != '*' && c != '-' && c != '_' { return false }
  let mut char_count = 0
  let mut space_ok = true
  let mut i = lexer.pos
  while i < lexer.len {
    let ch = lexer.source.char_at(i)
    if ch == '\n' || ch == '\r' { break }
    if ch == c { char_count = char_count + 1; space_ok = true }
    else if ch == ' ' || ch == '\t' { /* allow spaces between */ }
    else { return false }  // Other character breaks it
    i = i + 1
  }
  char_count >= 3
}

fn is_fenced_code_fence(lexer : Lexer) -> Bool {
  let c = current_char(lexer)
  if c != '`' && c != '~' { return false }
  let mut count = 0
  let mut i = lexer.pos
  while i < lexer.len && lexer.source.char_at(i) == c {
    count = count + 1
    i = i + 1
  }
  count >= 3
}

fn is_unordered_list_marker(lexer : Lexer) -> Bool {
  let c = current_char(lexer)
  if c != '-' && c != '*' && c != '+' { return false }
  // Must be followed by space or tab (or end of line)
  let next_c = peek_char(lexer)
  next_c == ' ' || next_c == '\t'
}

fn is_ordered_list_marker(lexer : Lexer) -> Bool {
  // Digit(s) followed by . or ) then space/tab
  if !is_digit(current_char(lexer)) { return false }
  let mut i = lexer.pos
  while i < lexer.len && is_digit(lexer.source.char_at(i)) { i = i + 1 }
  if i >= lexer.len { return false }
  let after_digits = lexer.source.char_at(i)
  if after_digits != '.' && after_digits != ')' { return false }
  // Must be followed by space or tab
  i = i + 1
  if i >= lexer.len { return false }
  let after_marker = lexer.source.char_at(i)
  after_marker == ' ' || after_marker == '\t'
}

fn is_digit(c : String) -> Bool {
  c >= "0" && c <= "9"
}

// ============================================================
// Scanner functions — each consumes input and returns a Token
// ============================================================

fn scan_atx_heading(ref lexer : Lexer) -> Token {
  let start_line = lexer.line
  let start_col = lexer.col
  let mut level = 0
  while current_char(lexer) == '#' && level < 6 {
    level = level + 1
    advance(ref lexer)
  }
  // Skip trailing spaces before content
  while current_char(lexer) == ' ' { advance(ref lexer) }
  // Consume rest of line as value
  let mut value = ""
  while lexer.pos < lexer.len && current_char(lexer) != "\n" {
    value = value + advance(ref lexer)
  }
  Token { ty: TokenType::ATXHeading, value: value, line: start_line, col: start_col }
}

fn scan_thematic_break(ref lexer : Lexer) -> Token {
  let start_line = lexer.line
  let start_col = lexer.col
  let mut value = ""
  while lexer.pos < lexer.len && current_char(lexer) != "\n" {
    value = value + advance(ref lexer)
  }
  Token { ty: TokenType::ThematicBreak, value: value, line: start_line, col: start_col }
}

fn scan_fenced_code_fence(ref lexer : Lexer) -> Token {
  let start_line = lexer.line
  let start_col = lexer.col
  let fence_char = current_char(lexer)
  let mut value = ""
  while lexer.pos < lexer.len && current_char(lexer) != "\n" {
    value = value + advance(ref lexer)
  }
  Token { ty: TokenType::FencedCodeFence, value: value, line: start_line, col: start_col }
}

fn scan_block_quote_prefix(ref lexer : Lexer) -> Token {
  let start_line = lexer.line
  let start_col = lexer.col
  advance(ref lexer)  // consume >
  // Optional space after >
  if current_char(lexer) == ' ' { advance(ref lexer) }
  Token { ty: TokenType::BlockQuotePrefix, value: ">", line: start_line, col: start_col }
}

fn scan_list_marker_unordered(ref lexer : Lexer) -> Token {
  let start_line = lexer.line
  let start_col = lexer.col
  let marker = advance(ref lexer)  // - * or +
  // Skip spaces after marker
  while current_char(lexer) == ' ' { advance(ref lexer) }
  Token { ty: TokenType::ListMarkerUnordered, value: marker, line: start_line, col: start_col }
}

fn scan_list_marker_ordered(ref lexer : Lexer) -> Token {
  let start_line = lexer.line
  let start_col = lexer.col
  let mut value = ""
  // Consume digits
  while is_digit(current_char(lexer)) {
    value = value + advance(ref lexer)
  }
  // Consume . or )
  value = value + advance(ref lexer)
  // Skip spaces after marker
  while current_char(lexer) == ' ' { advance(ref lexer) }
  Token { ty: TokenType::ListMarkerOrdered, value: value, line: start_line, col: start_col }
}

fn scan_plain_text_line(ref lexer : Lexer) -> Token {
  let start_line = lexer.line
  let start_col = lexer.col
  let mut value = ""
  while lexer.pos < lexer.len && current_char(lexer) != "\n" {
    value = value + advance(ref lexer)
  }
  Token { ty: TokenType::PlainText(value), value: value, line: start_line, col: start_col }
}
