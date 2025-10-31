local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local group = augroup("UserCustomAutoCmds", { clear = true })

autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

autocmd("FileType", {
  group = group,
  pattern = {
    "gitcommit",
    "markdown",
  },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

autocmd("BufWritePre", {
  group = group,
  pattern = { "*.lua", "*.ts", "*.tsx", "*.js" },
  callback = function(event)
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})
