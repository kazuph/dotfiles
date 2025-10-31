local map = vim.keymap.set

map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

map("n", "<leader>w", vim.cmd.write, { desc = "保存" })
map("n", "<leader>q", vim.cmd.quit, { desc = "ウィンドウを閉じる" })
map("n", "<leader>Q", vim.cmd.qall, { desc = "Neovimを終了" })

map("n", "<leader>fe", "<cmd>Neotree toggle<cr>", { desc = "ファイルツリー" })
map("n", "<leader>ff", function()
  require("telescope.builtin").find_files({ hidden = true })
end, { desc = "ファイル検索" })
map("n", "<leader>fg", function()
  require("telescope.builtin").live_grep()
end, { desc = "ライブgrep" })
map("n", "<leader>fb", function()
  require("telescope.builtin").buffers()
end, { desc = "バッファ一覧" })
map("n", "<leader>fh", function()
  require("telescope.builtin").help_tags()
end, { desc = "ヘルプ検索" })

map("n", "<leader>tn", "<cmd>ToggleTerm direction=float<cr>", { desc = "フロート端末" })
map("n", "<leader>ts", "<cmd>ToggleTerm size=15 direction=horizontal<cr>", { desc = "水平端末" })

local function toggle_linewise(count)
  require("Comment.api").toggle.linewise.current(count)
end

local function toggle_blockwise(count)
  require("Comment.api").toggle.blockwise.current(count)
end

map("n", "<leader>/", function()
  toggle_linewise()
end, { desc = "行コメント切替" })
map("v", "<leader>/", function()
  require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, { desc = "選択行コメント", silent = true })
map("n", "<leader>?", function()
  toggle_blockwise()
end, { desc = "ブロックコメント切替" })
map("v", "<leader>?", function()
  require("Comment.api").toggle.blockwise(vim.fn.visualmode())
end, { desc = "選択ブロックコメント", silent = true })

map("n", "<leader>rn", function()
  vim.lsp.buf.rename()
end, { desc = "名前変更" })
map("n", "<leader>ca", function()
  vim.lsp.buf.code_action()
end, { desc = "コードアクション" })

map("n", "<leader>fd", function()
  vim.diagnostic.open_float()
end, { desc = "行診断" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "前の診断" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "次の診断" })

map("n", "<leader>gb", function()
  require("gitsigns").toggle_current_line_blame()
end, { desc = "行 blame 切替" })
