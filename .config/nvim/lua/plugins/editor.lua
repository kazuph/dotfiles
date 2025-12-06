---@type LazySpec
return {
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    version = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    opts = {
      defaults = {
        prompt_prefix = " ",
        selection_caret = " ",
        mappings = {
          i = {
            ["<C-h>"] = "which_key",
          },
        },
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      close_if_last_window = true,
      filesystem = {
        follow_current_file = { enabled = true, leave_dirs_open = true },
        use_libuv_file_watcher = true,
      },
      window = {
        width = 32,
        mappings = {
          ["<space>"] = "toggle_node",
        },
      },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        function()
          require("flash").jump()
        end,
        mode = { "n", "x", "o" },
        desc = "Flash ジャンプ",
      },
      {
        "S",
        function()
          require("flash").treesitter()
        end,
        mode = { "n", "x", "o" },
        desc = "Flash Treesitter",
      },
    },
  },
  {
    "mvllow/modes.nvim",
    event = "VeryLazy",
    opts = {
      colors = {
        insert = "#78dce8",
        visual = "#ab9df2",
        delete = "#ff6188",
        copy = "#a9dc76",
      },
      line_opacity = 0.2,
    },
  },
  {
    "rmagatti/goto-preview",
    keys = {
      {
        "gp",
        function()
          require("goto-preview").goto_preview_definition()
        end,
        desc = "定義プレビュー",
      },
      {
        "gP",
        function()
          require("goto-preview").goto_preview_references()
        end,
        desc = "参照プレビュー",
      },
      {
        "gq",
        function()
          require("goto-preview").close_all_win()
        end,
        desc = "プレビュー閉じる",
      },
    },
    opts = {
      width = 100,
      height = 20,
      border = "rounded",
      default_mappings = false,
    },
  },
}
