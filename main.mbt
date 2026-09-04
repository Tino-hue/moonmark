///|
/// 读取 Node.js process.argv（跳过前两个元素：node 路径和脚本路径）
/// 注：此处 extern 返回 Array[String] 会触发 W0020 弃用警告。
/// 目前通过 moon.mod warnings="-0020" 抑制该警告；原因是 FixedArray + Option
/// 在 MoonBit 与 FileSystem 结构体字段互操作时存在语义问题，待工具链演进后再迁移。
extern "js" fn get_cli_args() -> Array[String] =
  #| () => process.argv.slice(2)

///|
fn main {
  let args = get_cli_args()
  let code = if args.length() == 0 {
    @cli.run_cli()
  } else {
    @cli.run_cli_with_args(args)
  }
  process_exit(code)
}

///|
extern "js" fn process_exit(code : Int) -> Unit =
  #| (code) => process.exit(code)
