---@type LazySpec
return {
  {
    "lambdalisue/nvim-aibo",
    cmd = { "Aibo", "AiboSend" },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("aibo").setup({
        prompt_height = 8,
        submit_delay = 80,
        prompt = {
          no_default_mappings = false,
        },
      })
    end,
    keys = {
      {
        "<leader>ai",
        function()
          local width = math.floor(vim.o.columns * 0.6)
          vim.cmd(string.format('Aibo -opener="%dvsplit" claude', width))
        end,
        desc = "Aibo: Claude セッション",
      },
      {
        "<leader>as",
        "<cmd>AiboSend -submit<cr>",
        mode = { "n", "v" },
        desc = "Aibo: 選択範囲を送信",
      },
    },
  },
}
