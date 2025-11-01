local opt = vim.opt

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

if vim.fn.has("nvim-0.9") == 1 then
  opt.splitkeep = "screen"
end
