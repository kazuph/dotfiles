-- ハイライト:
-- - 選択範囲を取り込み、ストリーミングなしでAIが返した差分を即座に適用するワークフロー。
-- - プロバイダ非依存のプロンプト仕様で、指定行だけを安全に置換させる。
-- - ステータスラインにプロバイダ別の実行数を出し、裏側の進行を見える化。
-- 機能:
-- - :Ai と互換コマンドが選択推定→意図入力→extmark付与→完了通知まで面倒を見る。
-- - Claude/Codex/Gemini CLIをspawn・出力後処理込みで切り替えられ、JSONレスポンスにも耐える。
-- - CRLFや末尾空行を除去してから差し替えるため、バッファのフォーマットを崩さない。
-- アーキテクチャ:
-- - begin_fix → start_job → apply_replacement間でctxテーブル（bufnr/range/prompt/provider）を受け渡し。
-- - providersテーブルがspawn/環境/後処理を記述するストラテジーパターン。
-- - extmarkで置換範囲を保持しつつジョブの非同期実行とstatus_cacheを同期。

-- このLuaモジュールはNeovim側で選択範囲を収集し、外部AI CLIに投げた出力をそのまま適用する精度重視の編集補助。
local M = {}

local ns = vim.api.nvim_create_namespace("AiCommand")
local jobs = {}
local job_seq = 0
local status_cache = ""

-- デフォルトのプロバイダは vim.g で上書きでき、このファイルを触らずに切り替えられる。
local config = {
  default_provider = vim.g.aibofix_default_provider or "claude",
}

local function notify(msg, level)
  vim.notify("[Ai] " .. msg, level or vim.log.levels.INFO, { title = "Ai" })
end

-- ビジュアル選択が無くてもカーソル行を対象にするフォールバックを用意。
local function current_line_range(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  return {
    start_row = row,
    start_col = 0,
    end_row = row,
    end_col = #line,
    fallback = true,
  }
end

-- Vimのマークを昇順の座標に正規化し、不正な値が来たらフォールバックさせる。
local function get_selection_range(bufnr)
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  if start_pos[2] == 0 or end_pos[2] == 0 then
    return current_line_range(bufnr)
  end

  local start_row = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_row = end_pos[2] - 1
  local end_col_inclusive = end_pos[3] - 1

  if end_row < start_row or (end_row == start_row and end_col_inclusive < start_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col_inclusive = end_col_inclusive, start_col
  end

  if start_row < 0 or end_row < 0 or start_col < 0 then
    return current_line_range(bufnr)
  end

  local end_line = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or ""
  local end_col = math.min(#end_line, end_col_inclusive + 1)

  if end_col < 0 then
    end_col = 0
  end

  start_col = math.max(0, start_col)

  return {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

-- 選択されたテキストをそのまま抜き出し、プロンプトと置換対象を正確に揃える。
local function extract_selection(bufnr, range)
  if range.start_row == range.end_row then
    local line = vim.api.nvim_buf_get_lines(bufnr, range.start_row, range.start_row + 1, false)[1] or ""
    return line:sub(range.start_col + 1, range.end_col)
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, range.start_row, range.end_row + 1, false)
  if #lines == 0 then
    return ""
  end
  lines[1] = lines[1]:sub(range.start_col + 1)
  lines[#lines] = lines[#lines]:sub(1, range.end_col)
  return table.concat(lines, "\n")
end

-- バッファ全体・選択範囲・ユーザー入力をまとめ、どのプロバイダでも同じ制約で動くプロンプトを生成。
local function build_prompt(ctx)
  local agent_name = ctx.provider_label or "AIアシスタント"
  local header = ([[あなたはNeovimから呼び出される%sです。以下のファイルのうち、指定範囲のみを編集対象にしてください。

ファイルパス: %s
バッファ全体:
```
%s
```

選択範囲 (行 %d-%d):
```
%s
```

Prompt:
%s

指示:
- 選択範囲に対する完成済みコードのみを返してください。
- Markdownのコードフェンスや説明文は返さないでください。
- シェルコマンドや外部ツールを実行せず、テキストによる回答だけを返してください。
- 置き換え後のテキストが空で良い場合は、何も出力しないでください。
]]):format(agent_name, ctx.display_path, ctx.full_text, ctx.range.start_row + 1, ctx.range.end_row + 1, ctx.selection_text, ctx.instruction)
  return header
end

-- CRLFや末尾改行を畳んでから適用し、余計な行差分を生まないようにする。
local function sanitize_output(output)
  local text = table.concat(output, "\n")
  text = text:gsub("\r", "")
  if text:sub(-1) == "\n" then
    text = text:sub(1, -2)
  end
  return text
end

local function apply_status(text)
  if text == status_cache and vim.g.aibofix_status == text then
    return
  end
  status_cache = text
  vim.g.aibofix_status = text
  vim.cmd("redrawstatus")
end

-- プロバイダごとの待機数を集計し、ステータスラインに裏で動くジョブを表示。
local function refresh_statusline()
  local counts = {}
  local total = 0
  for _, ctx in pairs(jobs) do
    local label = ctx.provider_label or ctx.provider_key or "AI"
    counts[label] = (counts[label] or 0) + 1
    total = total + 1
  end

  local text = ""
  if total > 0 then
    local segments = {}
    for label, count in pairs(counts) do
      table.insert(segments, string.format("%s:%d", label, count))
    end
    table.sort(segments)
    text = " Ai[" .. table.concat(segments, ",") .. "]"
  end

  apply_status(text)
end

local function ensure_status_cleared()
  if next(jobs) == nil then
    apply_status("")
  end
end

-- Gemini CLIはJSONを挟むログを吐くことがあるので、後方からJSONを探索し、無ければ整形済みstdoutで代用する。
local function parse_gemini_stdout(stdout)
  local lines = {}
  for _, line in ipairs(stdout) do
    if line and line ~= "" then
      table.insert(lines, line)
    end
  end

  local function concat_from(index)
    local chunk = {}
    for i = index, #lines do
      table.insert(chunk, lines[i])
    end
    return table.concat(chunk, "\n")
  end

  for i = #lines, 1, -1 do
    if lines[i]:match("^%s*{") then
      local chunk = concat_from(i)
      local ok, decoded = pcall(vim.json.decode, chunk)
      if ok and type(decoded) == "table" then
        if type(decoded.response) == "string" and decoded.response ~= "" then
          return decoded.response
        end
        if decoded.output and type(decoded.output.text) == "string" then
          return decoded.output.text
        end
      end
    end
  end

  return sanitize_output(stdout)
end

-- providersテーブルはストラテジーとして機能し、spawn方法と出力後処理を切り替える。
local providers = {
  claude = {
    label = "Claude Code",
    binary = "claude",
    spawn = function()
      return {
        cmd = { "claude", "--dangerously-skip-permissions", "--print", "--output-format", "text" },
        stdin = "pipe",
      }
    end,
    finalize = function(_, stdout)
      return sanitize_output(stdout)
    end,
  },
  codex = {
    label = "Codex",
    binary = "codex",
    spawn = function(ctx)
      local outfile = vim.fn.tempname()
      ctx.output_file = outfile
      return {
        cmd = { "codex", "exec", "--skip-git-repo-check", "-o", outfile, "-" },
        stdin = "pipe",
      }
    end,
    finalize = function(ctx, stdout)
      if ctx.output_file and vim.fn.filereadable(ctx.output_file) == 1 then
        local content = table.concat(vim.fn.readfile(ctx.output_file), "\n")
        vim.fn.delete(ctx.output_file)
        ctx.output_file = nil
        if content ~= "" then
          return content
        end
      end
      return sanitize_output(stdout)
    end,
  },
  gemini = {
    label = "Gemini",
    binary = "gemini",
    spawn = function()
      return {
        cmd = { "gemini", "--output-format", "json" },
        stdin = "pipe",
      }
    end,
    finalize = function(_, stdout)
      return parse_gemini_stdout(stdout)
    end,
  },
}

local function split_lines(text)
  if text == "" then
    return {}
  end
  return vim.split(text, "\n", { plain = true })
end

-- extmarkで元の選択範囲を保持し、応答待ちにバッファが動いても追従できるようにする。
local function get_mark_range(bufnr, mark_id)
  local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, { details = true })
  if not pos then
    return nil
  end
  local details = pos[3] or {}
  return {
    start_row = pos[1],
    start_col = pos[2],
    end_row = details.end_row or pos[1],
    end_col = details.end_col or pos[2],
  }
end

-- 追跡していた範囲をAI出力で置き換え、更新行を通知する。
local function apply_replacement(ctx, text)
  local range = get_mark_range(ctx.bufnr, ctx.mark_id)
  if not range then
    notify("適用範囲の特定に失敗しました。編集中に大きく変更された可能性があります。", vim.log.levels.WARN)
    return
  end
  local lines = split_lines(text)
  vim.api.nvim_buf_set_text(ctx.bufnr, range.start_row, range.start_col, range.end_row, range.end_col, lines)
  notify(
    string.format(
      "#%d: %s の行 %d-%d を更新しました。",
      ctx.seq,
      ctx.display_path,
      range.start_row + 1,
      range.end_row + 1
    )
  )
end

local function clear_mark(ctx)
  if ctx.mark_id and vim.api.nvim_buf_is_valid(ctx.bufnr) then
    pcall(vim.api.nvim_buf_del_extmark, ctx.bufnr, ns, ctx.mark_id)
  end
end

local function cleanup_job(job_id)
  local ctx = jobs[job_id]
  if not ctx then
    return
  end
  if ctx.output_file and vim.fn.filereadable(ctx.output_file) == 1 then
    vim.fn.delete(ctx.output_file)
    ctx.output_file = nil
  end
  jobs[job_id] = nil
  refresh_statusline()
end

local function list_providers()
  local keys = {}
  for name, provider in pairs(providers) do
    table.insert(keys, string.format("%s (%s)", name, provider.label))
  end
  table.sort(keys)
  return table.concat(keys, ", ")
end

local function ensure_provider(provider_key)
  local provider = providers[provider_key]
  if not provider then
    notify(
      string.format("プロバイダ %s は未対応です。利用可能: %s", provider_key, list_providers()),
      vim.log.levels.ERROR
    )
    return false
  end
  if provider.binary and vim.fn.executable(provider.binary) ~= 1 then
    notify(string.format("%s コマンドが見つかりませんでした。", provider.binary), vim.log.levels.ERROR)
    return false
  end
  return true
end

-- 外部CLIを起動してstdout/stderrを集め、終了後に結果を適用するメインワークフロー。
local function start_job(ctx, provider_key)
  local provider = providers[provider_key]
  if not provider then
    notify(string.format("プロバイダ %s は未定義です。", tostring(provider_key)), vim.log.levels.ERROR)
    clear_mark(ctx)
    return
  end

  if not ensure_provider(provider_key) then
    clear_mark(ctx)
    return
  end

  local spawn = provider.spawn(ctx)
  if not spawn or not spawn.cmd then
    notify(string.format("%s の起動設定に失敗しました。", provider.label), vim.log.levels.ERROR)
    clear_mark(ctx)
    return
  end

  local stdout = {}
  local stderr = {}

  local job_opts = {
    cwd = spawn.cwd or ctx.cwd,
    stdout_buffered = true,
    stderr_buffered = true,
  }

  if spawn.stdin == "pipe" then
    job_opts.stdin = "pipe"
  end
  if spawn.env then
    job_opts.env = spawn.env
  end

  local job_id = vim.fn.jobstart(spawn.cmd, vim.tbl_extend("force", job_opts, {
    on_stdout = function(_, data)
      if not data then
        return
      end
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(stdout, line)
        end
      end
    end,
    on_stderr = function(_, data)
      if not data then
        return
      end
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(stderr, line)
        end
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        local err_text = table.concat(stderr, "\n")
        local out_text = ""

        if code ~= 0 then
          if err_text == "" then
            err_text = string.format("%s コマンドが失敗しました。", provider.label)
          end
          notify(string.format("#%d (%s): %s", ctx.seq, provider.label, err_text), vim.log.levels.ERROR)
          cleanup_job(job_id)
          clear_mark(ctx)
          ensure_status_cleared()
          return
        end

        local ok, result = pcall(function()
          if provider.finalize then
            return provider.finalize(ctx, stdout, stderr)
          end
          return sanitize_output(stdout)
        end)
        if not ok then
          notify(string.format("#%d (%s): 出力解析に失敗しました。%s", ctx.seq, provider.label, result), vim.log.levels.ERROR)
          cleanup_job(job_id)
          clear_mark(ctx)
          return
        end
        out_text = result or ""

        local target_buf_valid = vim.api.nvim_buf_is_valid(ctx.bufnr)
        cleanup_job(job_id)

        if not target_buf_valid then
          notify(string.format("#%d (%s): 対象バッファが既に閉じられています。", ctx.seq, provider.label), vim.log.levels.WARN)
          clear_mark(ctx)
          ensure_status_cleared()
          return
        end

        apply_replacement(ctx, out_text)
        clear_mark(ctx)
        ensure_status_cleared()
      end)
    end,
  }))

  if job_id <= 0 then
    clear_mark(ctx)
    notify(string.format("%s のジョブ起動に失敗しました。", provider.label), vim.log.levels.ERROR)
    ensure_status_cleared()
    return
  end

  if spawn.stdin == "pipe" then
    vim.fn.chansend(job_id, ctx.prompt)
    vim.fn.chansend(job_id, "\n")
    vim.fn.chanclose(job_id, "stdin")
  end

  ctx.provider_key = provider_key
  jobs[job_id] = ctx
  refresh_statusline()

  notify(
    string.format(
      "#%d (%s): %s の行 %d-%d を送信しました。",
      ctx.seq,
      provider.label,
      ctx.display_path,
      ctx.range.start_row + 1,
      ctx.range.end_row + 1
    )
  )
end

local function parse_command_args(argline)
  if not argline or argline == "" then
    return nil, nil
  end
  local trimmed = vim.trim(argline)
  if trimmed == "" then
    return nil, ""
  end
  local first, rest = trimmed:match("^(%S+)%s*(.*)$")
  if first then
    local key = first:lower()
    if providers[key] then
      return key, rest
    end
  end
  return nil, trimmed
end

local function resolve_provider_key(explicit)
  if explicit and providers[explicit] then
    return explicit
  end
  local fallback = config.default_provider or "claude"
  fallback = fallback:lower()
  if providers[fallback] then
    return fallback
  end
  return "claude"
end

-- :Ai と互換コマンドの入口。引数を解釈し、選択範囲と指示を集めて start_job へ引き渡す。
local function begin_fix(opts)
  local provider_key_arg, inline_instruction = parse_command_args(opts.args or "")
  local provider_key = resolve_provider_key(provider_key_arg)
  local provider = providers[provider_key]
  if not provider then
    notify(string.format("利用可能なプロバイダが見つかりません。%s", list_providers()), vim.log.levels.ERROR)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local range = get_selection_range(bufnr)
  local selection_text = extract_selection(bufnr, range)
  local full_text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local display_path = bufname ~= "" and vim.fn.fnamemodify(bufname, ":~:.") or "[No Name]"
  local cwd = bufname ~= "" and vim.fn.fnamemodify(bufname, ":p:h") or vim.loop.cwd()

  local function launch(instruction)
    if not instruction or instruction:match("^%s*$") then
      notify("修正内容が入力されませんでした。", vim.log.levels.WARN)
      return
    end
    job_seq = job_seq + 1
    local mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, range.start_row, range.start_col, {
      end_row = range.end_row,
      end_col = range.end_col,
      hl_group = "Visual",
      hl_eol = true,
    })

    local ctx = {
      bufnr = bufnr,
      range = range,
      selection_text = selection_text,
      full_text = full_text,
      instruction = instruction,
      display_path = display_path,
      cwd = cwd,
      mark_id = mark_id,
      seq = job_seq,
      provider_label = provider.label or provider_key,
    }
    ctx.prompt = build_prompt(ctx)
    start_job(ctx, provider_key)
  end

  if inline_instruction and inline_instruction ~= "" then
    launch(inline_instruction)
    return
  end

  vim.ui.input({ prompt = string.format("Ai(%s) Prompt: ", provider.label) }, function(input)
    launch(input)
  end)
end

-- 公開APIのsetupはユーザーコマンド登録と設定マージだけを行う。
function M.setup(opts)
  if opts and type(opts) == "table" then
    config = vim.tbl_deep_extend("force", config, opts)
  end
  if config.default_provider then
    config.default_provider = config.default_provider:lower()
  end
  if M._setup_done then
    return
  end
  vim.api.nvim_create_user_command("Ai", begin_fix, {
    nargs = "*",
    range = true,
    desc = "選択範囲をAIで部分修正",
  })
  vim.api.nvim_create_user_command("AiFix", begin_fix, {
    nargs = "*",
    range = true,
    desc = "[互換用] AiFix コマンド",
  })
  M._setup_done = true
end

-- ステータスライン等がポーリングできるよう、未完了ジョブの有無を返す。
function M.has_pending()
  return next(jobs) ~= nil
end

-- ステータス表示を更新して、最新のキャッシュ文字列を返す。
function M.status()
  refresh_statusline()
  return status_cache
end

refresh_statusline()

return M
