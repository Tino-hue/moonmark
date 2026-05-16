// MoonMark HTML Renderer — Renders AST to HTML string
// Phase 4: AST → HTML output

pub use ast.{Document, Block, Heading, Paragraph, List, ListKind,
              ListItem, CodeBlock, CodeBlockKind, BlockQuote}
pub use ast.{Inline, Text, Code, Emph, Strong, StrongEmph,
              HardBreak, SoftBreak, Image, ImageInfo, Link, LinkInfo,
              HTMLInline, Strikethrough}

// ============================================================
// Public API
// ============================================================

/// Render a full Document AST to an HTML string.
pub fn render(doc : Document) -> String {
  let mut html = ""
  for block in doc.children {
    html = html + render_block(block)
  }
  html
}

/// Render a single block node to HTML.
pub fn render_block(block : Block) -> String {
  match block {
    Block::Heading(h) => render_heading(h)
    Block::Paragraph(p) => render_paragraph(p)
    Block::List(l) => render_list(l)
    Block::CodeBlock(cb) => render_code_block(cb)
    Block::BlockQuote(bq) => render_block_quote(bq)
    Block::ThematicBreak => "<hr />\n"
    Block::HTMLBlock(raw) => raw + "\n"
  }
}

/// Render inline nodes to HTML.
pub fn render_inline(inlines : Array[Inline]) -> String {
  let mut html = ""
  for node in inlines {
    html = html + render_inline_node(node)
  }
  html
}

// ============================================================
// Block-level rendering
// ============================================================

fn render_heading(h : Heading) -> String {
  let tag = "h" + h.level.to_string()
  let content = render_inline(h.content)
  let attr_str = match h.attr {
    Some(id) => " id=\"" + id + "\"",
    None => ""
  }
  "<" + tag + attr_str + ">" + content + "</" + tag + ">\n"
}

fn render_paragraph(p : Paragraph) -> String {
  let content = render_inline(p.content)
  "<p>" + content + "</p>\n"
}

fn render_list(l : List) -> String {
  let (open_tag, close_tag) = match l.kind {
    ListKind::Unordered => ("<ul>\n", "</ul>\n")
    ListKind::Ordered(start) =>
      ("<ol start=\"" + start.to_string() + "\">\n", "</ol>\n")
  }

  let mut body = ""
  for item in l.items {
    body = body + render_list_item(item, l.tight)
  }

  open_tag + body + close_tag
}

fn render_list_item(item : ListItem, tight : Bool) -> String {
  let mut inner = ""
  // If item has block children, render them
  if item.content.length() > 0 {
    for block in item.content {
      inner = inner + render_block(block)
    }
  }

  if tight || inner == "" {
    "<li>" + inner.trim() + "</li>\n"
  } else {
    "<li>\n" + inner + "</li>\n"
  }
}

fn render_code_block(cb : CodeBlock) -> String {
  let escaped = escape_html(cb.code)

  match cb.kind {
    CodeBlockKind::Fenced(fence_char, info) => {
      let lang_class = match cb.language {
        Some(lang) => " class=\"language-" + lang + "\"",
        None => ""
      }
      "<pre><code" + lang_class + ">" + escaped + "</code></pre>\n"
    }
    CodeBlockKind::Indented(indent) => {
      "<pre><code>" + escaped + "</code></pre>\n"
    }
  }
}

fn render_block_quote(bq : BlockQuote) -> String {
  let mut inner = ""
  for block in bq.content {
    inner = inner + render_block(block)
  }
  "<blockquote>\n" + inner + "</blockquote>\n"
}

// ============================================================
// Inline-level rendering
// ============================================================

fn render_inline_node(node : Inline) -> String {
  match node {
    Inline::Text(t) => escape_html(t)
    Inline::Code(c) => "<code>" + escape_html(c) + "</code>"
    Inline::Emph(children) => "<em>" + render_inline(children) + "</em>"
    Inline::Strong(children) => "<strong>" + render_inline(children) + "</strong>"
    Inline::StrongEmph(children) => "<strong><em>" + render_inline(children) + "</em></strong>"
    Inline::HardBreak => "<br />\n"
    Inline::SoftBreak => "\n"
    Inline::Image(img) => render_image(img)
    Inline::Link(link) => render_link(link)
    Inline::HTMLInline(raw) => raw
    Inline::Strikethrough(children) => "<del>" + render_inline(children) + "</del>"
  }
}

fn render_image(img : ImageInfo) -> String {
  let alt = escape_html(img.alt)
  let src_attr = " src=\"" + escape_html_attr(img.url) + "\""
  let alt_attr = " alt=\"" + alt + "\""
  let title_attr = match img.title {
    Some(t) => " title=\"" + escape_html_attr(t) + "\"",
    None => ""
  }
  "<img" + src_attr + alt_attr + title_attr + " />"
}

fn render_link(link : LinkInfo) -> String {
  let href = " href=\"" + escape_html_attr(link.url) + "\""
  let title_attr = match link.title {
    Some(t) => " title=\"" + escape_html_attr(t) + "\"",
    None => ""
  }
  let content = render_inline(link.text)
  "<a" + href + title_attr + ">" + content + "</a>"
}

// ============================================================
// HTML escaping utilities
// ============================================================

/// Escape HTML special characters in text content (& < >).
pub fn escape_html(s : String) -> String {
  let mut result = ""
  for i in 0..s.length() {
    let c = s.char_at(i)
    result = result + match c {
      '&' => "&amp;"
      '<' => "&lt;"
      '>' => "&gt;"
      '"' => "&quot;"
      '\'' => "&#39;"
      _ => c.to_string()
    }
  }
  result
}

/// Escape HTML attribute values (also escapes quotes).
pub fn escape_html_attr(s : String) -> String {
  escape_html(s)
}
