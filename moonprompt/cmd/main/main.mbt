///|
fn parse_flag(args : Array[String], name : String, fallback~ : Int) -> Int {
  let mut i = 0
  while i + 1 < args.length() {
    if args[i] == name {
      return @strconv.parse_int(args[i + 1]) catch { _ => fallback }
    }
    i += 1
  }
  fallback
}

///|
fn main {
  let args = @sys.get_cli_args()
  let status = parse_flag(args, "--status", fallback=0)
  let duration_ms = parse_flag(args, "--duration", fallback=0)
  let rendered = @lib.render_from_runtime(status, duration_ms)
  let branch = rendered.branch.unwrap_or("")
  println(rendered.text + "::MOONPROMPT_BRANCH::" + branch)
}
