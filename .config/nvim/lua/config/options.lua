vim.g.markdown_recommended_style = 0
vim.g.markdown_syntax_conceal = 0

local opt = vim.opt

-- 日本語エンコーディング対応（Shift_JIS, EUC-JP等）
opt.fileencodings = "utf-8,sjis,euc-jp,cp932,iso-2022-jp,latin1"

opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.breakindent = true
opt.completeopt = { "menu", "menuone", "noselect" }
opt.cursorline = true
opt.expandtab = true
opt.ignorecase = true
opt.smartcase = true
opt.smartindent = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.termguicolors = true
opt.splitbelow = true
opt.splitright = true
opt.number = true
opt.relativenumber = false
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.updatetime = 200
opt.timeoutlen = 300
opt.undofile = true
opt.swapfile = false
opt.fillchars = { eob = " " }
opt.conceallevel = 2
opt.autoread = true

-- GUI用フォント設定（goneovim, neovide等）
if vim.fn.has("gui_running") == 1 or vim.g.neovide or vim.g.gonvim_running then
  opt.guifont = "UDEV Gothic 35NF:h16"
end

if vim.fn.has("nvim-0.9") == 1 then
  opt.splitkeep = "screen"
end
