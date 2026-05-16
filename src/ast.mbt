// MoonMark AST — Abstract Syntax Tree for CommonMark Markdown
// Based on CommonMark Spec v0.30: https://spec.commonmark.org/

// ============================================================
// Block-level nodes
// ============================================================

// Represents a full Markdown document (root node)
pub type Document {
  children : Array[Block]
}

// Block-level elements
pub enum Block {
  Heading(Heading)        // ATX headings: # ## ### etc.
  Paragraph(Paragraph)    // Plain text paragraph
  List(List)              // Ordered or unordered list
  CodeBlock(CodeBlock)    // Fenced or indented code block
  BlockQuote(BlockQuote)  // > blockquote
  ThematicBreak           // Horizontal rule: --- *** ___
  HTMLBlock(String)       // Raw HTML block
  // Table support planned for future
}

// Heading with level (1-6) and optional anchor ID
pub struct Heading {
  level : Int             // 1 = h1, ... 6 = h6
  content : Array[Inline] // Inline children
  attr : String?          // Optional {#id} attribute
}

// Paragraph containing inline elements
pub struct Paragraph {
  content : Array[Inline]
}

// Ordered or unordered list
pub enum ListKind { Unordered; Ordered(start_index : Int) }

pub struct ListItem {
  content : Array[Block]  // List items can contain blocks
  marker : String         // "-", "*", "1.", etc.
}

pub struct List {
  kind : ListKind
  tight : Bool            // Tight (<p>) vs loose spacing
  items : Array[ListItem]
}

// Code block (fenced or indented)
pub enum CodeBlockKind { Fenced(fence_char : String, info : String); Indented(indent : Int) }

pub struct CodeBlock {
  kind : CodeBlockKind
  code : String            // Raw code text
  language : String?       // Language identifier (for fenced)
}

// Block quote (> ...)
pub struct BlockQuote {
  content : Array[Block]
}

// ============================================================
// Inline-level nodes
// ============================================================

// Inline elements within blocks
pub enum Inline {
  Text(String)                    // Plain text
  Code(String)                    // Inline `code`
  Emph(Array[Inline])             // *emphasized* / _emphasized_
  Strong(Array[Inline])           // **strong** / __strong__
  StrongEmph(Array[Inline])       // ***strong+emph***
  HardBreak                      // Hard line break (two trailing spaces)
  SoftBreak                      // Soft line break (single newline)
  Image(ImageInfo)                // ![alt](url)
  Link(LinkInfo)                  // [text](url)
  HTMLInline(String)              // Raw inline HTML
  Strikethrough(Array[Inline])    // ~~deleted~~ (GFM extension)
}

// Image metadata
pub struct ImageInfo {
  alt : String
  url : String
  title : String?
}

// Link/hyperlink metadata
pub struct LinkInfo {
  text : Array[Inline]
  url : String
  title : String?
}
