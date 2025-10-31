if vim.loader and not vim.g.vscode then
  vim.loader.enable()
end

vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("config.options")
require("config.autocmds")
require("config.keymaps")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local ok, lazy = pcall(require, "lazy")
if not ok then
  vim.api.nvim_err_writeln("lazy.nvim failed to load")
  return
end

lazy.setup("plugins", {
  defaults = {
    lazy = true,
    version = false,
  },
  install = {
    colorscheme = { "catppuccin", "tokyonight", "habamax" },
  },
  checker = {
    enabled = false,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
  ui = {
    border = "rounded",
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
})
