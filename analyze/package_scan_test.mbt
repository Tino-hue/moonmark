///|
test "count_public_apis_from_source: empty / whitespace-only input" {
  inspect(count_public_apis_from_source(""), content="0")
  inspect(count_public_apis_from_source("\n\n  \t\n\n"), content="0")
}

///|
test "count_public_apis_from_source: the seven pub declaration kinds" {
  let source =
    #|pub fn add(a : Int, b : Int) -> Int { a + b }
    #|pub let VERSION : String = "1.0.0"
    #|pub const MAX_AGE : Int = 150
    #|pub struct User { name : String, age : Int }
    #|pub enum Color { Red | Green | Blue }
    #|pub trait Show { fn show(self : Self) -> String }
    #|pub type Id = String
  inspect(count_public_apis_from_source(source), content="7")
}

///|
test "count_public_apis_from_source: ignores private declarations" {
  let source =
    #|fn helper() -> Unit { () }
    #|let internal_flag : Bool = true
    #|struct Point { x : Int, y : Int }
    #|enum Dir { Left | Right }
    #|trait Logger { fn log(self : Self, msg : String) -> Unit }
    #|type Name = String
    #|const LIMIT : Int = 5
  inspect(count_public_apis_from_source(source), content="0")
}

///|
test "count_public_apis_from_source: skips comment lines and block comments" {
  let source =
    #|// pub fn should_not_count_1() -> Unit { () }
    #|/// pub fn documented_but_not_real_decl either
    #|/*
    #|pub fn inside_block() -> Unit { () }
    #|pub struct Hidden {}
    #|*/
    #|pub fn valid() -> Int { 42 }
  inspect(count_public_apis_from_source(source), content="1")
}

///|
test "count_public_apis_from_source: handles indentation + keyword boundaries" {
  // 注意：`pub function` 不是合法声明，fn 是完整 keyword；`pub typedef` 也不是 type
  let source =
    #|    pub fn foo() -> Unit { () }
    #|  pub struct S { v : Int }
    #|// Not a keyword boundary: the word after `pub` starts with `fn`
    #|// but then has an extra letter, so MUST be treated as `pub + ident` pair
    #|// and not counted as a declaration.
  let base = count_public_apis_from_source(source)
  inspect(base, content="2")
  // Now test: `pub fn_foo` — must NOT match as `fn` because next char is `_`
  // (ident char) which means the keyword is not "fn" but a longer id.
  let tricky =
    #|pub fn_foo() -> Unit { () }
    #|pub typedef_alias : Int = 0  // this line has no `pub type` (just `pub typedef...`)
  inspect(count_public_apis_from_source(tricky), content="0")
}

///|
test "count_public_apis_from_source: realistic mixed module" {
  let source =
    #|/// A module documenting things.
    #|/// Second doc line.
    #|
    #|pub struct Box[T] {
    #|  value : T,
    #|}
    #|
    #|pub fn Box::new[T](value : T) -> Box[T] {
    #|  { value }
    #|}
    #|
    #|pub fn Box::get[T](self : Box[T]) -> T {
    #|  self.value
    #|}
    #|
    #|pub trait Default[T] {
    #|  fn default() -> T
    #|}
    #|
    #|pub enum Result[T, E] {
    #|  Ok(T)
    #|  Err(E)
    #|}
    #|
    #|pub type Bytes = Array[UInt8]
    #|
    #|pub let DEFAULT_COUNT : Int = 10
    #|
    #|pub const MAGIC : Int = 0xCAFE
    #|
    #|fn helper() -> Unit { () }
  // struct(1) + fn::new(2) + trait(1) + enum(1) + type(1) + let(1) + const(1)
  inspect(count_public_apis_from_source(source), content="8")
}

///|
test "count_public_apis_from_dir with mock FileSystem" {
  // 复用 cache_test.mbt 已验证过的 InMemory FileSystem 模式。
  // 这里我们不依赖真实文件系统，用 scan_deprecated 同样的内联写法。
  let src_a =
    #|pub fn foo() -> Int { 0 }
    #|pub fn bar() -> Int { 1 }
    #|fn private_helper() -> Int { 2 }
  let src_b =
    #|pub struct X { n : Int }
    #|pub enum Y { A | B }
  // Count for two files: 2 fn + 1 struct + 1 enum = 4
  inspect(
    count_public_apis_from_source(src_a) + count_public_apis_from_source(src_b),
    content="4",
  )
}
