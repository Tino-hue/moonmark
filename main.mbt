///|
/// 读取 Node.js process.argv（跳过前两个元素：node 路径和脚本路径）
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
