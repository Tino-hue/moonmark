test "detect deprecated function" {
  let source =
    #|/// @deprecated since 0.1.0 Use new_fn instead
    #|pub fn old_fn() -> Unit {
    #|  // ...
    #|}
  let apis = scan_deprecated_apis(source)
  assert_eq(apis.length(), 1)
  assert_eq(apis[0].name, "old_fn")
  assert_eq(apis[0].since, Some("0.1.0"))
  assert_eq(apis[0].message, Some("Use new_fn instead"))
}

test "detect deprecated without since" {
  let source =
    #|/// @deprecated This function is obsolete
    #|fn obsolete() -> Int {
    #|  0
    #|}
  let apis = scan_deprecated_apis(source)
  assert_eq(apis.length(), 1)
  assert_eq(apis[0].name, "obsolete")
  assert_eq(apis[0].since, None)
  assert_eq(apis[0].message, Some("This function is obsolete"))
}

test "no deprecated in source" {
  let source =
    #|pub fn normal_fn() -> Unit {
    #|  ()
    #|}
  let apis = scan_deprecated_apis(source)
  assert_eq(apis.length(), 0)
}

test "detect deprecated let binding" {
  let source =
    #|/// @deprecated since 0.2.0
    #|pub let OLD_VALUE = 42
  let apis = scan_deprecated_apis(source)
  assert_eq(apis.length(), 1)
  assert_eq(apis[0].name, "OLD_VALUE")
  assert_eq(apis[0].since, Some("0.2.0"))
}

test "detect deprecated struct" {
  let source =
    #|/// @deprecated since 1.0.0 Use NewStruct
    #|pub struct OldStruct {
    #|  field : Int
    #|}
  let apis = scan_deprecated_apis(source)
  assert_eq(apis.length(), 1)
  assert_eq(apis[0].name, "OldStruct")
  assert_eq(apis[0].since, Some("1.0.0"))
  assert_eq(apis[0].message, Some("Use NewStruct"))
}

test "multiple deprecated apis" {
  let source =
    #|/// @deprecated since 0.1.0
    #|pub fn first() -> Unit {}
    #|
    #|/// @deprecated since 0.2.0
    #|pub fn second() -> Int { 0 }
  let apis = scan_deprecated_apis(source)
  assert_eq(apis.length(), 2)
  assert_eq(apis[0].name, "first")
  assert_eq(apis[1].name, "second")
}

test "deprecated const" {
  let source =
    #|/// @deprecated since 0.3.0
    #|pub const OLD_CONST = "value"
  let apis = scan_deprecated_apis(source)
  assert_eq(apis.length(), 1)
  assert_eq(apis[0].name, "OLD_CONST")
}

test "deprecated enum" {
  let source =
    #|/// @deprecated since 0.4.0
    #|pub enum OldEnum {
    #|  A
    #|  B
    #|}
  let apis = scan_deprecated_apis(source)
  assert_eq(apis.length(), 1)
  assert_eq(apis[0].name, "OldEnum")
}

test "deprecated trait" {
  let source =
    #|/// @deprecated since 0.5.0
    #|pub trait OldTrait {
    #|  fn method(self) -> Unit
    #|}
  let apis = scan_deprecated_apis(source)
  assert_eq(apis.length(), 1)
  assert_eq(apis[0].name, "OldTrait")
}
