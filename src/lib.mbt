// MoonMark — CommonMark-compliant Markdown Parser & HTML Renderer for MoonBit
//
// This is the main library entry point. It re-exports all public APIs
// from sub-modules and provides a convenience function for one-call parsing.
//
// Usage:
//   import moonmark
//   let html = moonmark.markdown_to_html("# Hello, MoonBit!")
//   // => "<h1>Hello, MoonBit!</h1>\n"

pub use ast {
  Document, Block, Heading, Paragraph,
  List, ListKind, ListItem, CodeBlock, CodeBlockKind, BlockQuote,
  Inline, Text, Code, Emph, Strong, StrongEmph,
  HardBreak, SoftBreak, Image, ImageInfo, Link, LinkInfo,
  HTMLInline, Strikethrough
}

pub use lexer.{Lexer, Token, TokenType, new as new_lexer, tokenize}
pub use block_parser.{Parser as BlockParser, parse as parse_blocks}
pub use inline_parser.{InlineParser, parse_inline}
pub use html_renderer {
  render, render_block, render_inline,
  escape_html, escape_html_attr
}

// ============================================================
// Convenience API: One-call parse + render
// ============================================================

/// Parse a Markdown string and return the rendered HTML.
/// This is the primary entry point for most users.
///
/// # Example
/// ```
/// let html = markdown_to_html("# Hello\n\nWorld")
/// // html == "<h1>Hello</h1>\n<p>World</p>\n"
/// ```
pub fn markdown_to_html(source : String) -> String {
  // Phase 1: Lexical analysis (source → tokens)
  let lexer = new_lexer(source)
  let tokens = tokenize(lexer)

  // Phase 2: Block-level parsing (tokens → block AST)
  let doc = parse_blocks(tokens)

  // Phase 3: Inline parsing is embedded in block parser for now
  // TODO: Run inline_parser on text content of each block

  // Phase 4: Render to HTML
  render(doc)
}

/// Parse Markdown into a Document AST without rendering.
/// Useful when you need to inspect or transform the AST.
pub fn parse(source : String) -> Document {
  let lexer = new_lexer(source)
  let tokens = tokenize(lexer)
  parse_blocks(tokens)
}
