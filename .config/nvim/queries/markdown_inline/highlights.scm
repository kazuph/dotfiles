; Custom copy based on upstream nvim-treesitter query.
; Link-related conceals and OSC8 hyperlinks are disabled to keep tmux rendering stable.

(code_span) @markup.raw @nospell

(emphasis) @markup.italic

(strong_emphasis) @markup.strong

(strikethrough) @markup.strikethrough

(shortcut_link
  (link_text) @nospell)

[
  (backslash_escape)
  (hard_line_break)
] @string.escape

; Conceal codeblock and text style markers (keep upstream behavior)
([
  (code_span_delimiter)
  (emphasis_delimiter)
] @conceal
  (#set! conceal ""))

; Inline links keep their literal markup (no conceal, no OSC8 url property)
(inline_link
  [
    "["
    "]"
    "("
    (link_destination)
    ")"
  ] @markup.link)

(image
  [
    "!"
    "["
    "]"
    "("
    (link_destination)
    ")"
  ] @markup.link)

(full_reference_link
  [
    "["
    "]"
    (link_label)
  ] @markup.link)

(collapsed_reference_link
  [
    "["
    "]"
  ] @markup.link)

(shortcut_link
  [
    "["
    "]"
  ] @markup.link)

[
  (link_label)
  (link_text)
  (link_title)
  (image_description)
] @markup.link.label

[
  (link_destination)
  (uri_autolink)
  (email_autolink)
] @markup.link.url @nospell

(entity_reference) @nospell

; Replace common HTML entities.
((entity_reference) @character.special
  (#eq? @character.special "&nbsp;")
  (#set! conceal " "))

((entity_reference) @character.special
  (#eq? @character.special "&lt;")
  (#set! conceal "<"))

((entity_reference) @character.special
  (#eq? @character.special "&gt;")
  (#set! conceal ">"))

((entity_reference) @character.special
  (#eq? @character.special "&amp;")
  (#set! conceal "&"))

((entity_reference) @character.special
  (#eq? @character.special "&quot;")
  (#set! conceal "\""))

((entity_reference) @character.special
  (#any-of? @character.special "&ensp;" "&emsp;")
  (#set! conceal " "))
