---@type LazySpec
return {
  {
    "vimiomori/bluedolphin.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "colorful",
      transparent = false,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        sidebars = "dark",
        floats = "dark",
      },
      sidebars = { "qf", "help", "neo-tree" },
      lualine_bold = true,
    },
    config = function(_, opts)
      require("bluedolphin").setup(opts)
      vim.cmd.colorscheme("bluedolphin")
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
    opts = function()
      local function ai_component()
        return require("ai").status()
      end
      return {
        options = {
          theme = "bluedolphin",
          component_separators = "",
          section_separators = "",
          globalstatus = true,
        },
        sections = {
          lualine_x = {
            "encoding",
            "fileformat",
            "filetype",
            {
              ai_component,
              cond = function()
                return ai_component() ~= ""
              end,
            },
          },
        },
      }
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup()
      wk.add({
        { "<leader>a", group = "Ai" },
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
