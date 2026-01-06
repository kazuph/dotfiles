-- Keep Markdown links literal inside tmux panes
vim.opt_local.conceallevel = 0
vim.opt_local.concealcursor = ""

-- クリップボードから画像を貼り付け（<leader>i）
-- images/<記事名>/タイムスタンプ.png に保存し、マークダウンリンクを挿入
vim.keymap.set("n", "<leader>i", function()
  local file_path = vim.api.nvim_buf_get_name(0)
  if file_path == "" then
    vim.notify("ファイルを保存してから実行してください", vim.log.levels.WARN)
    return
  end

  -- 記事名を取得（拡張子なし）
  local file_name = vim.fn.fnamemodify(file_path, ":t:r")
  local cwd = vim.fn.getcwd()

  -- 保存先ディレクトリ: images/<記事名>/
  local img_dir = cwd .. "/images/" .. file_name
  vim.fn.mkdir(img_dir, "p")

  -- ファイル名: タイムスタンプ.png
  local timestamp = os.date("%Y%m%d-%H%M%S")
  local img_name = timestamp .. ".png"
  local img_path = img_dir .. "/" .. img_name

  -- pngpaste でクリップボードから画像を保存
  local result = vim.fn.system({ "pngpaste", img_path })
  if vim.v.shell_error ~= 0 then
    vim.notify("クリップボードに画像がありません\n(pngpaste が必要: brew install pngpaste)", vim.log.levels.ERROR)
    return
  end

  -- マークダウンリンクを挿入
  local md_link = string.format("![](/images/%s/%s)", file_name, img_name)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, { md_link })
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })

  vim.notify("画像を保存: " .. img_path, vim.log.levels.INFO)
end, { buffer = true, desc = "クリップボード画像を貼り付け" })
