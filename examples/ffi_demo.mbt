// FFI and interop examples for MoonHighlight grammar testing

extern "c" fn console_log(msg : String) -> Unit

extern "c" fn strlen(s : Bytes) -> Int

fn main {
  console_log("Hello from MoonBit!")
  let s = b"hello"
  let len = strlen(s)
  println(len)
}
