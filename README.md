# MoonHighlight 🌙

**A Tree-sitter based syntax highlighting grammar for [MoonBit](https://www.moonbitlang.cn/) — supporting VSCode, Neovim, Helix, Zed and more.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tree-sitter](https://img.shields.io/badge/Tree--sitter-v0.23-blue.svg)](https://tree-sitter.github.io/tree-sitter/)

## ✨ Why MoonHighlight?

MoonBit is a statically typed, compile-to-WASM language with rich syntax features. Unfortunately, there's **no Tree-sitter grammar for MoonBit yet**, meaning:

- VSCode extension uses **TextMate** (regular expression based, less accurate)
- GitHub code views can't provide **proper semantic highlighting**
- Other editors (Neovim/Helix/Zed) have **no MoonBit support at all**

**MoonHighlight fills this gap** — with a real incremental parser and precise AST-based highlighting.

## 🎨 Highlighted Syntax Examples

### Semantic Differentiation

Unlike simple TextMate grammars, MoonHighlight distinguishes between:

```moonbit
pub fn calculate(a : Int, b : Int) -> Int {    // ✅ "fn" keyword, parameter "a/b", return type
  let result : Int = a + b                     // ✅ local variable, type annotation
  match result {                                // ✅ match keyword, variable
    0 => fail("zero division")                 // ✅ literal pattern, function call
    _ => result                                // ✅ wildcard pattern
  }
}
```

### Async Functions

```moonbit
async fn fetch_data(url : String) -> String {  // ✅ async function with special style
  let (resp, body) = @http.get(url)            // ✅ destructuring
  guard resp.code is (200..<300) else {
    fail("bad response")
  }
  body.text()                                  // ✅ method call chaining
}
```

### String Interpolation

```moonbit
let msg = "The answer is \{x + y}"             // ✅ interpolated expressions inside strings
let poem =
  #| MoonBit rocks                          // ✅ raw multi-line string
  #| Built with care
```

### Error Handling

```moonbit
try parse_json(input) catch {                  // ✅ try/catch with special colors
  JsonError(msg) => println(msg)               // ✅ pattern matching on error types
  _ => fail("unknown error")
}
```

## 📦 Installation

> ⚠️ **Coming soon** — grammar development in progress.

Once published, you'll be able to install via your editor's marketplace.

```bash
# Neovim (nvim-treesitter)
:TSInstall moonhighlight

# Helix (languages.toml)
language-server = { command = "tree-sitter", args = ["highlight", "--scope", "moonbit"] }
```

## 🏗 Architecture

MoonHighlight follows Tree-sitter's standard grammar structure:

```
Grammar definition (grammar.js)
    │
    ▼
tree-sitter generate  →  src/parser.c  +  src/parser.h
    │
    ▼
tree-sitter test     →  corpus/       (MoonBit test files)
    │
    ▼
Editor bindings     →  VSCode / Neovim / Helix / Zed
```

### Module Overview

| Module | Purpose |
|--------|---------|
| `grammar.js` | Tree-sitter grammar rules for all MoonBit syntax |
| `src/parser.c` | Auto-generated C parser (do not edit manually) |
| `src/parser.h` | Auto-generated header |
| `corpus/` | Test files covering all MoonBit syntax constructs |
| `queries/highlights.scm` | Tree-sitter highlighting query definitions |

### Supported Syntax

#### Keywords & Declarations

| Token | Example |
|-------|---------|
| `fn` | `pub fn add(a, b) -> Int` |
| `let` / `const` | `let x = 42` / `const PI = 3.14` |
| `struct` / `enum` / `type` | Type definitions |
| `trait` / `impl` | Trait system |
| `pub` / `priv` | Visibility modifiers |
| `async` | `async fn main()` |
| `raise` / `try` / `catch` | Error handling |
| `guard` | `guard x is Some(v) else { ... }` |
| `#attribute` | `#deprecated`, `#cfg`, custom attributes |

#### Literals & Types

| Category | Examples |
|----------|----------|
| Integers | `42`, `0xFF`, `0b1010`, `1_000_000`, `42U`, `100L` |
| Floats | `3.14`, `0x1.2P3` |
| Strings | `"hello"`, `#|raw\ntext|#`, `$|interpolated|{x}|` |
| Chars | `'A'`, `'兔'`, `'\u{30}'` |
| Bytes | `b'a'`, `b"hello"`, `b'\xff'` |
| Arrays | `[1, 2, 3]`, `FixedArray::make(10, 0)` |
| Option/Result | `Some(x)`, `None`, `Ok(v)`, `Err(e)` |
| Generic types | `Array[Int]`, `Option[T]` |

#### Control Flow

```moonbit
if condition { ... } else { ... }
match value {
  Pattern => expr
  _ => default
}
guard value is Pattern else { ... }
while cond { ... }
for item in collection { ... }
for i in 0..<10 { ... }
```

## 🎯 Roadmap

- [ ] Phase 1: Lexer — keywords, identifiers, literals (numbers, strings, chars)
- [ ] Phase 2: Declarations — fn/let/const/type/struct/enum/trait/impl
- [ ] Phase 3: Expressions — operators, function calls, method calls
- [ ] Phase 4: Control flow — if/match/guard/while/for
- [ ] Phase 5: Patterns — constructor/ wildcard/ guarded patterns
- [ ] Phase 6: Types — generics, constraints, function types
- [ ] Phase 7: Attributes — all built-in + custom attributes
- [ ] Phase 8: Error handling — raise/try/catch/try?
- [ ] Phase 9: Async — async fn / await / task groups
- [ ] Phase 10: String interpolation — nested expression parsing
- [ ] Phase 11: FFI — extern declarations, #external type
- [ ] Phase 12: VSCode extension integration
- [ ] Phase 13: Color themes (dark/light)
- [ ] Phase 14: Test corpus — all official docs examples
- [ ] Phase 15: Neovim/Helix/Zed bindings

## 📄 License

MIT License — see [LICENSE](LICENSE) file.

## 🙏 Acknowledgments

- [Tree-sitter](https://tree-sitter.github.io/tree-sitter/) — The incremental parsing system
- [tree-sitter-rust](https://github.com/tree-sitter/tree-sitter-rust) — Best reference grammar
- [tree-sitter-ocaml](https://github.com/tree-sitter/tree-sitter-ocaml) — Pattern matching reference
- [tree-sitter-swift](https://github.com/alex-pinkus/tree-sitter-swift) — if/let/guard reference
- [MoonBit Team](https://www.moonbitlang.cn/) — The language and toolchain

---

*MoonHighlight — Built with 🌙 MoonBit for the 国产基础软件生态*