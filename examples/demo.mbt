// ============================================================
// MoonHighlight Demo — Showcase all syntax features
// This file demonstrates every highlightable construct
// ============================================================

package moonhighlight/demo

import moonbit/core/println
import moonbit/core/int as Int

/// A 2D point with generic coordinates
#[derive(Debug, Show, Eq)]
pub struct Point[T] {
  x : T
  y : T
}

impl Point[Int] {
  /// Calculate distance from origin
  pub fn distance(self) -> Double {
    let dx = self.x.to_double()
    let dy = self.y.to_double()
    (dx * dx + dy * dy).sqrt()
  }

  pub fn translate(self, dx : Int, dy : Int) -> Point[Int] {
    Point::new { x: self.x + dx, y: self.y + dy }
  }
}

/// Color enum with RGB variant
pub enum Color {
  Red
  Green
  Blue
  Rgb(Int, Int, Int)
  Hex(String)
}

trait Display with Show as S {
  fn to_string(self) -> String
  fn display(self) -> Unit { println(self.to_string()) }
}

/// Parse a JSON string into structured data
#[inline]
fn parse_json(input : String) -> Result[JsonNode, JsonError] {
  try do_parse(input) catch {
    JsonError(msg) => Err(JsonError("parse failed: " + msg))
    _ => raise("unexpected error")
  }
}

/// Async HTTP request handler
async fn fetch_data(url : String) -> Result[String, Error] {
  let (resp, body) = @http.get(url)
  guard resp.code is (200..<300) else {
    return Err(Error("HTTP " + resp.code.to_string()))
  }

  // String interpolation example
  let msg = $"Fetched \{body.length()} bytes from \{url}"

  // Raw multi-line string
  let html = #|
<div class="result">
  <p>\{msg}</p>
</div>
|#

  Ok(html)
}

// Pattern matching showcase
fn process_color(c : Color) -> String {
  match c {
    Red => "#FF0000"
    Green => "#00FF00"
    Blue => "#0000FF"
    Rgb(r, g, b) => $"rgb(\{r},\{g},\{b})"
    Hex(s) => s
  }
}

// Guard expression
fn unwrap[T](opt : Option[T], default : T) -> T {
  guard opt is Some(v) else { default }
  v
}

// For loop with range
fn count_down(n : Int) -> Array[Int] {
  let result = Array::new()
  for i in n..>0 {
    result.push(i)
  }
  result
}

// Closure and pipeline
fn pipeline_demo(arr : Array[Int]) -> Int {
  arr
    |> filter(fn(x) { x > 0 })
    |> map(fn(x) { x * 2 })
    |> sum
}

// Byte literals
let newline = b'\n'
let header = b"Content-Type: application/json"

// Suberror types
pub suberror JsonError {
  InvalidSyntax(String)
  UnexpectedToken(Char)
  IoError(String)
}

// Defer for cleanup
fn with_resource[T](r : Resource, f : (Resource) -> T) -> T {
  defer r.close()
  f(r)
}

// Type alias
pub type Callback[T] = (T) -> Unit
pub type Predicate[T] = (T) -> Bool

// External FFI declaration
extern "js" fn console_log(msg : String) = "console.log"

// Deprecated API
#[deprecated(since="0.2", message="use fetch_data instead")]
#[cfg(target="wasm")]
pub fn old_fetch(url : String) -> String {
  "legacy implementation"
}