local map = vim.keymap.set

local function telescope_builtin(func, opts)
  return function()
    require("lazy").load({ plugins = { "telescope.nvim" } })
    local builtin = require("telescope.builtin")
    builtin[func](opts and vim.deepcopy(opts) or {})
  end
end

map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

map("n", "<leader>w", vim.cmd.write, { desc = "保存" })
map("n", "<leader>q", vim.cmd.quit, { desc = "ウィンドウを閉じる" })
map("n", "<leader>Q", vim.cmd.qall, { desc = "Neovimを終了" })

map("n", "<leader>fe", "<cmd>Neotree toggle<cr>", { desc = "ファイルツリー" })
map("n", "<leader>ff", telescope_builtin("find_files", { hidden = true }), { desc = "ファイル検索" })
map("n", "<C-p>", telescope_builtin("find_files", { hidden = true }), { desc = "Ctrl+P ファイル検索" })
map("n", "<leader>fg", telescope_builtin("live_grep"), { desc = "ライブgrep" })
map("n", "<leader>fb", telescope_builtin("buffers"), { desc = "バッファ一覧" })
map("n", "<leader>fh", telescope_builtin("help_tags"), { desc = "ヘルプ検索" })

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

map({ "n", "v" }, "<leader>af", "<cmd>Ai<cr>", { desc = "Ai: 部分修正" })

-- ウィンドウリサイズ (Ctrl+e の後に hjkl)
map("n", "<C-e>h", "<cmd>vertical resize -2<cr>", { desc = "ウィンドウ幅を減らす" })
map("n", "<C-e>j", "<cmd>resize +2<cr>", { desc = "ウィンドウ高さを増やす" })
map("n", "<C-e>k", "<cmd>resize -2<cr>", { desc = "ウィンドウ高さを減らす" })
map("n", "<C-e>l", "<cmd>vertical resize +2<cr>", { desc = "ウィンドウ幅を増やす" })

-- Markdown限定: 開いているファイルに対して `npx reviw <file>` を実行
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    vim.keymap.set("n", "<leader>p", function()
      vim.cmd.write()
      local file = vim.api.nvim_buf_get_name(ev.buf)
      if file == "" then
        vim.notify("No file name to run reviw", vim.log.levels.WARN, { title = "npx reviw" })
        return
      end
      vim.notify("Running npx reviw " .. file .. " (async)", vim.log.levels.INFO, { title = "npx reviw" })
      vim.fn.jobstart({ "npx", "reviw", file }, {
        stdout_buffered = false,
        stderr_buffered = false,
        on_exit = function(_, code)
          vim.schedule(function()
            local level = code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
            vim.notify("reviw finished (exit " .. code .. ")", level, { title = "npx reviw" })
          end)
        end,
      })
    end, { buffer = ev.buf, desc = "npx reviw current markdown" })
  end,
})
