///|
test "render keeps current modules but looks lean" {
  let ctx : PromptContext = {
    user: "kazuph",
    host: "MacBook-Air",
    home: "/Users/kazuph",
    cwd: "/Users/kazuph/src/github.com/kazuph/moonprompt",
    status: 0,
    duration_ms: 2450,
    bun_version: Some("1.3.5"),
    python_version: Some("3.12.9"),
    virtual_env: None,
    aws_profile: Some("prod"),
  }
  let repo : RepoInfo? = Some({
    root: "/Users/kazuph/src/github.com/kazuph/moonprompt",
    branch: "main",
  })
  inspect(
    render(ctx, repo).text,
    content=(
      #|%F{240}╭─%f %F{214}kazuph%f%F{240}@%f%F{114}MacBook-Air%f %F{240}·%f %F{81}~/…/github.com/kazuph/moonprompt%f %F{240}·%f %F{245}git%f %F{183}main%f %F{240}·%f %F{179}aws prod%f %F{240}·%f %F{150}2.4s%f
      #|%F{240}╰─%f %F{76}❯%f 
    ),
  )
}

///|
test "render turns the arrow red on failure" {
  let ctx : PromptContext = {
    user: "kazuph",
    host: "MacBook-Air",
    home: "/Users/kazuph",
    cwd: "/Users/kazuph",
    status: 1,
    duration_ms: 0,
    bun_version: Some("1.3.5"),
    python_version: None,
    virtual_env: None,
    aws_profile: None,
  }
  let rendered = render(ctx, None)
  assert_true(rendered.text.contains("%F{203}❯%f"))
}
