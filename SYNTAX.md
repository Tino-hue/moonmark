# MoonBit 语法速查表

> MoonHighlight 项目配套的语法参考，用于验证 grammar 覆盖完整性。

## 声明

```moonbit
// 函数
pub fn name(param : Type) -> ReturnType { body }

// 异步函数
async fn fetch(url : String) -> Result[String, Error] { ... }

// 变量绑定
let x : Int = 42
mut counter : Int = 0
const PI : Double = 3.14159

// 结构体
#[derive(Debug, Show)]
pub struct Point[T] {
  x : T
  y : T
}

// 枚举
pub enum Color { Red; Green; Blue; Rgb(Int, Int, Int) }

// 特征
trait Display with Show as S {
  fn to_string(self) -> String
}

// 实现
impl Point[Int] {
  pub fn distance(self) -> Double { ... }
}

// 类型别名
pub type Callback[T] = (T) -> Unit

// 子错误
pub suberror JsonError {
  InvalidSyntax(String)
  UnexpectedToken(Char)
}
```

## 表达式

```moonbit
// 字面量
42            // Int
3.14          // Double
"hello"       // String
'b'           //Char
true / false  // Bool
()            // Unit
(1, 2, 3)     // Tuple

// 字符串
$"interpolate \{expr}"
#|raw string|#
b'byte'       // Byte literal
b"bytes"      // Bytes literal

// 运算符
+ - * / %     // 算术
== != < > <= >=  // 比较
&& || !       // 逻辑
|>            // 管道

// 调用
func(arg1, arg2)
obj::method(args)
Type::Constructor(payload)

// 控制流
if cond { a } else { b }
match expr { pattern => value }
guard opt is Some(v) else { fallback }
loop { ... break value }
for i in 0..<10 { ... }

// 错误处理
try risky() catch { Err(e) => handle(e) }
raise("error")
defer cleanup()

// 闭包
fn(x : Int) -> Int { x * 2 }

// 结构体表达式
Point::new { x: 10, y: 20 }
{ ..base, y: 30 }  // with spread
```

## 模式匹配

```moonbit
match result {
  Ok(value) => value
  Err(msg) => { println(msg); -1 }
  _ => default_value
}

// Guard + 模式
guard response is Some(data) else {
  raise("no data")
}
```

## 导入与包

```moonbit
package myapp/core

import moonbit/core/vec
import moonbit/core/io as IO
import moonbit/core/str as Str { to_int }
```

## 属性

```moonbit
#[inline]
#[deprecated(since="0.2", message="use new_api")]
#[derive(Debug, Show, Eq)]
#[cfg(target="wasm")]
```

## FFI

```moonbit
extern "js" fn console_log(msg : String) = "console.log"
extern "wasm" fn memory_size() -> Int = "memory.size"
extern "c" fn strlen(s : RawPtr) -> Int
```
