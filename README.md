# MoonMark 🌙

**A CommonMark-compliant Markdown parser and HTML renderer written in [MoonBit](https://www.moonbitlang.cn/).**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- **CommonMark v0.30 compliant** — Follows the official CommonMark specification
- **Full block-level parsing** — Headings, paragraphs, lists, code blocks, blockquotes, thematic breaks
- **Rich inline support** — Emphasis, strong, links, images, inline code, strikethrough (GFM)
- **Safe HTML output** — Automatic escaping of special characters
- **AST access** — Parse to structured AST for custom processing pipelines
- **WASM-ready** — Compiled to WebAssembly for browser-side rendering

## 📦 Installation

```bash
# Add to your moon.mod.json dependencies:
# "moonmark": "https://github.com/Tino-hue/moonmark"
```

## 🚀 Quick Start

```moonbit
import moonmark

// One-call convenience API
let html = moonmark.markdown_to_html("# Hello, MoonBit!\n\nThis is **bold** and *italic*.")
// => <h1>Hello, MoonBit!</h1>\n<p>This is <strong>bold</strong> and <em>italic</em>.</p>\n

// Or parse to AST first
let doc = moonbit.parse("# Heading\n\nParagraph text")
// Access doc.children as Array[Block] for inspection/transformation
```

## 🏗 Architecture

MoonMark follows a classic 4-phase compilation pipeline:

```
Markdown Source → Lexer → Block Parser → Inline Parser → HTML Renderer
```

| Phase | Module | Input | Output |
|-------|--------|-------|--------|
| 1. Lexical Analysis | `src/lexer.mbt` | Markdown text | Token stream |
| 2. Block Parsing | `src/block_parser.mbt` | Tokens | Block-level AST |
| 3. Inline Parsing | `src/inline_parser.mbt` | Text content | Inline AST nodes |
| 4. HTML Rendering | `src/html_renderer.mbt` | AST | HTML string |

### Module Overview

- **`src/lib.mbt`** — Main entry point, re-exports all public APIs + `markdown_to_html()` convenience function
- **`src/ast.mbt`** — Abstract Syntax Tree type definitions (Block & Inline nodes)
- **`src/lexer.mbt`** — Tokenizer: converts Markdown source into typed tokens
- **`src/block_parser.mbt`** — Block parser: recognizes headings, lists, code blocks, etc.
- **`src/inline_parser.mbt`** — Inline parser: handles emphasis, links, images within blocks
- **`src/html_renderer.mbt`** — Renderer: converts AST to safe HTML output

## 🧪 Supported Syntax

### Block Elements

| Syntax | Description |
|--------|-------------|
| `# Heading` | ATX headings (H1–H6) |
| `---` / `***` / `___` | Thematic break (horizontal rule) |
| ``` `` ``` ``` | Fenced code blocks with language tag |
| `> Quote` | Block quotes |
| `- item` / `1. item` | Unordered / ordered lists |
| Plain text | Paragraphs |

### Inline Elements

| Syntax | Rendered As |
|--------|-------------|
| `*text*` / `_text_` | `<em>` emphasis |
| `**text**` / `__text__` | `<strong>` bold |
| `***text***` | `<strong><em>` both |
| `` `code` `` | `<code>` inline code |
| `[link](url)` | `<a href="...">` hyperlink |
| `![alt](url)` | `<img>` image |
| `~~text~~` | `<del>` strikethrough (GFM) |
| `\char` | Literal character (escape) |

## 📋 Roadmap

- [x] Phase 1: Lexer tokenization
- [x] Phase 2: Block-level parsing
- [x] Phase 3: Inline parsing
- [x] Phase 4: HTML renderer
- [ ] CommonMark spec test suite integration
- [ ] GFM table support
- [ ] Task list items (`- [ ]`)
- [ ] Footnotes
- [ ] Custom renderer interface (extensible output formats)
- [ ] `mooncakes.io` package publishing

## 📄 License

MIT License — see [LICENSE](LICENSE) file.

## 🙏 Acknowledgments

- [CommonMark Spec](https://spec.commonmark.org/) — The Markdown specification we follow
- [commonmark.js](https://github.com/commonmark/commonmark.js) — Reference implementation (JavaScript)
- [commonmark-hs](https://github.com/jgm/commonmark-hs) — Functional reference (Haskell)
- [MoonBit Team](https://www.moonbitlang.cn/) — The language and toolchain that made this possible

---

*MoonMark — Built with 🌙 MoonBit for the国产基础软件生态*
