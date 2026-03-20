// moonprompt - zsh prompt renderer (MoonBit script mode)
// Usage: moon run moonprompt.mbt --target native -- [options]
//
// Options (all passed from zsh wrapper):
//   --status N        last command exit code
//   --duration N      command duration in ms
//   --user NAME       username
//   --host NAME       hostname
//   --cwd PATH        current working directory
//   --home PATH       home directory
//   --branch NAME     git branch name (empty = not in repo)
//   --staged N        git staged file count
//   --modified N      git modified file count
//   --untracked N     git untracked file count
//   --stashed N       git stash count
//   --ahead N         commits ahead of remote
//   --behind N        commits behind remote

fn parse_str(args : Array[String], name : String, fallback~ : String) -> String {
  let mut i = 0
  while i + 1 < args.length() {
    if args[i] == name {
      return args[i + 1]
    }
    i += 1
  }
  fallback
}

fn parse_int(args : Array[String], name : String, fallback~ : Int) -> Int {
  let s = parse_str(args, name, fallback="")
  if s == "" {
    return fallback
  }
  @strconv.parse_int(s) catch { _ => fallback }
}

fn escape_prompt(text : String) -> String {
  let buf = StringBuilder::new()
  for ch in text {
    if ch == '%' {
      buf.write_string("%%")
    } else if ch == '\n' || ch == '\r' {
      buf.write_char(' ')
    } else {
      buf.write_char(ch)
    }
  }
  buf.to_string()
}

fn colored(color : Int, text : String) -> String {
  "%F{" + color.to_string() + "}" + text + "%f"
}

fn shorten_path(path : String, home : String) -> String {
  let pretty = if home.length() > 0 && path.has_prefix(home) {
    let rest = slice(path, home.length(), path.length())
    if rest.length() == 0 { "~" } else { "~" + rest }
  } else {
    path
  }
  let parts = split_path(pretty)
  if parts.length() <= 4 {
    pretty
  } else if parts[0] == "~" {
    "~/" + ".../" + join_tail(parts, 3)
  } else if pretty.has_prefix("/") {
    "/.../" + join_tail(parts, 3)
  } else {
    ".../" + join_tail(parts, 3)
  }
}

fn split_path(path : String) -> Array[String] {
  if path == "/" {
    return ["/"]
  }
  if path == "~" {
    return ["~"]
  }
  let parts : Array[String] = []
  let len = path.length()
  let mut start = 0
  if path.has_prefix("~/") {
    parts.push("~")
    start = 2
  } else if len > 0 && path[0] == '/' {
    start = 1
  }
  let mut i = start
  while i <= len {
    if i == len || path[i] == '/' {
      if i > start {
        parts.push(slice(path, start, i))
      } else if start == 0 && i == 0 {
        parts.push("/")
      }
      start = i + 1
    }
    i += 1
  }
  parts
}

fn join_tail(parts : Array[String], count : Int) -> String {
  let start = if parts.length() > count { parts.length() - count } else { 0 }
  let buf = StringBuilder::new()
  let mut i = start
  while i < parts.length() {
    if i > start {
      buf.write_string("/")
    }
    buf.write_string(parts[i])
    i += 1
  }
  buf.to_string()
}

fn format_duration(duration_ms : Int) -> String {
  if duration_ms < 10000 {
    let secs = duration_ms / 1000
    let tenth = duration_ms % 1000 / 100
    secs.to_string() + "." + tenth.to_string() + "s"
  } else if duration_ms < 60000 {
    (duration_ms / 1000).to_string() + "s"
  } else {
    let mins = duration_ms / 60000
    let secs = duration_ms % 60000 / 1000
    let pad = if secs < 10 { "0" } else { "" }
    mins.to_string() + "m" + pad + secs.to_string() + "s"
  }
}

fn render_git_status(
  staged : Int,
  modified : Int,
  untracked : Int,
  stashed : Int,
  ahead : Int,
  behind : Int,
) -> String {
  let buf = StringBuilder::new()
  if staged > 0 {
    buf.write_string(colored(76, "+" + staged.to_string()))
  }
  if modified > 0 {
    if buf.to_string().length() > 0 {
      buf.write_string(" ")
    }
    buf.write_string(colored(203, "!" + modified.to_string()))
  }
  if untracked > 0 {
    if buf.to_string().length() > 0 {
      buf.write_string(" ")
    }
    buf.write_string(colored(214, "?" + untracked.to_string()))
  }
  if stashed > 0 {
    if buf.to_string().length() > 0 {
      buf.write_string(" ")
    }
    buf.write_string(colored(81, "*" + stashed.to_string()))
  }
  if ahead > 0 || behind > 0 {
    if buf.to_string().length() > 0 {
      buf.write_string(" ")
    }
    if ahead > 0 {
      buf.write_string(colored(117, "^" + ahead.to_string()))
    }
    if ahead > 0 && behind > 0 {
      buf.write_string(" ")
    }
    if behind > 0 {
      buf.write_string(colored(179, "v" + behind.to_string()))
    }
  }
  buf.to_string()
}

fn slice(text : String, start : Int, end_ : Int) -> String {
  let buf = StringBuilder::new()
  let mut i = start
  while i < end_ && i < text.length() {
    buf.write_char(text[i].unsafe_to_char())
    i += 1
  }
  buf.to_string()
}

fn main {
  let args = @env.args()
  let status = parse_int(args, "--status", fallback=0)
  let duration_ms = parse_int(args, "--duration", fallback=0)
  let user = parse_str(args, "--user", fallback="user")
  let host = parse_str(args, "--host", fallback="host")
  let cwd = parse_str(args, "--cwd", fallback=".")
  let home = parse_str(args, "--home", fallback="")
  let branch = parse_str(args, "--branch", fallback="")
  let staged = parse_int(args, "--staged", fallback=0)
  let modified = parse_int(args, "--modified", fallback=0)
  let untracked = parse_int(args, "--untracked", fallback=0)
  let stashed = parse_int(args, "--stashed", fallback=0)
  let ahead = parse_int(args, "--ahead", fallback=0)
  let behind = parse_int(args, "--behind", fallback=0)

  let top = StringBuilder::new()
  top.write_string("%F{240}\u{256D}\u{2500}%f ")
  top.write_string(colored(214, escape_prompt(user)))
  top.write_string("%F{240}@%f")
  top.write_string(colored(114, escape_prompt(host)))
  top.write_string(" %F{240}\u{00B7}%f ")
  top.write_string(colored(81, escape_prompt(shorten_path(cwd, home))))

  if branch != "" {
    top.write_string(" %F{240}\u{00B7}%f ")
    top.write_string("%F{245}git%f ")
    top.write_string(colored(183, escape_prompt(branch)))
    let git_status = render_git_status(
      staged, modified, untracked, stashed, ahead, behind,
    )
    if git_status.length() > 0 {
      top.write_string(" [")
      top.write_string(git_status)
      top.write_string("]")
    }
  }

  if duration_ms >= 2000 {
    top.write_string(" %F{240}\u{00B7}%f ")
    top.write_string(colored(150, format_duration(duration_ms)))
  }

  let bottom = StringBuilder::new()
  bottom.write_string("%F{240}\u{2570}\u{2500}%f ")
  if status == 0 {
    bottom.write_string("%F{76}\u{276F}%f ")
  } else {
    bottom.write_string("%F{203}\u{276F}%f ")
  }

  // Output: prompt_text::MOONPROMPT_BRANCH::branch_name
  let text = top.to_string() + "\n" + bottom.to_string()
  println(text + "::MOONPROMPT_BRANCH::" + branch)
}
