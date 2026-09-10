///|
/// 读取 Node.js process.argv（跳过前两个元素：node 路径和脚本路径）
/// 返回 FixedArray 以消除 W0020 弃用警告，随后转为 Array 用于内部处理。
extern "js" fn get_cli_args() -> FixedArray[String] =
  #| () => process.argv.slice(2)

///|
fn main {
  let args_fixed = get_cli_args()
  let args = Array::from_iter(args_fixed.iter())
  let code = if args.length() == 0 {
    @cli.run_cli()
  } else {
    @cli.run_cli_with_args(args)
  }
  set_exit_code(code)
}

///|
/// 设置进程退出码，让进程自然结束。
/// 相比 process.exit() 硬退出，这种方式允许事件循环中的
/// 待处理任务（如异步 I/O、定时器）正常完成后再退出。
extern "js" fn set_exit_code(code : Int) -> Unit =
  #| (code) => { process.exitCode = code; }
