// MoonMark Usage Examples
//
// This file demonstrates common usage patterns for the MoonMark library.
// Run with: moon run examples/usage.mbt

import moonmark { markdown_to_html, parse, render }
import moonmark.ast.{Document, Block, Heading, Paragraph}

fn main {
  println("🌙 MoonMark — Usage Examples\n")

  // ----------------------------------------------------------
  // Example 1: Basic Markdown to HTML conversion
  // ----------------------------------------------------------
  println("--- Example 1: Basic Conversion ---")
  let md = "# Hello, MoonBit!\n\nWelcome to **MoonMark**.\n\n- Item 1\n- Item 2"
  let html = markdown_to_html(md)
  println("Input:\n" + md)
  println("\nOutput HTML:")
  println(html)

  // ----------------------------------------------------------
  // Example 2: Parse to AST and inspect
  // ----------------------------------------------------------
  println("\n--- Example 2: AST Inspection ---")
  let doc = parse("# My Title\n\nSome content")
  println("Document has " + doc.children.length().to_string() + " top-level blocks:")
  for block in doc.children {
    match block {
      Block::Heading(h) => "  → Heading (level " + h.level.to_string() + ")"
      Block::Paragraph(p) => "  → Paragraph"
      _ => "  → Other block type"
    } |> println
  }

  // ----------------------------------------------------------
  // Example 3: Code highlighting placeholder
  // ----------------------------------------------------------
  println("\n--- Example 3: Fenced Code Block ---")
  let code_md = "```moonbit\nfn add(a : Int, b : Int) -> Int {\n  a + b\n}\n```"
  let code_html = markdown_to_html(code_md)
  println(code_html)

  // ----------------------------------------------------------
  // Example 4: Links and images
  // ----------------------------------------------------------
  println("\n--- Example 4: Rich Content ---")
  let rich_md = "Check out [MoonBit](https://moonbitlang.cn)!\n\n![Logo](logo.png)"
  let rich_html = markdown_to_html(rich_md)
  println(rich_html)

  println("\n✨ All examples completed!")
}
