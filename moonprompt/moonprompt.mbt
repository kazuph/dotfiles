///|
pub struct PromptContext {
  user : String
  host : String
  home : String
  cwd : String
  status : Int
  duration_ms : Int
  bun_version : String?
  python_version : String?
  virtual_env : String?
  aws_profile : String?
}

///|
pub struct RepoInfo {
  root : String
  branch : String
}

///|
pub struct RenderedPrompt {
  branch : String?
  text : String
}

///|
pub fn render_from_runtime(status : Int, duration_ms : Int) -> RenderedPrompt {
  let envs = @sys.get_env_vars()
  let cwd = match envs.get("PWD") {
    Some(path) => path
    None =>
      match @env.current_dir() {
        Some(path) => path
        None => "."
      }
  }
  let host = first_env(envs, ["MOONPROMPT_HOST", "HOST", "HOSTNAME"]).unwrap_or(
    "host",
  )
  let ctx : PromptContext = {
    user: env_value(envs, "USER", fallback="user"),
    host,
    home: env_value(envs, "HOME", fallback=""),
    cwd,
    status,
    duration_ms,
    bun_version: clean_env(envs, "MOONPROMPT_BUN_VERSION"),
    python_version: clean_env(envs, "MOONPROMPT_PY_VERSION"),
    virtual_env: clean_env(envs, "VIRTUAL_ENV"),
    aws_profile: first_env(envs, [
      "MOONPROMPT_AWS_PROFILE", "AWS_VAULT", "AWS_PROFILE", "AWS_DEFAULT_PROFILE",
    ]),
  }
  render(ctx, detect_repo(cwd))
}

///|
pub fn render(ctx : PromptContext, repo : RepoInfo?) -> RenderedPrompt {
  let top = StringBuilder::new()
  top.write_string("%F{240}╭─%f ")
  top.write_string(colored(214, escape_prompt(ctx.user)))
  top.write_string("%F{240}@%f")
  top.write_string(colored(114, escape_prompt(ctx.host)))
  top.write_string(" %F{240}·%f ")
  top.write_string(colored(81, escape_prompt(shorten_path(ctx.cwd, ctx.home))))

  match repo {
    Some(info) => {
      top.write_string(" %F{240}·%f ")
      top.write_string("%F{245}git%f ")
      top.write_string(colored(183, escape_prompt(info.branch)))
    }
    None => ()
  }

  if has_bun_marker(ctx.cwd, ctx.home, repo_root_of(repo)) {
    top.write_string(" %F{240}·%f ")
    top.write_string(colored(203, version_segment("bun", ctx.bun_version)))
  }

  if has_python_marker(ctx, repo_root_of(repo)) {
    top.write_string(" %F{240}·%f ")
    top.write_string(colored(222, version_segment("py", ctx.python_version)))
  }

  match ctx.aws_profile {
    Some(profile) => {
      top.write_string(" %F{240}·%f ")
      top.write_string(colored(179, "aws " + escape_prompt(profile)))
    }
    None => ()
  }

  if ctx.duration_ms >= 2000 {
    top.write_string(" %F{240}·%f ")
    top.write_string(colored(150, format_duration(ctx.duration_ms)))
  }

  let bottom = StringBuilder::new()
  bottom.write_string("%F{240}╰─%f ")
  if ctx.status == 0 {
    bottom.write_string("%F{76}❯%f ")
  } else {
    bottom.write_string("%F{203}❯%f ")
  }

  { branch: branch_of(repo), text: top.to_string() + "\n" + bottom.to_string() }
}

///|
fn repo_root_of(repo : RepoInfo?) -> String? {
  match repo {
    Some(info) => Some(info.root)
    None => None
  }
}

///|
fn branch_of(repo : RepoInfo?) -> String? {
  match repo {
    Some(info) => Some(info.branch)
    None => None
  }
}

///|
pub fn detect_repo(start : String) -> RepoInfo? {
  let mut current = start
  while current.length() > 0 {
    let dot_git = join_path(current, ".git")
    let git_dir = resolve_git_dir(current, dot_git)
    match git_dir {
      Some(dir) =>
        match read_git_branch(dir) {
          Some(branch) => return Some({ root: current, branch })
          None => return None
        }
      None => ()
    }
    let parent = parent_dir(current)
    if parent == current {
      break
    }
    current = parent
  }
  None
}

///|
fn env_value(
  envs : Map[String, String],
  key : String,
  fallback~ : String,
) -> String {
  match clean_env_value(envs.get(key)) {
    Some(value) => value
    None => fallback
  }
}

///|
fn clean_env(envs : Map[String, String], key : String) -> String? {
  clean_env_value(envs.get(key))
}

///|
fn clean_env_value(value : String?) -> String? {
  match value {
    Some(text) => if text.length() == 0 { None } else { Some(text) }
    None => None
  }
}

///|
fn first_env(envs : Map[String, String], keys : Array[String]) -> String? {
  for key in keys {
    match clean_env(envs, key) {
      Some(value) => return Some(value)
      None => ()
    }
  }
  None
}

///|
fn has_bun_marker(cwd : String, home : String, repo_root : String?) -> Bool {
  has_any_marker(cwd, home, repo_root, ["bun.lock", "bun.lockb", "bunfig.toml"])
}

///|
fn has_python_marker(ctx : PromptContext, repo_root : String?) -> Bool {
  match ctx.virtual_env {
    Some(_) => true
    None =>
      has_any_marker(ctx.cwd, ctx.home, repo_root, [
        ".python-version", "pyproject.toml", "requirements.txt", "Pipfile", "tox.ini",
        "setup.py", "__init__.py",
      ])
  }
}

///|
fn has_any_marker(
  cwd : String,
  home : String,
  repo_root : String?,
  names : Array[String],
) -> Bool {
  let mut current = cwd
  let stop = match repo_root {
    Some(root) => root
    None => if home.length() > 0 { home } else { "/" }
  }
  while true {
    for name in names {
      if @fs.path_exists(join_path(current, name)) {
        return true
      }
    }
    if current == stop {
      break
    }
    let parent = parent_dir(current)
    if parent == current {
      break
    }
    current = parent
  }
  false
}

///|
fn resolve_git_dir(root : String, dot_git : String) -> String? {
  if @fs.path_exists(join_path(dot_git, "HEAD")) {
    Some(dot_git)
  } else if @fs.path_exists(dot_git) {
    let content = @fs.read_file_to_string(dot_git) catch { _ => return None }
    parse_gitdir(root, trim_ascii(content))
  } else {
    None
  }
}

///|
fn parse_gitdir(root : String, content : String) -> String? {
  let prefix = "gitdir: "
  if !content.has_prefix(prefix) {
    None
  } else {
    let raw = slice(content, prefix.length(), content.length())
    if raw.has_prefix("/") {
      Some(raw)
    } else {
      Some(join_path(root, raw))
    }
  }
}

///|
fn read_git_branch(git_dir : String) -> String? {
  let head_path = join_path(git_dir, "HEAD")
  let head = @fs.read_file_to_string(head_path) catch { _ => return None }
  let cleaned = trim_ascii(head)
  let prefix = "ref: refs/heads/"
  if cleaned.has_prefix(prefix) {
    Some(slice(cleaned, prefix.length(), cleaned.length()))
  } else if cleaned.length() >= 7 {
    Some(slice(cleaned, 0, 7))
  } else {
    None
  }
}

///|
fn shorten_path(path : String, home : String) -> String {
  let pretty = if home.length() > 0 && path.has_prefix(home) {
    let rest = slice(path, home.length(), path.length())
    if rest.length() == 0 {
      "~"
    } else {
      "~" + rest
    }
  } else {
    path
  }
  let parts = split_path(pretty)
  if parts.length() <= 4 {
    pretty
  } else if parts[0] == "~" {
    "~/" + "…/" + join_tail(parts, 3)
  } else if pretty.has_prefix("/") {
    "/…/" + join_tail(parts, 3)
  } else {
    "…/" + join_tail(parts, 3)
  }
}

///|
fn split_path(path : String) -> Array[String] {
  if path == "/" {
    return ["/"]
  }
  if path == "~" {
    return ["~"]
  }
  let parts = Array::new()
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

///|
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

///|
fn parent_dir(path : String) -> String {
  if path == "/" || path == "~" {
    return path
  }
  let mut end_ = path.length()
  while end_ > 1 && path[end_ - 1] == '/' {
    end_ -= 1
  }
  let mut i = end_ - 1
  while i > 0 && path[i] != '/' {
    i -= 1
  }
  if i == 0 {
    if path[0] == '/' {
      "/"
    } else {
      "."
    }
  } else {
    slice(path, 0, i)
  }
}

///|
fn join_path(dir : String, name : String) -> String {
  if dir == "/" {
    "/" + name
  } else if dir.has_suffix("/") {
    dir + name
  } else {
    dir + "/" + name
  }
}

///|
fn version_segment(label : String, version : String?) -> String {
  match version {
    Some(value) => escape_prompt(label) + " " + escape_prompt(value)
    None => escape_prompt(label)
  }
}

///|
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
    mins.to_string() + "m" + zero_pad(secs) + "s"
  }
}

///|
fn zero_pad(value : Int) -> String {
  if value < 10 {
    "0" + value.to_string()
  } else {
    value.to_string()
  }
}

///|
fn colored(color : Int, text : String) -> String {
  "%F{" + color.to_string() + "}" + text + "%f"
}

///|
fn trim_ascii(text : String) -> String {
  let mut start = 0
  let mut end_ = text.length()
  while start < end_ && is_trim_char(text[start].to_int()) {
    start += 1
  }
  while end_ > start && is_trim_char(text[end_ - 1].to_int()) {
    end_ -= 1
  }
  slice(text, start, end_)
}

///|
fn is_trim_char(ch : Int) -> Bool {
  ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t'
}

///|
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

///|
fn slice(text : String, start : Int, end_ : Int) -> String {
  let buf = StringBuilder::new()
  let mut i = start
  while i < end_ {
    buf.write_char(text[i].unsafe_to_char())
    i += 1
  }
  buf.to_string()
}
