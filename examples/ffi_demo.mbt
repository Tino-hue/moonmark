// FFI and interop examples for MoonHighlight grammar testing

extern "js" fn console_log(msg : String) = "console.log"
extern "wasm" fn memory_size() -> Int = "memory.size"
extern "c" fn strlen(s : RawPtr) -> Int

pub fn main() -> Unit {
  console_log("Hello from MoonBit!")
  let size = memory_size()
  println(size)
}
