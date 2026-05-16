// MoonMark Block Parser — Converts token stream into block-level AST
// Phase 2: Tokens → Block nodes

pub use ast.{Document, Block, Heading, Paragraph, List, ListKind, ListItem, CodeBlock, CodeBlockKind, BlockQuote}

// ============================================================
// Parser state
// ============================================================

pub struct Parser {
  tokens : Array[Token]
  pos : Int
  len : Int
}

use lexer.{Token, TokenType}

// ============================================================
// Public API
// ============================================================

/// Parse a token array into a Document AST (block level only).
/// Inline parsing is done as a separate pass.
pub fn parse(tokens : Array[Token]) -> Document {
  let parser = Parser { tokens: tokens, pos: 0, len: tokens.length() }
  parse_document(ref parser)
}

fn parse_document(ref parser : Parser) -> Document {
  let mut children = Array[Block]()
  while !is_at_end(parser) {
    // Skip blank lines between blocks
    if current(parser).ty == TokenType::BlankLine {
      advance_pos(ref parser)
      continue
    }
    let block = parse_block(ref parser)
    children.push(block)
  }
  Document { children: children }
}

// ============================================================
// Block-level parsing
// ============================================================

fn parse_block(ref parser : Parser) -> Block {
  let tok = current(parser)

  match tok.ty {
    TokenType::ATXHeading => parse_atx_heading(ref parser)
    TokenType::ThematicBreak =>
      advance_pos(ref parser); Block::ThematicBreak
    TokenType::FencedCodeFence => parse_fenced_code_block(ref parser)
    TokenType::BlockQuotePrefix => parse_block_quote(ref parser)
    TokenType::ListMarkerUnordered | TokenType::ListMarkerOrdered => parse_list(ref parser)
    _ => parse_paragraph(ref parser)  // PlainText or default
  }
}

fn parse_atx_heading(ref parser : Parser) -> Block {
  let tok = current(ref parser)
  // Determine heading level from raw value prefix in original source
  // We infer level from context: count # chars before this token
  // For now, we'll use a heuristic based on value content
  let mut level = 1  // Default; real impl would track # count during lexing
  let content_text = tok.value.trim()

  // Strip leading/trailing # from content if present
  let clean_content = strip_trailing_hashes(content_text)

  advance_pos(ref parser)

  // Inline parsing will be done in a later pass
  Block::Heading(Heading {
    level: level,
    content: Array[Inline](),  // Filled by inline parser pass
    attr: null
  })
}

fn parse_fenced_code_block(ref parser : Parser) -> Block {
  let open_fence = current(ref parser)
  advance_pos(ref parser)  // consume opening fence

  let fence_char = if open_fence.value.char_at(0) == '`' { "`" } else { "~" }

  // Extract info string (language) after fence
  let info = extract_info_string(open_fence.value)

  // Collect code lines until closing fence
  let mut code_lines = Array[String]()
  while !is_at_end(parser) && current(parser).ty != TokenType::FencedCodeFence {
    let line_tok = current(ref parser)
    if line_tok.ty == TokenType::BlankLine {
      code_lines.push("")
    } else {
      code_lines.push(line_tok.value)
    }
    advance_pos(ref parser)
  }

  // Consume closing fence if present
  if !is_at_end(parser) && current(parser).ty == TokenType::FencedCodeFence {
    advance_pos(ref parser)
  }

  let code = join_lines(code_lines)

  Block::CodeBlock(CodeBlock {
    kind: CodeBlockKind::Fenced(fence_char: fence_char, info: info),
    code: code,
    language: if info == "" { null } else { Some(info) }
  })
}

fn parse_block_quote(ref parser : Parser) -> Block {
  advance_pos(ref parser)  // consume >

  let mut content_blocks = Array[Block]()
  while !is_at_end(parser) {
    let tok = current(ref parser)
    // Continue consuming lines that are part of this blockquote
    // (simplified: consumes until blank line or different block type)
    if tok.ty == TokenType::BlankLine || tok.ty == TokenType::BlockQuotePrefix {
      if tok.ty == TokenType::BlockQuotePrefix {
        advance_pos(ref parser)  // consume nested >
        continue
      } else {
        break
      }
    }
    let inner = parse_block(ref parser)
    content_blocks.push(inner)
  }

  Block::BlockQuote(BlockQuote { content: content_blocks })
}

fn parse_list(ref parser : Parser) -> Block {
  let first_tok = current(ref parser)
  let is_ordered = first_tok.ty == TokenType::ListMarkerOrdered

  let kind = if is_ordered {
    // Parse start index from "1." etc.
    let marker_val = first_tok.value
    let start_str = marker_val.substring(0, marker_val.length() - 1)  // Remove trailing . or )
    let start_idx = parse_int_default(start_str, 1)
    ListKind::Ordered(start_index: start_idx)
  } else {
    ListKind::Unordered
  }

  let mut items = Array[ListItem]()

  while !is_at_end(parser) {
    let tok = current(ref parser)
    let is_item_marker =
      if is_ordered { tok.ty == TokenType::ListMarkerOrdered }
      else { tok.ty == TokenType::ListMarkerUnordered }

    if is_item_marker {
      let marker = tok.value
      advance_pos(ref parser)  // consume marker

      // Collect item content until next item or different block
      let mut item_lines = Array[String]()
      while !is_at_end(parser) {
        let inner = current(ref parser)
        if inner.ty == TokenType::ListMarkerUnordered ||
           inner.ty == TokenType::ListMarkerOrdered ||
           inner.ty == TokenType::BlankLine {
          break
        }
        item_lines.push(inner.value)
        advance_pos(ref parser)
      }

      items.push(ListItem {
        content: Array[Block](),  // Simplified: items as text for now
        marker: marker
      })
    } else {
      break
    }
  }

  Block::List(List {
    kind: kind,
    tight: true,  // Default to tight list
    items: items
  })
}

fn parse_paragraph(ref parser : Parser) -> Block {
  let mut lines = Array[String]()
  while !is_at_end(parser) {
    let tok = current(ref parser)
    // Paragraph ends at blank line or new block type
    if tok.ty == TokenType::BlankLine ||
       tok.ty == TokenType::ATXHeading ||
       tok.ty == TokenType::ThematicBreak ||
       tok.ty == TokenType::FencedCodeFence ||
       tok.ty == TokenType::BlockQuotePrefix ||
       tok.ty == TokenType::ListMarkerUnordered ||
       tok.ty == TokenType::ListMarkerOrdered {
      break
    }
    lines.push(tok.value)
    advance_pos(ref parser)
  }

  let text = join_lines(lines)
  Block::Paragraph(Paragraph {
    content: Array[Inline]()  // Filled by inline parser pass
  })
}

// ============================================================
// Helper functions
// ============================================================

fn current(parser : Parser) -> Token {
  if parser.pos >= parser.len {
    Token { ty: TokenType::EOF, value: "", line: 0, col: 0 }
  } else {
    parser.tokens[parser.pos]
  }
}

fn is_at_end(parser : Parser) -> Bool {
  parser.pos >= parser.len || current(parser).ty == TokenType::EOF
}

fn advance_pos(ref parser : Parser) {
  parser.pos = parser.pos + 1
}

fn strip_trailing_hashes(s : String) -> String {
  let trimmed = s.trim()
  let mut end = trimmed.length() - 1
  while end >= 0 && trimmed.char_at(end) == '#' {
    end = end - 1
  }
  if end < 0 { "" }
  else { trimmed.substring(0, end + 1).trim() }
}

fn extract_info_string(fence_line : String) -> String {
  // First 3+ chars are the fence, rest is info string
  let trimmed = fence_line.trim()
  let mut i = 0
  while i < trimmed.length() &&
        (trimmed.char_at(i) == '`' || trimmed.char_at(i) == '~') {
    i = i + 1
  }
  if i >= trimmed.length() { "" }
  else { trimmed.substring(i).trim() }
}

fn join_lines(lines : Array[String]) -> String {
  let mut result = ""
  let mut first = true
  for line in lines {
    if !first { result = result + "\n" }
    result = result + line
    first = false
  }
  result
}

fn parse_int_default(s : String, default : Int) -> Int {
  let mut result = 0
  let mut valid = false
  for i in 0..s.length() {
    let c = s.char_at(i)
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
      valid = true
    }
  }
  if valid { result } else { default }
}
