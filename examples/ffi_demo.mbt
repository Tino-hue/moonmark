// ============================================================
// MoonHighlight — FFI & Interop Example
// Demonstrates external function declarations and multi-backend
// ============================================================

package moonhighlight/ffi_demo

// JavaScript backend FFI
extern "js" fn console_log(msg : String) = "console.log"
extern "js" fn document_get_element(id : String) = "document.getElementById"
extern "js" fn window_alert(msg : String) = "window.alert"

// Wasm backend FFI
extern "wasm" fn memory_size() -> Int = "memory.size"
extern "wasm" fn memory_grow(pages : Int) -> Int = "memory.grow"

// C backend FFI (via auto-generated bindings)
extern "c" fn strlen(s : RawPtr) -> Int
extern "c" fn memcpy(dst : RawPtr, src : RawPtr, n : Int) -> RawPtr

// Multi-backend with different implementations
extern "js" fn get_timestamp() -> Int64 = "Date.now"
extern "wasm" fn get_timestamp() -> Int64 = "process_time"

// FFI usage in functions
pub fn log_and_return[T](value : T) -> T {
  let msg = $"Value: \{value}"
  console_log(msg)
  value
}

pub fn check_memory() -> (Int, Int) {
  let before = memory_size()
  let _ = memory_grow(1)
  let after = memory_size()
  (before, after)
}

// Struct with FFI methods
#[derive(Debug)]
pub struct ForeignResource {
  ptr : RawPtr
  size : Int
}

impl ForeignResource {
  pub fn new(ptr : RawPtr, size : Int) -> ForeignResource {
    { ptr: ptr, size: size }
  }

  pub fn copy_data(self) -> Array[Byte] {
    let buf = Array::new(self.size, b'\0')
    memcpy(buf.as_raw_ptr(), self.ptr, self.size)
    buf
  }

  pub fn is_empty(self) -> Bool {
    self.size == 0
  }
}
