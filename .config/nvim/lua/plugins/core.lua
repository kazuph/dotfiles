---@type LazySpec
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "frappe",
        integrations = {
          cmp = true,
          gitsigns = true,
          neotree = true,
          treesitter = true,
          which_key = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
  {
    "echasnovski/mini.icons",
    version = false,
    lazy = true,
    config = function()
      require("mini.icons").setup()
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin",
        component_separators = "",
        section_separators = "",
        globalstatus = true,
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup()
      wk.add({
        { "<leader>a", group = "Aibo" },
        { "<leader>c", group = "コード" },
        { "<leader>f", group = "検索" },
        { "<leader>g", group = "Git" },
        { "<leader>w", group = "ウィンドウ" },
      })
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300,
      },
    },
  },
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      mappings = {
        basic = false,
        extra = false,
      },
    },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
    },
  },
  {
    "akinsho/toggleterm.nvim",
    cmd = { "ToggleTerm", "TermExec" },
    opts = {
      size = 12,
      open_mapping = [[<c-\>]],
      direction = "float",
      float_opts = {
        border = "rounded",
      },
    },
  },
}
