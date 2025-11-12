local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local group = augroup("UserCustomAutoCmds", { clear = true })

local function strip_osc8_sequences(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.b._osc8_scrubbing then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local dirty = false
  for idx, line in ipairs(lines) do
    if line:find("\27]8;", 1, true) or line:find("E]8;", 1, true) then
      local cleaned = line
      cleaned = cleaned:gsub("\27%]8;.-\7", "")
      cleaned = cleaned:gsub("\27%]8;.-\27\\", "")
      cleaned = cleaned:gsub("E%]8;.-\7", "")
      cleaned = cleaned:gsub("E%]8;.-E\\", "")
      if cleaned ~= line then
        lines[idx] = cleaned
        dirty = true
      end
    end
  end
  if not dirty then
    return
  end
  vim.b._osc8_scrubbing = true
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.fn.winrestview(view)
  vim.b._osc8_scrubbing = nil
end

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

autocmd("FileType", {
  group = group,
  pattern = {
    "markdown",
    "json",
    "jsonc",
  },
  callback = function()
    vim.opt_local.conceallevel = 0
    vim.opt_local.concealcursor = ""
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

autocmd({ "BufReadPost", "TextChanged", "TextChangedI" }, {
  group = group,
  pattern = { "*.md", "*.markdown", "*.mdx", "*.txt" },
  callback = function(event)
    strip_osc8_sequences(event.buf)
  end,
})

autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = group,
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd.checktime()
    end
  end,
})
