fn main {
  let code = @cli.run_cli()
  process_exit(code)
}

extern "js" fn process_exit(code : Int) -> Unit =
  #| (code) => process.exit(code)
